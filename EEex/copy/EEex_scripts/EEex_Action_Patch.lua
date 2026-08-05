
(function()

	EEex_DisableCodeProtection()

	--[[
	+-------------------------------------------------------------------------------------------------------------+
	| Block disallowed actions while B3_STATE_DAZED is active                                                     |
	+-------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Action_Hook_ShouldDazeBlockAction(evaluator: CGameAIBase*) -> int                        |
	|       return:                                                                                               |
	|           ->  0 - Allow the current action                                                                  |
	|           -> !0 - Current action was converted to NoAction(); keep the engine on its normal dispatch path   |
	+-------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CGameAIBase::ExecuteAction()-DefaultJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], r8

			mov rcx, rbx                                          ; pAIBase
			call #L(EEex::Action_Hook_ShouldDazeBlockAction)

			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			test eax, eax
			jz daze_allow_base

			xor r8d, r8d                                          ; Dispatch as NoAction()

			daze_allow_base:
			#DESTROY_SHADOW_SPACE
			cmp r8d, 0x1D5
		]]}
	)

	EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CGameSprite::ExecuteAction()-DefaultJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(32)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r9
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r10

			mov rcx, rdi                                          ; pSprite as CGameAIBase
			call #L(EEex::Action_Hook_ShouldDazeBlockAction)

			mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			test eax, eax
			jz daze_allow_sprite

			xor ecx, ecx                                          ; Dispatch as NoAction()

			daze_allow_sprite:
			#DESTROY_SHADOW_SPACE
			cmp ecx, 0x1D7
		]]}
	)

	--[[
	+--------------------------------------------------------------------------------+
	| Implement new actions                                                          |
	+--------------------------------------------------------------------------------+
	|   472 EEex_LuaAction(S:Chunk*)                                                 |
	|   473 EEex_MatchObject(S:Chunk*)                                               |
	|   473 EEex_MatchObjectEx(S:Chunk*,I:Nth*,I:Range*,I:Flags*X-MATOBJ)            |
	|   474 EEex_SetTarget(S:Name*,O:Target*)                                        |
	|   476 EEex_SpellObjectOffset(O:Target*,I:Spell*Spell,P:Offset*)                |
	|   476 EEex_SpellObjectOffsetRES(S:RES*,O:Target*,P:Offset*)                    |
	|   477 EEex_SpellObjectOffsetNoDec(O:Target*,I:Spell*Spell,P:Offset*)           |
	|   477 EEex_SpellObjectOffsetNoDecRES(S:RES*,O:Target*,P:Offset*)               |
	|   478 EEex_ForceSpellObjectOffset(O:Target*,I:Spell*Spell,P:Offset*)           |
	|   478 EEex_ForceSpellObjectOffsetRES(S:RES*,O:Target*,P:Offset*)               |
	|   479 EEex_ReallyForceSpellObjectOffset(O:Target*,I:Spell*Spell,P:Offset*)     |
	|   479 EEex_ReallyForceSpellObjectOffsetRES(S:RES*,O:Target*,P:Offset*)         |
	+--------------------------------------------------------------------------------+
	|   [Lua] EEex_Action_Hook_OnEvaluatingUnknown(evaluator: CGameAIBase) -> number |
	|       return -> Set as internal action return value:                           |
	|           -> EEex_Action_ReturnType.ACTION_STOPPED                             |
	|           -> EEex_Action_ReturnType.ACTION_ERROR                               |
	|           -> EEex_Action_ReturnType.ACTION_DONE                                |
	|           -> EEex_Action_ReturnType.ACTION_NORMAL                              |
	|           -> EEex_Action_ReturnType.ACTION_INTERRUPTABLE                       |
	|           -> EEex_Action_ReturnType.ACTION_NO_ACTION                           |
	+--------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameAIBase::ExecuteAction()-DefaultCase"), 0, 7, 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.RSI, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11,
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Action_Hook_OnEvaluatingUnknown", {
				["args"] = {
					function(rspOffset) return {[[
						mov qword ptr ss:[rsp+#$(1)], rbx
					]], {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
				},
				["returnType"] = EEex_LuaCallReturnType.Number,
			}),
			{[[
				mov esi, eax
				#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
				#MANUAL_HOOK_EXIT(0)
				jmp #L(Hook-CGameAIBase::ExecuteAction()-NormalBranch)

				call_error:
				#RESUME_SHADOW_ENTRY
				#DESTROY_SHADOW_SPACE
			]]}
		})
	)

	--[[
	+----------------------------------------------------------------------------------+
	| Implement "sprite started action" listeners                                      |
	+----------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Action_Hook_OnAfterSpriteStartedAction(pSprite: CGameSprite*) |
	+----------------------------------------------------------------------------------+
	|   [Lua] EEex_Action_LuaHook_OnAfterSpriteStartedAction(sprite: CGameSprite)      |
	+----------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("CGameSprite::SetCurrAction()-LastCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			cmp word ptr ds:[r14], 0 ; Don't call the hook for NoAction() since the engine spams it
			jz #L(return)

			mov rcx, rdi                                          ; pSprite
			call #L(EEex::Action_Hook_OnAfterSpriteStartedAction)
		]]}
	)

	EEex_EnableCodeProtection()

end)()
