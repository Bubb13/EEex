
(function()

	EEex_DisableCodeProtection()

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

	EEex_EnableCodeProtection()

end)()
