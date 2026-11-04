
(function()

	EEex_DisableCodeProtection()

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

	--[[
	+------------------------------------------------------------------------------------------------------------------------------+
	| BUG: v2.7.3.0 - op180 (CGameEffectRestrictEquipItem) is only honored when actually equipping, unlike op181                   |
	+------------------------------------------------------------------------------------------------------------------------------+
	| op180 (by item resref) and op181 (by item type) add an entry to the target's m_derivedStats, in a list chosen by param2:     |
	|                                                                                                                              |
	|              param2 == 0 ("equip")             param2 != 0 ("use")                                                           |
	|     op180    m_cImmunitiesItemEquip            m_cImmunitiesItemUse                                                          |
	|     op181    m_cImmunitiesItemTypeEquip        m_cImmunitiesItemTypeUse                                                      |
	|                                                                                                                              |
	| The engine reads the op181 lists in more places than the op180 ones:                                                         |
	|   1) CInfGame::GetItemTint() (Lua `item.tint`: "STORTINT" is the inventory's red "unusable" tint) and                        |
	|      CInfGame::CheckItemUsable(short, ...) (inventory Use button, chargen drop slots, CGameSprite::GetRatingWithItem())      |
	|      test m_cImmunitiesItemTypeEquip right after CheckItemUsable(CGameSprite*, ...), but never m_cImmunitiesItemEquip.       |
	|      Only CInfGame::CheckItemSlot() / CInfGame::SwapItemPersonal() (actually equipping) test both lists.                     |
	|   2) CGameSprite::UseItem() refuses items on m_cImmunitiesItemTypeUse, but no code ever reads m_cImmunitiesItemUse.          |
	|                                                                                                                              |
	| op177 / op182 / op183 / op283 decode their .EFF into a temporary child and call its ApplyEffect() directly, which fills the  |
	| very same lists. The fixes below therefore act where the lists are READ, so every way op180 can be applied is covered.       |
	+------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_CheckItemUsable(pThis: CInfGame*, pSprite: CGameSprite*, item: CItem*, errorCode: uint&,         |
	|                                             bAsync: int) -> int                                                              |
	|       return:                                                                                                                |
	|           -> 0        - Not usable (engine result, or the item's resref is on the op180 equip restriction list)              |
	|           -> non-zero - Don't alter engine behavior                                                                          |
	+------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_ShouldRestrictCurItemUse(pSprite: CGameSprite*) -> bool                                          |
	|       return:                                                                                                                |
	|           -> false - Don't alter engine behavior                                                                             |
	|           -> true  - m_curItem's resref is on the op180 use restriction list: take UseItem()'s op181 refusal path            |
	+------------------------------------------------------------------------------------------------------------------------------+
	| Why these hooks (every engine fact below is verified for BG2:EE, BG:EE, and IWD:EE):                                         |
	|   * 1) EEex_ReplaceCall() on both `call CInfGame::CheckItemUsable(CGameSprite*, ...)`. The C++ hook has that function's      |
	|     exact Win64 signature, calls the original, and can only turn "usable" into 0. Both callers already route 0 to the        |
	|     same "unusable" path an op181 hit takes, so no assembly and no register assumptions are needed.                          |
	|   * 2) EEex_HookAfterCallWithLabels() on UseItem()'s `call CImmunitiesItemTypeEquipList::OnList()` (op181 use list). The     |
	|     item being used is not an argument there, but rbx is UseItem()'s `this`: the site itself reads [rbx+m_curItem] and       |
	|     [rbx+m_bAllowEffectListCall] and adds rbx to the list offset. A non-zero eax makes the engine take its own op181         |
	|     refusal path. OnList() already zeroed its effect-copy out-parameter on the miss, so that path deletes nothing extra.     |
	|     The engine reads no volatile register other than eax after the call, which is why only rax is written back.              |
	+------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_Utility_NewScope(function()

		-- These labels are only shipped in v2.7.3.0's pattern database (pattern_dbs/v2.7.3.0.db).
		-- On other engine versions all of them are absent, and vanilla behavior is kept.
		local tintCheckCallAddress = EEex_TryLabel("Hook-CInfGame::GetItemTint()-CheckItemUsableCall")
		local usableCheckCallAddress = EEex_TryLabel("Hook-CInfGame::CheckItemUsable(short,CItem*,ulong&,int)-CheckItemUsableCall")
		local useItemOnListCallAddress = EEex_TryLabel("Hook-CGameSprite::UseItem()-ItemTypeUseOnListCall")

		if tintCheckCallAddress == nil and usableCheckCallAddress == nil and useItemOnListCallAddress == nil then
			return -- Engine version without these labels: keep vanilla op180 behavior
		end

		if tintCheckCallAddress == nil or usableCheckCallAddress == nil or useItemOnListCallAddress == nil then
			-- Fixing only some sites would make op180 behave differently depending on which screen / action consults it
			EEex_Error("op180 fix: incomplete pattern database, expected the GetItemTint(), CheckItemUsable(short), and UseItem() labels")
		end

		----------------------------------------------------------------------------------------------------------
		-- The short pattern signatures only locate the three sites. Validate every instruction the hooks rely  --
		-- on before writing anything, so a mismatch never leaves a half-applied fix behind.                    --
		----------------------------------------------------------------------------------------------------------

		-- `address` must hold `bytes` (`false` matches any byte), optionally followed by an unsigned 32-bit value `u32`
		local expectInstruction = function(address, bytes, u32, description)
			for i = 1, #bytes do
				local byte = bytes[i]
				if byte ~= false and EEex_ReadU8(address + i - 1) ~= byte then
					EEex_Error(string.format("op180 fix: expected `%s` at %s", description, EEex_ToHex(address)))
				end
			end
			if u32 ~= nil and EEex_ReadU32(address + #bytes) ~= u32 then
				EEex_Error(string.format("op180 fix: unexpected 32-bit operand in `%s` at %s", description, EEex_ToHex(address)))
			end
		end

		-- Absolute target of the `call rel32` (E8 xx xx xx xx) at `address`. rel32 is relative to the end of the call.
		local callTarget = function(address)
			return address + 5 + EEex_Read32(address + 1)
		end

		-- 1) CInfGame::GetItemTint(): `call CheckItemUsable(CGameSprite*, ...)`, then `test eax, eax` / `je <"STORTINT">`
		expectInstruction(tintCheckCallAddress, {0xE8}, nil, "call rel32")
		expectInstruction(tintCheckCallAddress + 5, {0x85, 0xC0, 0x0F, 0x84}, nil, "test eax, eax / je rel32")

		-- 1) CInfGame::CheckItemUsable(short, ...): `call CheckItemUsable(CGameSprite*, ...)`, then
		--    `test rdi, rdi` / `je <return eax>` / `test eax, eax` / `je <return 0>` (rdi = item)
		expectInstruction(usableCheckCallAddress, {0xE8}, nil, "call rel32")
		expectInstruction(usableCheckCallAddress + 5, {0x48, 0x85, 0xFF, 0x74, false, 0x85, 0xC0, 0x74, false}, nil,
			"test rdi, rdi / je rel8 / test eax, eax / je rel8")

		-- Both sites must call the same function: CInfGame::CheckItemUsable(CGameSprite*, CItem*, unsigned long&, int)
		local checkItemUsableAddress = callTarget(tintCheckCallAddress)
		if callTarget(usableCheckCallAddress) ~= checkItemUsableAddress then
			EEex_Error("op180 fix: GetItemTint() and CheckItemUsable(short) no longer call the same CheckItemUsable()")
		end

		-- 2) CGameSprite::UseItem(): the op181 use list check around the hooked call (useItemOnListCallAddress = C)
		--     C-47  mov rcx, qword ptr [rbx+m_curItem]
		--     C-40  mov edi, dword ptr [rbx+m_bAllowEffectListCall]
		--     C-34  call CItem::GetItemType
		--     C-29  movzx edx, ax                ; nType
		--     C-26  lea r9, [rbp-0x49]           ; CGameEffect*& (effect copy, deleted by the refusal path when non-null)
		--     C-22  mov eax, m_tempStats.m_cImmunitiesItemTypeUse
		--     C-17  lea r8, [rbp-0x51]           ; unsigned long& (error strref, unused by the refusal path)
		--     C-13  test edi, edi
		--     C-11  mov ecx, m_derivedStats.m_cImmunitiesItemTypeUse
		--     C-6   cmove ecx, eax
		--     C-3   add rcx, rbx
		--     C     call CImmunitiesItemTypeEquipList::OnList   ; hooked
		--     C+5   test eax, eax
		--     C+7   je rel32                    ; <not restricted>, falls through into the refusal path
		local C = useItemOnListCallAddress
		expectInstruction(C - 47, {0x48, 0x8B, 0x8B}, EEex_OffsetOf("CGameSprite.m_curItem"), "mov rcx, qword ptr [rbx+m_curItem]")
		expectInstruction(C - 40, {0x8B, 0xBB}, EEex_OffsetOf("CGameSprite.m_bAllowEffectListCall"), "mov edi, dword ptr [rbx+m_bAllowEffectListCall]")
		expectInstruction(C - 34, {0xE8}, nil, "call rel32")
		expectInstruction(C - 29, {0x0F, 0xB7, 0xD0}, nil, "movzx edx, ax")
		expectInstruction(C - 26, {0x4C, 0x8D, 0x4D, 0xB7}, nil, "lea r9, [rbp-0x49]")
		expectInstruction(C - 22, {0xB8}, EEex_OffsetOf("CGameSprite.m_tempStats.m_cImmunitiesItemTypeUse"), "mov eax, imm32")
		expectInstruction(C - 17, {0x4C, 0x8D, 0x45, 0xAF}, nil, "lea r8, [rbp-0x51]")
		expectInstruction(C - 13, {0x85, 0xFF}, nil, "test edi, edi")
		expectInstruction(C - 11, {0xB9}, EEex_OffsetOf("CGameSprite.m_derivedStats.m_cImmunitiesItemTypeUse"), "mov ecx, imm32")
		expectInstruction(C - 6, {0x0F, 0x44, 0xC8}, nil, "cmove ecx, eax")
		expectInstruction(C - 3, {0x48, 0x03, 0xCB}, nil, "add rcx, rbx")
		expectInstruction(C, {0xE8}, nil, "call rel32")
		expectInstruction(C + 5, {0x85, 0xC0, 0x0F, 0x84}, nil, "test eax, eax / je rel32")

		-- Resolve the native side up front (errors if the matching EEex.dll does not export it)
		local hookCheckItemUsableAddress = EEex_Label("EEex::Fix_Hook_CheckItemUsable")
		local originalCheckItemUsableSlot = EEex_Label("EEex::Fix_Original_CheckItemUsable")
		EEex_Label("EEex::Fix_Hook_ShouldRestrictCurItemUse")

		-------------------------------------------------
		-- [EEex.dll] EEex::Fix_Hook_CheckItemUsable() --
		-------------------------------------------------

		-- The C++ hook calls the engine's CheckItemUsable(CGameSprite*, ...) through this pointer, so it must be set before
		-- any call is retargeted
		EEex_WritePtr(originalCheckItemUsableSlot, checkItemUsableAddress)

		-- `call CheckItemUsable` -> `call EEex::Fix_Hook_CheckItemUsable` (through a near jmp stub, since EEex.dll can be
		-- further than rel32 away from the executable). Same arguments, same stack, same return register.
		EEex_ReplaceCall(tintCheckCallAddress, hookCheckItemUsableAddress)
		EEex_ReplaceCall(usableCheckCallAddress, hookCheckItemUsableAddress)

		---------------------------------------------------------
		-- [EEex.dll] EEex::Fix_Hook_ShouldRestrictCurItemUse() --
		---------------------------------------------------------

		-- Runs right after the engine's op181 OnList() returned. The default after-call watchdog set already ignores
		-- rcx / rdx / r8-r11 (the OnList() call clobbered them anyway); rax is written here on purpose.
		EEex_HookAfterCallWithLabels(useItemOnListCallAddress, {
			{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
			{[[
				test eax, eax
				jnz #L(return)                                       ; op181 already refuses the item: keep the engine's result

				#MAKE_SHADOW_SPACE
				mov rcx, rbx                                         ; pSprite (UseItem()'s `this`, validated above)
				call #L(EEex::Fix_Hook_ShouldRestrictCurItemUse)
				#DESTROY_SHADOW_SPACE
				movzx eax, al                                        ; The engine follows with `test eax, eax` / `je <not restricted>`
			]]}
		)
	end)

	EEex_EnableCodeProtection()

end)()
