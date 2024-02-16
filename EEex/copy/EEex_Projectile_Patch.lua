
(function()

	EEex_DisableCodeProtection()

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
