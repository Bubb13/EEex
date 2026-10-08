
(function()

	EEex_DisableCodeProtection()

	--[[
	+-----------------------------------------------------------------------------+
	| Fix signed XP losses in the three x64 v2.7.3.0 engines. The permanent op104 |
	| ADD can underflow; character feedback always chooses the gain string; party |
	| distribution uses unsigned DIV and consumes only positive remainders.       |
	+-----------------------------------------------------------------------------+
	| C++ owns the arithmetic and formatting. ASM only adapts verified operands.  |
	+-----------------------------------------------------------------------------+
	--]]

	EEex_Utility_NewScope(function()

		local names = {
			"Hook-CGameEffectXP::ApplyEffect()-PermanentAdd",
			"Hook-CGameSprite::FeedBack()-ExperienceFormatCall",
			"Hook-CGameSprite::FeedBack()-ExperienceFetchCall",
			"Hook-CInfGame::AddPartyXP()-SignedSplit",
			"Hook-CInfGame::AddPartyXP()-SignedRemainder",
			"Hook-CInfGame::FeedBack()-ExperienceFormatCall",
		}
		local sites, present = {}, 0
		for i, name in ipairs(names) do
			sites[i] = EEex_TryLabel(name)
			if sites[i] == 0 then EEex_Error("XP loss fix: null "..name) end
			if sites[i] ~= nil then present = present + 1 end
		end
		-- The shared scripts also run with v2.6.6.0 databases and DLLs. None of
		-- their sites are advertised, so do not ask them for the new helpers.
		if present == 0 then return end
		if present ~= #names then EEex_Error("XP loss fix: incomplete pattern database") end

		local function requireLabel(name)
			local value = EEex_TryLabel(name)
			if value == nil or value == 0 then EEex_Error("XP loss fix: missing "..name) end
			return value
		end
		for _, name in ipairs({
			"EEex::Fix_Hook_ClampXPLoss", "EEex::Fix_Hook_FormatExperienceAmount",
			"EEex::Fix_Hook_SplitPartyXP", "EEex::Fix_Hook_NextPartyXPShare",
		}) do requireLabel(name) end
		local formatTarget = requireLabel("CString::Format")
		local fetchTarget = requireLabel("CTlkTable::Fetch")
		local lossStrref = EEex_Fix_Private_ExperienceLossStrref
		if type(lossStrref) ~= "number" or lossStrref ~= math.floor(lossStrref)
			or lossStrref < 0 or lossStrref > 0xFFFFFF then
			EEex_Error("XP loss fix: reinstall EEex to assign its loss-message TLK reference")
		end

		local function expectBytes(address, hex)
			for i = 1, #hex, 2 do
				if EEex_ReadU8(address + (i - 1) / 2) ~= tonumber(hex:sub(i, i + 1), 16) then
					EEex_Error("XP loss fix: unexpected instruction bytes")
				end
			end
		end
		local function expectCall(address, target)
			expectBytes(address, "E8")
			if address + 5 + EEex_Read32(address + 1) ~= target then
				EEex_Error("XP loss fix: unexpected native call target")
			end
		end
		local function expectFormatPointer(address)
			expectBytes(address, "488D15") -- lea rdx, [rip+disp32]
			expectBytes(address + 7 + EEex_Read32(address + 3), "256400") -- %d\0
		end

		-- Preflight ALL six contracts before allocating/writing the first hook.
		-- Relative operands are decoded, not compared to one game's raw addresses.
		local xpOffset = EEex_OffsetOf("CGameSprite.m_baseStats.m_xp")
		expectBytes(sites[1] - 11, "4183782401418B401C7522")
		expectBytes(sites[1], "0182")
		if EEex_Read32(sites[1] + 2) ~= xpOffset then EEex_Error("XP loss fix: XP offset differs") end
		expectBytes(sites[1] + 6, "B80100000041C780180100000100000041C7801401000001000000C3")
		expectBytes(sites[2] - 14, "458BC7") -- r8d = original signed int1 in r15d
		expectFormatPointer(sites[2] - 11)
		expectBytes(sites[2] - 4, "488D4D97") -- existing CString local
		expectCall(sites[2], formatTarget)
		expectBytes(sites[3] - 19, "4C8D45CF4881C1501100004533C9BA9E00F000")
		expectCall(sites[3], fetchTarget)
		expectBytes(sites[4] - 4, "410FBFC9") -- ecx = native positive recipient count
		expectBytes(sites[4], "33D28BC3F7F1")
		expectBytes(sites[4] + 6, "488D4C24408BEA448BF8BA68000000")
		expectBytes(sites[5], "6685ED7E0D418D470166FFCD89442444EB0544897C2444")
		expectBytes(sites[5] + 23, "4C8D4C2430")
		expectFormatPointer(sites[6] - 23)
		expectBytes(sites[6] - 16, "F7D8488D4DB74585F6440F4EF0458BC6")
		expectCall(sites[6], formatTarget)

		-- These three helpers are verified integer-only leaves in the built DLL.
		-- Save every volatile integer register except RAX (the result), and save
		-- flags outside the callee's 32-byte shadow space. The macros account for
		-- the leaf effect's RSP%16 == 8 and the party routine's aligned frame.
		local function arithmeticCall(helper, args, result)
			return EEex_FlattenTable({{[[
				#MAKE_SHADOW_SPACE(56)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r10
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r11
				pushfq
				pop r11
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11
			]]}, args, {"call #L("..helper..") #ENDL"}, {[[
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)]
				mov r11, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)]
			]]}, result or {}, {[[
				push qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)]
				popfq
				#DESTROY_SHADOW_SPACE
			]]}})
		end
		local registers = EEex_HookIntegrityWatchdogRegister
		EEex_HookBeforeRestoreWithLabels(sites[1], 0, 6, 6, {
			{"stack_mod", 8}, {"hook_integrity_watchdog_ignore_registers", {registers.RAX}}},
			arithmeticCall("EEex::Fix_Hook_ClampXPLoss", {
				"mov ecx, dword ptr ds:[rdx+#$(1)] #ENDL", {xpOffset}, "mov edx, eax #ENDL",
			})
		)

		-- Both are call replacements with the original RCX/RDX/R8 arguments and
		-- caller-provided shadow space. C++ forwards to the bound engine formatter;
		-- no extra frame, allocation policy, or character-name handling is invented.
		for _, site in ipairs({sites[2], sites[6]}) do
			EEex_HookRemoveCallWithLabels(site, {}, {"call #L(EEex::Fix_Hook_FormatExperienceAmount) #ENDL"})
		end
		EEex_HookBeforeCallWithLabels(sites[3], {
			{"hook_integrity_watchdog_ignore_registers", {registers.RDX}}},
			{"pushfq #ENDL test r15d, r15d #ENDL jns keep_gain #ENDL mov edx, #$(1) #ENDL keep_gain: #ENDL popfq #ENDL", {lossStrref}}
		)

		-- Replace XOR/MOV/DIV, then unpack the proven eight-byte Win64 result
		-- into the original EAX quotient / EDX remainder. The native following
		-- instructions still copy them to R15D / EBP and construct the XP effect.
		EEex_HookBeforeRestoreWithLabels(sites[4], 0, 0, 6, {
			{"hook_integrity_watchdog_ignore_registers", {registers.RAX, registers.RDX}}},
			arithmeticCall("EEex::Fix_Hook_SplitPartyXP", {"mov edx, ecx #ENDL mov ecx, ebx #ENDL"}, {
				"mov rdx, rax #ENDL shr rdx, 32 #ENDL mov eax, eax #ENDL",
			})
		)

		-- Replace the WHOLE remainder branch, rather than relocating its relative
		-- jumps. No outside branch enters its interior (proved by the audit).
		-- RSP+44h is this routine's verified Item_effect_st.effectAmount local;
		-- LAST_FRAME_TOP compensates for the helper frame. R15D remains the base
		-- quotient. EAX is dead after the store; EBP becomes the next remainder.
		EEex_HookBeforeRestoreWithLabels(sites[5], 0, 0, 23, {
			{"hook_integrity_watchdog_ignore_registers", {registers.RAX, registers.RBP}}},
			arithmeticCall("EEex::Fix_Hook_NextPartyXPShare", {"mov ecx, r15d #ENDL mov edx, ebp #ENDL"}, {
				"mov dword ptr ss:[rsp+#LAST_FRAME_TOP(44h)], eax #ENDL shr rax, 32 #ENDL mov ebp, eax #ENDL",
			})
		)

		-- This replacement writes the engine local before the watchdog exit;
		-- permit exactly that DWORD, in addition to the ordinary caller shadow.
		EEex_HookIntegrityWatchdog_IgnoreStackSizes(sites[5], {{0x44, 4}})
	end)

	--[[
	+-------------------------------------------------------------------------------------------------------------------------+
	| Implement the missing WSPECIAL.2DA["SPEED"] bonus                                                                       |
	+-------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_ImplementWSPECIALSpeedColumn(pSprite: CGameSprite*, nProficiencyLevel: int, bOffHand: bool) |
	+-------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::CheckCombatStatsWeapon()-NonZeroWeapProfCall"), {
		{"hook_integrity_watchdog_ignore_registers", { EEex_HookIntegrityWatchdogRegister.RAX }}},
		{[[
			mov rcx, r14                     ; pSprite
			movsx edx, r12w                  ; nProficiencyLevel
			mov r8d, dword ptr ss:[rbp+0x50] ; bOffHand
			call #L(EEex::Fix_Hook_ImplementWSPECIALSpeedColumn)
		]]}
	)

	--[[
	+------------------------------------------------------------------------------------------------------------------------+
	| BUG: v2.5+ - op33 param2 == 3 immediately subtracts from SAVEVSWANDS instead of SAVEVSDEATH in the current effect pass |
	+------------------------------------------------------------------------------------------------------------------------+
	|   [JIT] CGameEffectSaveVsDeath::ApplyEffect()                                                                          |
	|       Replace the incorrect immediate save target. Example patch from v2.6.6.0:                                        |
	|           Bugged -> sub word ptr ds:[rdi+1136h], ax ; SAVEVSWANDS                                                      |
	|           Fixed  -> sub word ptr ds:[rdi+1134h], ax ; SAVEVSDEATH                                                      |
	+------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_WriteU32(
		EEex_Label("Hook-CGameEffectSaveVsDeath::ApplyEffect()-ImmediateSaveWriteOffset"),
		EEex_OffsetOf("CGameSprite.m_derivedStats.m_nSaveVSDeath")
	)

	--[[
	+----------------------------------------------------------------------------------------------------------------+
	| Fix TRAPLIMT.2DA's snare cap check in CGameEffectSetSnare::ApplyEffect                                         |
	+----------------------------------------------------------------------------------------------------------------+
	| The real engine bug is an off-by-one at the cap compare: after comparing the current active trap count against |
	| TRAPLIMT.2DA's limit, the engine branches on `jle`, so `current == limit` is still accepted and one extra trap |
	| can be placed. This patch rewrites that short jump to `jl` at the shared compare site used by the current      |
	| BGEE, BG2EE, and IWDEE executables (`v2.6.6.0`).                                                               |
	+----------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_Utility_NewScope(function()

		local compareJumpAddress = EEex_Label("Hook-CGameEffectSetSnare::ApplyEffect()-SetSnareTrapCapCompareJmp")
		local fixedOpcode = 0x7C -- jl

		local currentOpcode = EEex_ReadU8(compareJumpAddress)
		if currentOpcode == fixedOpcode then
			-- Something else already fixed the branch
			return
		end

		if currentOpcode ~= 0x7E then -- jle
			EEex_Error(string.format(
				"Unexpected opcode 0x%02X at #L(Hook-CGameEffectSetSnare::ApplyEffect()-SetSnareTrapCapCompareJmp)",
				currentOpcode
			))
		end

		EEex_WriteU8(compareJumpAddress, fixedOpcode)
	end)

	--[[
	+----------------------------------------------------------------------------------------------------+
	| BUG: v2.6.6.0 - op206/318/324 incorrectly indexes the source object's item list if the incoming    |
	| effect's source spell has a name strref of -1 without first checking if the source was a sprite    |
	+----------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_SpellImmunityShouldSkipItemIndexing(pGameObject: CGameObject*) -> bool |
	|       return:                                                                                      |
	|           -> false - Don't alter engine behavior                                                   |
	|           -> true  - Force the engine to skip its item list check                                  |
	+----------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameEffect::CheckAdd()-FixSpellImmunityShouldSkipItemIndexing"), 4, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			mov rcx, qword ptr ds:[rsp+#LAST_FRAME_TOP(50h)]            ; pGameObject
			call #L(EEex::Fix_Hook_SpellImmunityShouldSkipItemIndexing)
			test al, al
			jnz #L(jmp_success)
		]]}
	)

	--[[
	+------------------------------------------------------------------------------------------------------+
	| Fix quick spell slots not updating when a special ability is added (for example, by op171 or act279) |
	+------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Fix_Hook_OnAddSpecialAbility(sprite: CGameSprite, spell: CSpell)                        |
	+------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::AddSpecialAbility()-LastCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(48)
			]]},
			EEex_GenLuaCall("EEex_Fix_Hook_OnAddSpecialAbility", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {[[
						lea rax, qword ptr ds:[rsp+#LAST_FRAME_TOP(48h)]
						mov qword ptr ss:[rsp+#$(1)], rax
					]], {rspOffset}}, "CSpell" end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--[[
	+----------------------------------------------------------------------------------------------------------------------+
	| Fix Spell() and SpellPoint() not being disruptable if the creature is facing SSW(1), SWW(3), NWW(5), NNW(7), NNE(9), |
	| NEE(11), SEE(13), or SSE(15)                                                                                         |
	+----------------------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Fix_Hook_ShouldForceMainSpellActionCode(sprite: CGameSprite, point: CPoint) -> boolean                  |
	|       return:                                                                                                        |
	|           -> false - Don't alter engine behavior                                                                     |
	|           -> true  - Force the engine to run the main spell action code regardless of the sprite's orientation       |
	|                      (which includes spell disruption handling)                                                      |
	+----------------------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Fix_Hook_OnSpellOrSpellPointStartedCastingGlow(sprite: CGameSprite)                                     |
	+----------------------------------------------------------------------------------------------------------------------+
	--]]

	----------------------------------------------------------
	-- [Lua] EEex_Fix_Hook_ShouldForceMainSpellActionCode() --
	----------------------------------------------------------

	local callShouldForceMainSpellActionCode = EEex_JITNear(EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Fix_Hook_ShouldForceMainSpellActionCode", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CGameSprite" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx #ENDL", {rspOffset}}, "CPoint" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor rax, rax

			no_error:
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}))

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::Spell()-CheckDirectionJmp"), 3, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			mov rdx, r14                                                  ; point
			mov rcx, rbx                                                  ; sprite
			call #$(1) ]], {callShouldForceMainSpellActionCode}, [[ #ENDL
			test rax, rax
			jnz #L(jmp_success)
		]]}
	)

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::SpellPoint()-CheckDirectionJmp"), 5, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			lea rdx, qword ptr ss:[rsp+0x60]                              ; point
			mov rcx, rbx                                                  ; sprite
			call #$(1) ]], {callShouldForceMainSpellActionCode}, [[ #ENDL
			test rax, rax
			jnz #L(jmp_success)
		]]}
	)

	-----------------------------------------------------------------
	-- [Lua] EEex_Fix_Hook_OnSpellOrSpellPointStartedCastingGlow() --
	-----------------------------------------------------------------

	local callOnSpellOrSpellPointStartedCastingGlow = EEex_JITNear(EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Fix_Hook_OnSpellOrSpellPointStartedCastingGlow", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CGameSprite" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}))

	for _, address in ipairs({
		EEex_Label("Hook-CGameSprite::Spell()-ApplyCastingEffect()"),
		EEex_Label("Hook-CGameSprite::SpellPoint()-ApplyCastingEffect()")
	}) do
		EEex_HookAfterCallWithLabels(address, {
			{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
			{[[
				mov rcx, rbx                                                         ; sprite
				call #$(1) ]], {callOnSpellOrSpellPointStartedCastingGlow}, [[ #ENDL
			]]}
		)
	end

	--[[
	+--------------------------------------------------------------------------------------------------------------------+
	| Fix SPLPROT.2DA relational stat comparisons treating signed stats as unsigned                                      |
	+--------------------------------------------------------------------------------------------------------------------+
	|   [JIT] CRuleTables::IsProtectedFromSpell()                                                                        |
	|       Only relations <=, ==, <, >, >=, != are re-evaluated here. Bitwise relations retain the engine's behavior.   |
	+--------------------------------------------------------------------------------------------------------------------+
	| Why hook with EEex_HookBeforeCallWithLabels():                                                                     |
	|   This site is the call from IsProtectedFromSpell() into CRuleTables::Compare(). At this exact point the caller    |
	|   has already fetched the stat value, loaded the compare constant, decoded the relation, and still has the stat id |
	|   live in a register. That gives us the narrowest possible interception point:                                     |
	|     * #L(return)      -> let the original Compare() call run unchanged                                             |
	|     * #L(return_skip) -> skip the call and continue as if Compare() had returned our replacement result            |
	|   Hooking earlier would require reimplementing more of IsProtectedFromSpell(); hooking after the call would mean   |
	|   the engine has already performed the wrong unsigned comparison.                                                  |
	+--------------------------------------------------------------------------------------------------------------------+
	--]]

	-- Register state at the Compare() call site:
	--   edx = stat value read from CDerivedStats::GetAtOffset()
	--   r8d = SPLPROT compare constant
	--   r9d = relation opcode that Compare() would evaluate
	--   r13w = stat id, still available from the surrounding IsProtectedFromSpell() loop
	--
	-- We only need one scratch register (r11) to index the signed-stat bitmap, so
	-- the watchdog is told to ignore that register for this hook.
	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CRuleTables::IsProtectedFromSpell()-CompareStatCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.R11}}},
		{[[
			; If this stat is not marked as signed, preserve the engine's original Compare() call.
			mov rax, #$(1) ]], {EEex_Fix_Private_SignedSplprotStatBitmap}, [[ #ENDL
			movzx r11d, r13w
			cmp byte ptr ds:[rax+r11], 0
			jz #L(return)

			; Compare() also supports non-relational operations. This fix only replaces the
			; six relational operators whose signedness is wrong; everything else stays native.
			cmp r9d, 5
			ja #L(return)

			; Re-evaluate the relation with signed setcc variants using the exact operands the
			; engine was about to pass into Compare(): edx (lhs stat value) vs r8d (rhs constant).
			test r9d, r9d
			je compare_le
			cmp r9d, 1
			je compare_eq
			cmp r9d, 2
			je compare_lt
			cmp r9d, 3
			je compare_gt
			cmp r9d, 4
			je compare_ge
			cmp r9d, 5
			je compare_ne
			jmp #L(return)

			compare_le:
			cmp edx, r8d
			setle al
			jmp finish_compare

			compare_eq:
			cmp edx, r8d
			sete al
			jmp finish_compare

			compare_lt:
			cmp edx, r8d
			setl al
			jmp finish_compare

			compare_gt:
			cmp edx, r8d
			setg al
			jmp finish_compare

			compare_ge:
			cmp edx, r8d
			setge al
			jmp finish_compare

			compare_ne:
			cmp edx, r8d
			setne al

			finish_compare:
			; Compare() returns a boolean-like integer in eax. Materialize the same shape and
			; skip the original call, resuming execution immediately after it.
			movzx eax, al
			jmp #L(return_skip)
		]]}
	)

	--[[
	+----------------------------------------------------------------------------------------------------------------+
	| [JIT] Opcode #182 should consider -1 (instead of 0) the fail return value from CGameSprite::FindItemPersonal() |
	+----------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeConditionalJump(EEex_Label("Hook-CGameEffectApplyEffectEquipItem::ApplyEffect()-CheckRetVal"), 0, {[[
		cmp ax, -1
	]]})

	--[[
	+--------------------------------------------------------------------------------------------------------------------------------+
	| Fix a couple of regressions in v2.6 regarding op206/op232/op256                                                                |
	+--------------------------------------------------------------------------------------------------------------------------------+
	|   1) op206's param1 only works for values 0xF00074 and 0xF00080                                                                |
	|   2) op232 and op256's "you cannot cast multiple instances" message fails to display                                           |
	+--------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_ShouldTransformSpellImmunityStrref(pEffect: CGameEffect*, pImmunitySpell: CImmunitySpell*) -> bool |
	|       return:                                                                                                                  |
	|           -> false - Don't transform immunity strref                                                                           |
	|           -> true  - Transform immunity strref                                                                                 |
	+--------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CGameEffect::CheckAdd()-FixShouldTransformSpellImmunityStrref"), 0, 5, 5, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}},
		{"manual_return", true}},
		{[[
			mov rdx, r12                                               ; pImmunitySpell
			mov rcx, rdi                                               ; pEffect
			call #L(EEex::Fix_Hook_ShouldTransformSpellImmunityStrref)
			test al, al

			#MANUAL_HOOK_EXIT(0)
			jnz #L(Hook-CGameEffect::CheckAdd()-FixShouldTransformSpellImmunityStrrefBody)
			jmp #L(Hook-CGameEffect::CheckAdd()-FixShouldTransformSpellImmunityStrrefElse)
		]]}
	)

	--[[
	+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	| Increase the cap of FoW-clearing creatures to 32,768                                                                                                                                  |
	+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] CGameArea::Override_AddClairvoyanceObject(pSprite: CGameSprite*, position: CPoint, duration: int)                                                                        |
	|   [EEex.dll] CGameSprite::Override_CheckIfVisible()                                                                                                                                   |
	|   [EEex.dll] CGameSprite::Override_SetVisualRange(nVisRange: short) -> short                                                                                                          |
	|   [EEex.dll] CVisibilityMap::Override_AddCharacter(pPos: CPoint*, nCharId: int, pVisibleTerrainTable: byte*, nVisRange: byte, pRemovalTable: int*) -> byte                            |
	|   [EEex.dll] CVisibilityMap::Override_IsCharacterIdOnMap(nCharId: int) -> int                                                                                                         |
	|   [EEex.dll] CVisibilityMap::Override_RemoveCharacter(pOldPos: CPoint*, nCharId: int, pVisibleTerrainTable: byte*, nVisRange: byte, pRemovalTable: int*, bRemoveCharId: byte)         |
	|   [EEex.dll] CVisibilityMap::Override_UpDate(pOldPos: CPoint*, pNewPos: CPoint*, nCharId: int, pVisibleTerrainTable: byte*, nVisRange: byte, pRemovalTable: int*, bForceUpdate: byte) |
	|   [EEex.dll] EEex::VisibilityMap_Hook_OnConstruct(pThis: CVisibilityMap*)                                                                                                             |
	|   [EEex.dll] EEex::VisibilityMap_Hook_OnDestruct(pThis: CVisibilityMap*)                                                                                                              |
	+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-CGameArea::AddClairvoyanceObject(CGameSprite*,CPoint,int)-FirstInstruction"), {[[
		jmp #L(CGameArea::Override_AddClairvoyanceObject(CGameSprite*,CPoint,int))
	]]})

	EEex_JITAt(EEex_Label("Hook-CGameSprite::CheckIfVisible()-FirstInstruction"), {[[
		jmp #L(CGameSprite::Override_CheckIfVisible)
	]]})

	EEex_JITAt(EEex_Label("Hook-CGameSprite::SetVisualRange()-FirstInstruction"), {[[
		jmp #L(CGameSprite::Override_SetVisualRange)
	]]})

	EEex_JITAt(EEex_Label("Hook-CVisibilityMap::AddCharacter()-FirstInstruction"), {[[
		jmp #L(CVisibilityMap::Override_AddCharacter)
	]]})

	EEex_JITAt(EEex_Label("Hook-CVisibilityMap::IsCharacterIdOnMap()-FirstInstruction"), {[[
		jmp #L(CVisibilityMap::Override_IsCharacterIdOnMap)
	]]})

	EEex_JITAt(EEex_Label("Hook-CVisibilityMap::RemoveCharacter()-FirstInstruction"), {[[
		jmp #L(CVisibilityMap::Override_RemoveCharacter)
	]]})

	EEex_JITAt(EEex_Label("Hook-CVisibilityMap::UpDate()-FirstInstruction"), {[[
		jmp #L(CVisibilityMap::Override_UpDate)
	]]})

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CVisibilityMap::Construct()-FirstInstruction"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

																 ; rcx already CVisibilityMap
			call #L(EEex::VisibilityMap_Hook_OnConstruct)

			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CVisibilityMap::Destruct()-FirstInstruction"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

																 ; rcx already CVisibilityMap
			call #L(EEex::VisibilityMap_Hook_OnDestruct)

			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	--[[
	+--------------------------------------------------------------------------------------------------------+
	| Fix "Auto-Pause - Spell Cast" causing effect probabilities to reroll multiple times for a single spell |
	+--------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_ShouldProcessEffectListSkipRolls() -> bool                                 |
	|       return:                                                                                          |
	|           -> false - Don't alter engine behavior                                                       |
	|           -> true  - Skip rerolling effect probabilities                                               |
	+--------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameSprite::ProcessEffectList()-FirstRandCall"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			call #L(EEex::Fix_Hook_ShouldProcessEffectListSkipRolls)
			test al, al
			jz #L(return)

			; Manually reimplement instructions skipped by the following jmp
			mov edx, dword ptr ds:[rsi+0x48]
			mov edi, r12d
			#MANUAL_HOOK_EXIT(1)
			jmp #L(Hook-CGameSprite::ProcessEffectList()-AfterRandCalls)
		]]}
	)
	-- Manually define the ignored registers for the unusual `jmp` above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("Hook-CGameSprite::ProcessEffectList()-FirstRandCall"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
		EEex_HookIntegrityWatchdogRegister.RDI, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
		EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
	})

	--[[
	+--------------------------------------------------------------------------------------+
	| Override CChitin::SynchronousUpdate() to gain control over a frame's render sequence |
	+--------------------------------------------------------------------------------------+
	|   Used to allow the UI to request another render pass                                |
	+--------------------------------------------------------------------------------------+
	|   [EEex.dll] CChitin::Override_SynchronousUpdate()                                   |
	+--------------------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-CChitin::SynchronousUpdate()-FirstInstruction"), {"jmp #L(CChitin::Override_SynchronousUpdate)"})

	--[[
	+------------------------------------------------------------------------------+
	| Fix killing the capture of an edit item not properly stopping the text input |
	+------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_OnBeforeUIKillCapture()                          |
	+------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-uiKillCapture()-FirstInstruction"), 0, 6, 6, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE
			call #L(EEex::Fix_Hook_OnBeforeUIKillCapture)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	--[[
	+-------------------------------------------------------------------------------------------------+
	| Fix capture functions that result in the capture item being deleted potentially causing a crash |
	+-------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Override_uiEventMenuStack(pEvent: SDL_Event*, pWindow: SDL_Rect*) -> bool    |
	+-------------------------------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-uiEventMenuStack()-FirstInstruction"), {"jmp #L(EEex::Override_uiEventMenuStack)"})

	--[[
	+--------------------------------------------------------------------------------------------------------------------+
	| Fix closing the local area map with a double click resulting in the world screen responding to the button up event |
	+--------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] CScreenMap::Override_OnLButtonDblClk(cPoint: CPoint)                                                  |
	|   [Lua] EEex_Fix_LuaHook_OnLocalMapDoubleClick()                                                                   |
	+--------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_SetSegmentProtection(".rdata", 0x4) -- PAGE_READWRITE
	EEex_WritePtr(EEex_UDToPtr(EEex_CScreenMap.VFTable.reference_OnLButtonDblClk), EEex_Label("CScreenMap::Override_OnLButtonDblClk"))
	EEex_SetSegmentProtection(".rdata", 0x2) -- PAGE_READONLY

	--[[
	+------------------------------------------------------------------------------------+
	| Fix floating text not maintaining its size / alignment when the viewport is zoomed |
	+------------------------------------------------------------------------------------+
	|   [EEex.dll] CGameText::Override_Render(pArea: CGameArea*, pVidMode: CVidMode*)    |
	+------------------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-CGameText::Render()-FirstInstruction"), {"jmp #L(CGameText::Override_Render)"})

	--[[
	+------------------------------------------------------------------------------------------------------------------------------------------+
	| Fix crash when parsing DLC zips due to bad binary search range resolution in certain situations                                          |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Override_bsearchrange(key: void*, base: void*, NumOfElements: unsigned long long, SizeOfElements: unsigned long long, |
	|                  Compare: int(__fastcall*)(const void*, const void*), start: int*, end: int*) -> bool                                    |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-bsearchrange()-FirstInstruction"), {"jmp #L(EEex::Override_bsearchrange)"})

	--[[
	+-----------------------------------------------------------------------------------------------------------------------------------------------+
	| Fix op135 (CGameEffectPolymorph) form-to-form transitions causing passive equipment bonuses (rings, amulets, etc.) to be stripped.            |
	| For some reason the EEs call `CGameSprite::UnequipAll(animationOnly=0)` when the creature is already polymorphed instead of using             |
	| `animationOnly=1`, which is what the originals always do. All other calls in the function to equip / unequip items specify `animationOnly=1`, |
	| so this seems like a bug in the EE logic, (and is particularly bad for undroppable items like Edwin's Amulet or Nalia's Ring).                |
	+-----------------------------------------------------------------------------------------------------------------------------------------------+
	|   [JIT] Remove the `if (pSprite->m_derivedStats.m_bPolymorphed == 0)` branch so the code always falls through to using `animationOnly=1`.     |
	+-----------------------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-CGameEffectPolymorph::ApplyEffect()-FormToFormUnequipAllBugJne"), {"#REPEAT(2,nop #ENDL)"})

	EEex_EnableCodeProtection()

end)()
