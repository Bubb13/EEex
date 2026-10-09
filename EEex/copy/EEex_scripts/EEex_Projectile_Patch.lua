
(function()

	EEex_DisableCodeProtection()

	--[[
	+--------------------------------------------------------------------------------------------------------+
	| v2.7.3.0: area flag bit 1 enables non-sprite matching;                                                 |
	| fireball flag bit 16 additionally admits dead sprites on those same paths.                             |
	+--------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Projectile_Hook_ShouldIncludeDeadSprites(const CProjectileArea* pProjectile) -> int |
	|       The constructors preserve the complete fireball DWORD. GetAllInRangeBack                         |
	|       already supports includeDead, but AreaEffect passes zero both when checking                      |
	|       for trigger targets and when collecting explosion targets. Change only that                      |
	|       argument; the engine continues to enforce type, activity, animation, LOS,                        |
	|       range, cone, immunity, and target-count rules. Rectangle/ray helper collection                   |
	|       does not honor area flag bit 1 and deliberately retains its native behavior.                     |
	+--------------------------------------------------------------------------------------------------------+
	--]]

	do

		local triggerSite = EEex_TryLabel("Hook-CProjectileArea::AreaEffect()-IncludeDeadTrigger")
		local explosionSite = EEex_TryLabel("Hook-CProjectileArea::AreaEffect()-IncludeDeadExplosion")

		-- These labels are supplied only by the v2.7.3.0 database. A legacy database
		-- skips this feature while continuing to install the existing projectile hooks.
		if triggerSite ~= nil or explosionSite ~= nil then

			local helper = EEex_TryLabel("EEex::Projectile_Hook_ShouldIncludeDeadSprites")
			local function requireAddress(address, name)
				if type(address) ~= "number" or address <= 0 or address >= 0x20000000000000
					or address ~= math.floor(address)
				then
					EEex_Error("Dead-sprite projectile hook: missing or invalid "..name)
				end
			end
			requireAddress(triggerSite, "trigger hook")
			requireAddress(explosionSite, "explosion hook")
			requireAddress(helper, "EEex.dll helper")

			-- These offsets and the following complete argument/call byte contracts are
			-- re-proved from all three matching EXE/PDB pairs by the permanent audit.
			-- Binding paths are dotted. No executable VA is embedded in this installer.
			if EEex_OffsetOf("CProjectileArea.m_checkForNonSprites") ~= 0x404
				or EEex_OffsetOf("CProjectileArea.m_fireBallFlags") ~= 0x46C
			then
				EEex_Error("Dead-sprite projectile hook: incompatible CProjectileArea bindings")
			end
			local function requireBytes(address, hex)
				for index = 1, #hex, 2 do
					if EEex_ReadU8(address + (index - 1) / 2) ~= tonumber(hex:sub(index, index + 1), 16) then
						EEex_Error("Dead-sprite projectile hook: native argument/call contract changed")
					end
				end
			end
			requireBytes(triggerSite - 52,
				"8B86040400004C8BC3440FB78EC2030000498BD5488B4E1889442440488D45A84489642438448974243048894424284C897C2420E82552F5FF")
			requireBytes(explosionSite - 63,
				"8B8604040000418BCC398E2C0400004C8BC3440FB78EC0030000498BD5894424400F94C14489642438488D45A8894C2430488B4E1848894424284C897C2420E83451F5FF")
			if triggerSite + 5 + EEex_Read32(triggerSite + 1)
				~= explosionSite + 5 + EEex_Read32(explosionSite + 1)
			then
				EEex_Error("Dead-sprite projectile hook: collector destinations differ")
			end

			-- All dependencies and both native contracts pass before any allocation or
			-- code write. A before-call hook reconstructs the original relative call
			-- from its decoded destination, rather than relocating its encoded bytes.

			for _, site in ipairs({triggerSite, explosionSite}) do
				EEex_HookBeforeCallWithLabels(site, {}, {[[
					; [EEex.dll] int EEex::Projectile_Hook_ShouldIncludeDeadSprites(const CProjectileArea*)
					; RSI is this in both audited paths; caller RSP is already 16-byte aligned.
					; Allocate separate ABI shadow space so native stack arguments remain intact.

					#MAKE_SHADOW_SPACE(56)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r10
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r11
					pushfq #STACK_MOD(8)
					pop r11 #STACK_MOD(-8)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11

					mov rcx, rsi
					call #L(EEex::Projectile_Hook_ShouldIncludeDeadSprites)

					; Native includeDead is an int at the original caller's RSP+38h.
					; RAX is volatile across the original void call and may hold our result.

					mov dword ptr ss:[rsp+#LAST_FRAME_TOP(38h)], eax

					push qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)] #STACK_MOD(8)
					popfq #STACK_MOD(-8)
					mov r11, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)]
					mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)]
					mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
					mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
					mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
				]]})

				if EEex_HookIntegrityWatchdog_Load then
					-- The standard before-call constructor already permits RAX and ABI
					-- shadow space changes. Permit precisely our additional four-byte int.
					EEex_HookIntegrityWatchdog_IgnoreStackSizes(site, {{0x38, 4}})
				end
			end
		end
	end

	--[[
	+----------------------------------------------------------------------------------------------------------------------------------+
	| Implement Opcode #408 (ProjectileMutator) `typeMutator` functionality                                                            |
	+----------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Projectile_Hook_OnBeforeDecode(nProjectileType: ushort, pDecoder: CGameAIBase*, pRetPtr: uintptr_t) -> ushort |
	|       return:                                                                                                                    |
	|           ->  -1 - Don't alter engine behavior                                                                                   |
	|           -> !-1 - Override projectile type with the return value                                                                |
	+----------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeRestoreWithLabels(EEex_Label("CProjectile::DecodeProjectile"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}},
		{"manual_hook_integrity_exit", true}},
		{[[
			#MAKE_SHADOW_SPACE(16)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx

			mov r8, qword ptr ss:[rsp+#LAST_FRAME_TOP(0)] ; pRetPtr
														  ; rdx is already pDecoder
														  ; rcx is already nProjectileType
			call #L(EEex::Projectile_Hook_OnBeforeDecode)

			cmp ax, -1
			je no_override

			mov cx, ax ; Override projectile type

			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
			#MANUAL_HOOK_EXIT(1)
			jmp #L(return)

			no_override:
			#RESUME_SHADOW_ENTRY
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
			#MANUAL_HOOK_EXIT(0)
		]]}
	)
	-- Manually define the ignored registers for the "override" branch above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("CProjectile::DecodeProjectile"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.R8,
		EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
	})

	--[[
	+-------------------------------------------------------------------------------------------------------------------------+
	| Implement Opcode #408 (ProjectileMutator) `projectileMutator` functionality                                             |
	+-------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Projectile_Hook_OnAfterDecode(pProjectile: CProjectile*, pDecoder: CGameAIBase*, pRetPtr: uintptr_t) |
	+-------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CProjectile::DecodeProjectile()-LastCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov r8, qword ptr ss:[rsp+408]               ; pRetPtr
			mov rdx, rsi                                 ; pDecoder
			mov rcx, rbx                                 ; pProjectile
			call #L(EEex::Projectile_Hook_OnAfterDecode)
		]]}
	)

	--[[
	+----------------------------------------------------------------------------------------------------------------------------------------------------+
	| Implement Opcode #408 (ProjectileMutator) `effectMutator` functionality                                                                            |
	+----------------------------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Projectile_Hook_OnBeforeAddEffect(pProjectile: CProjectile*, pDecoder: CGameAIBase*, pEffect: CGameEffect*, pRetPtr: uintptr_t) |
	+----------------------------------------------------------------------------------------------------------------------------------------------------+
	--]]

	-- This is very ugly, but since CProjectile::AddEffect() isn't passed the source aiBase, I have to go and
	-- manually define where the aiBase is currently saved for the given CProjectile::AddEffect() call.
	local getAddEffectAIBase = EEex_JITNear({[[

		#STACK_MOD(8) ; This was called, the ret ptr broke alignment
		#MAKE_SHADOW_SPACE(24)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], r8
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], r9

		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::ForceSpell()-CProjectile::AddEffect()-RetPtr")}, [[       ; 0x14016CE36
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::ForceSpell()-CProjectile::AddEffect()-RetPtr-2")}, [[     ; 0x14016CE53
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::ForceSpellPoint()-CProjectile::AddEffect()-RetPtr")}, [[  ; 0x14016DEA4
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Spell()-CProjectile::AddEffect()-RetPtr")}, [[            ; 0x1403B5238
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Spell()-CProjectile::AddEffect()-RetPtr-2")}, [[          ; 0x1403B5259
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::SpellPoint()-CProjectile::AddEffect()-RetPtr")}, [[       ; 0x1403B6DE2
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Swing()-CProjectile::AddEffect()-RetPtr")}, [[            ; 0x1403B88B3
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Swing()-CProjectile::AddEffect()-RetPtr-2")}, [[          ; 0x1403B9291
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::UseItem()-CProjectile::AddEffect()-RetPtr")}, [[          ; 0x1403BB59A
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::UseItem()-CProjectile::AddEffect()-RetPtr-2")}, [[        ; 0x1403BB5BF
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::UseItemPoint()-CProjectile::AddEffect()-RetPtr")}, [[     ; 0x1403BC0DA
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpell()-CProjectile::AddEffect()-RetPtr")}, [[        ; 0x14016AE6F
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpell()-CProjectile::AddEffect()-RetPtr-2")}, [[      ; 0x14016AFE2
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpellPoint()-CProjectile::AddEffect()-RetPtr")}, [[   ; 0x14016BC3B
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpellPoint()-CProjectile::AddEffect()-RetPtr-2")}, [[ ; 0x14016BCAD
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireItem()-CProjectile::AddEffect()-RetPtr")}, [[         ; 0x14016A465
		cmp rcx, rax
		je in_rbp
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireItem()-CProjectile::AddEffect()-RetPtr-2")}, [[       ; 0x14016A487
		cmp rcx, rax
		je in_rbp
		mov rax, #$(1) ]], {EEex_Label("Data-CBounceList::Add()-CProjectile::AddEffect()-RetPtr")}, [[              ; 0x14014C7DB
		cmp rcx, rax
		je in_r15
		mov rax, #$(1) ]], {EEex_Label("Data-CBounceList::Add()-CProjectile::AddEffect()-RetPtr-2")}, [[            ; 0x14014C82E
		cmp rcx, rax
		je in_r15
		mov rax, #$(1) ]], {EEex_Label("Data-CGameEffect::FireSpell()-CProjectile::AddEffect()-RetPtr")}, [[        ; 0x1401E4715
		cmp rcx, rax
		je source_id_on_stack
		mov rax, #$(1) ]], {EEex_Label("Data-CGameEffect::FireSpell()-CProjectile::AddEffect()-RetPtr-2")}, [[      ; 0x1401E4793
		cmp rcx, rax
		je source_id_on_stack
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireItemPoint()-CProjectile::AddEffect()-RetPtr")}, [[    ; 0x14016A7F3
		cmp rcx, rax
		je in_rsi

		xor rax, rax
		jmp return

		in_rbx:
		mov rax, rbx
		jmp return

		in_r14:
		mov rax, r14
		jmp return

		in_rbp:
		mov rax, rbp
		jmp return

		in_r15:
		mov rax, r15
		jmp return

		source_id_on_stack:
		mov ecx, dword ptr ss:[rbp+0x7F]
		lea rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
		mov qword ptr ss:[rdx], 0
		call #L(CGameObjectArray::GetShare)
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
		jmp return

		in_rsi:
		mov rax, rsi

		return:
		mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
		mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
		ret
	]]})

	EEex_HookBeforeRestoreWithLabels(EEex_Label("CProjectile::AddEffect"), 0, 8, 8, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(16)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx

			mov r9, qword ptr ss:[rsp+#LAST_FRAME_TOP(0)]        ; pRetPtr
			mov r8, rdx                                          ; pEffect

			mov rcx, r9 ; pRetPtr
			call #$(1) ]], {getAddEffectAIBase}, [[ #ENDL
			mov rdx, rax                                         ; pDecoder

																 ; r9 already pRetPtr
																 ; r8 already pEffect
																 ; rdx already pDecoder
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)] ; pProjectile
			call #L(EEex::Projectile_Hook_OnBeforeAddEffect)

			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_EnableCodeProtection()

end)()
