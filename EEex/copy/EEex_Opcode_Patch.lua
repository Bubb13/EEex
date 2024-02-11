
(function()

	EEex_DisableCodeProtection()

	--[[
	+--------------------------------------------------------------------------+
	| Clean up EEex data linked to a CGameEffect instance before it is deleted |
	+--------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnDestruct(pEffect: CGameEffect*)         |
	+--------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameEffect::Destruct()_FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rcx, rdi                          ; pEffect
			call #L(EEex::Opcode_Hook_OnDestruct)
		]]}
	)

	--[[
	+---------------------------------------------------------------------------------------------+
	| Associate EEex data linked to a CGameEffect instance with a new CGameEffect instance (copy) |
	+---------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnCopy(pSrcEffect: CGameEffect*, pDstEffect: CGameEffect*)   |
	+---------------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameEffect::CopyFromBase()-FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			; This is the only caller that isn't working with a CGameEffect.
			mov rax, #$(1) ]], {EEex_Label("Data-CGameEffect::DecodeEffectFromBase()-After-CGameEffect::CopyFromBase()")}, [[ #ENDL
			cmp qword ptr ss:[rsp+0x38], rax
			je #L(return)

			mov rdx, rdi                                             ; pDstEffect
			lea rcx, qword ptr ds:[rsi-#$(1)] ]], {EEex_PtrSize}, [[ ; pSrcEffect
			call #L(EEex::Opcode_Hook_OnCopy)
		]]}
	)

	--[[
	+-------------------------------------------------------------------------------------+
	| Call a hook immediately after sprites have had both of their effect lists evaluated |
	+-------------------------------------------------------------------------------------+
	|   Used to implement listeners that act as "final" operations on a sprite            |
	+-------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_AfterListsResolved(pSprite: CGameSprite*)            |
	+-------------------------------------------------------------------------------------+
	|   [Lua] EEex_Opcode_LuaHook_AfterListsResolved(sprite: CGameSprite)                 |
	+-------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::ProcessEffectList()-AfterListsResolved"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rcx, rsi                                  ; pSprite
			call #L(EEex::Opcode_Hook_AfterListsResolved)
		]]}
	)

	--------------------------------------
	--          Opcode Changes          --
	--------------------------------------

	--[[
	+--------------------------------------------------------------------------------------------------+
	| Opcode #214                                                                                      |
	+--------------------------------------------------------------------------------------------------+
	|   param2 == 3 -> Call the global Lua function with the name in `resource` to get a CButtonData   |
	|                  iterator. Then, use this iterator to determine which spells should be shown to  |
	|                  the player. Note that the function name must be 8 characters or less, and be    |
	|                  ALL UPPERCASE.                                                                  |
	|                                                                                                  |
	|   resource    -> Name of the global Lua function when `param2 == 3`                              |
	+--------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Opcode_Hook_OnOp214ApplyEffect(effect: CGameEffect, sprite: CGameSprite) -> boolean |
	|       return:                                                                                    |
	|           false -> Effect not handled                                                            |
	|           true  -> Effect handled (skip normal code)                                             |
	+--------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameEffectSecondaryCastList::ApplyEffect()"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(64)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			]]},
			EEex_GenLuaCall("EEex_Opcode_Hook_OnOp214ApplyEffect", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error

				call_error:
				mov rax, 1

				no_error:
				test rax, rax
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
				jz #L(return)

				mov eax, 1
				#MANUAL_HOOK_EXIT(1)
				ret
			]]},
		})
	)
	-- Manually define the ignored registers for the unusual `ret` above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("Hook-CGameEffectSecondaryCastList::ApplyEffect()"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
		EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
		EEex_HookIntegrityWatchdogRegister.R11
	})

	--[[
	+---------------------------------------------------------------------------------------------------------------------+
	| Opcode #248                                                                                                         |
	+---------------------------------------------------------------------------------------------------------------------+
	|   (special & 1) != 0 -> .EFF bypasses op120                                                                         |
	+---------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnOp248AddTail(pOp248: CGameEffect*, pExtraEffect: CGameEffect*)                     |
	+---------------------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp248(sprite: CGameSprite, targetSprite: CGameSprite, blocked: boolean) |
	+---------------------------------------------------------------------------------------------------------------------+
	--]]

	---------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_OnOp248AddTail() --
	---------------------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameEffectMeleeEffect::ApplyEffect()-AddTail"),  {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rdx, rbx                              ; pEffect
			mov rcx, rdi                              ; pOp248
			call #L(EEex::Opcode_Hook_OnOp248AddTail)
		]]}
	)

	-------------------------------------------------------
	-- [Lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp248() --
	-------------------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-Melee"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(64)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		]]},
		EEex_GenLuaCall("EEex_Opcode_Hook_OnAfterSwingCheckedOp248", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "CGameSprite" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rax #ENDL", {rspOffset}}, "boolean" end,
			},
		}),
		{[[
			call_error:
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	--[[
	+---------------------------------------------------------------------------------------------------------------------+
	| Opcode #249                                                                                                         |
	+---------------------------------------------------------------------------------------------------------------------+
	|   (special & 1) != 0 -> .EFF bypasses op120                                                                         |
	+---------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnOp249AddTail(pOp249: CGameEffect*, pExtraEffect: CGameEffect*)                     |
	+---------------------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp249(sprite: CGameSprite, targetSprite: CGameSprite, blocked: boolean) |
	+---------------------------------------------------------------------------------------------------------------------+
	--]]

	---------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_OnOp249AddTail() --
	---------------------------------------------------

	local op249SavedEffect = EEex_Malloc(EEex_PtrSize)

	EEex_HookBeforeRestore(EEex_Label("Hook-CGameEffectRangeEffect::ApplyEffect()"), 0, 6, 6, {[[
		mov qword ptr ds:[#$(1)], rcx ]], {op249SavedEffect}, [[ #ENDL
	]]})

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameEffectRangeEffect::ApplyEffect()-AddTail"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rdx, rbx                                             ; pEffect
			mov rcx, qword ptr ss:[#$(1)] ]], {op249SavedEffect}, [[ ; pOp249
			call #L(EEex::Opcode_Hook_OnOp249AddTail)
		]]}
	)

	-------------------------------------------------------
	-- [Lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp249() --
	-------------------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-Ranged"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(64)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		]]},
		EEex_GenLuaCall("EEex_Opcode_Hook_OnAfterSwingCheckedOp249", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "CGameSprite" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rax #ENDL", {rspOffset}}, "boolean" end,
			},
		}),
		{[[
			call_error:
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE

			test rax, rax
			jz #L(return)

			#MANUAL_HOOK_EXIT(0)
			; The consequence of not running the else block is that this boilerplate is not executed
			mov rsi, qword ptr ss:[rsp+0x70]
			lea r13, qword ptr ds:[r15+0xC]
			jmp #L(Hook-CGameSprite::Swing()-NoCImmunitiesWeaponElseContinue)
		]]},
	}))

	--[[
	+------------------------------------------------------------------------------------------------------+
	| Opcode #280                                                                                          |
	+------------------------------------------------------------------------------------------------------+
	|   param1  != 0 -> Force wild surge number to param1                                                  |
	|   special != 0 -> Suppress wild surge feedback string and visuals                                    |
	+------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op280_BeforeApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) |
	+------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op280_GetForcedWildSurgeNumber(pSprite: CGameSprite*) -> int          |
	|       return -> Forced wild surge number                                                             |
	+------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op280_ShouldSuppressWildSurgeVisuals(pSprite: CGameSprite*) -> bool   |
	|       return:                                                                                        |
	|           false -> Don't alter engine behavior                                                       |
	|           true  -> Suppress wild surge feedback string and visuals                                   |
	+------------------------------------------------------------------------------------------------------+
	--]]

	------------------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_Op280_BeforeApplyEffect() --
	------------------------------------------------------------

	-- Store op280 param1 and special as stats
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameEffectForceSurge::ApplyEffect()-FirstInstruction"), 0, 9, 9, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(16)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx


															   ; rdx already pSprite
															   ; rcx already pEffect
			call #L(EEex::Opcode_Hook_Op280_BeforeApplyEffect)

			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-------------------------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_Op280_GetForcedWildSurgeNumber() --
	-------------------------------------------------------------------

	-- Override wild surge number if op280 param1 is non-zero
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameSprite::WildSpell()-OverrideSurgeNumber"), 0, 9, 9, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11, EEex_HookIntegrityWatchdogRegister.R13
		}}},
		{[[
			mov rcx, r14						                      ; pSprite
			call #L(EEex::Opcode_Hook_Op280_GetForcedWildSurgeNumber)

			test eax, eax
			cmovnz r13d, eax
		]]}
	)

	-------------------------------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_Op280_ShouldSuppressWildSurgeVisuals() --
	-------------------------------------------------------------------------

	-- Suppress feedback string if op280 special is non-zero
	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameSprite::WildSpell()-CGameSprite::Feedback()"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11}}},
		{[[
			#MAKE_SHADOW_SPACE(32)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9

																			; rcx already pSprite
			call #L(EEex::Opcode_Hook_Op280_ShouldSuppressWildSurgeVisuals)
			test al, al

			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
			jnz #L(return_skip)
		]]}
	)

	-- Suppress random visual effect if op280 special is non-zero
	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::WildSpell()-SuppressVisualEffectJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			mov rcx, r14                                                    ; pSprite
			call #L(EEex::Opcode_Hook_Op280_ShouldSuppressWildSurgeVisuals)
			test al, al
			jnz #L(jmp_success)
		]]}
	)

	-- Suppress adding SPFLESHS CVisualEffect object to the area if op280 special is non-zero
	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameSprite::WildSpell()-CVisualEffect::Load()-SPFLESHS"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11}}},
		{[[
			#MAKE_SHADOW_SPACE(32)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9

			mov rcx, r14                                                    ; pSprite
			call #L(EEex::Opcode_Hook_Op280_ShouldSuppressWildSurgeVisuals)
			test al, al
			jz normal

			; This is normally done by the CVisualEffect::Load() call
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			call #L(CString::Destruct)

			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
			jmp #L(return_skip)

			normal:
			#RESUME_SHADOW_ENTRY
			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- Make SPFLESHS message nullptr if op280 special is non-zero
	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameSprite::WildSpell()-operator_new()-SPFLESHS"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

			mov rcx, r14                                                    ; pSprite
			call #L(EEex::Opcode_Hook_Op280_ShouldSuppressWildSurgeVisuals)
			test al, al

			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
			jz #L(return)

			xor rax, rax
			jmp #L(return_skip)
		]]}
	)

	-- Only send SPFLESHS message if it is non-nullptr
	EEex_HookBeforeCall(EEex_Label("Hook-CGameSprite::WildSpell()-CMessageHandler::AddMessage()-SPFLESHS"), {[[
		test rdx, rdx
		jz #L(return_skip)
	]]})

	--[[
	+----------------------------------------------------------------------------------------------------------+
	| Opcode #326                                                                                              |
	+----------------------------------------------------------------------------------------------------------+
	|   (special & 1) != 0 -> Flip what SPLPROT.2DA considers the "source" and "target" sprites                |
	+----------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ApplySpell_ShouldFlipSplprotSourceAndTarget(pEffect: CGameEffect*) -> int |
	|       return:                                                                                            |
	|            0 -> Don't alter engine behavior                                                              |
	|           !0 -> Flip what SPLPROT.2DA considers the "source" and "target" sprites                        |
	+----------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CGameEffectApplySpell::ApplyEffect()-OverrideSplprotContext"), 0, 7, 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}},
		{"manual_return", true}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(32)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9

				mov rcx, rbx                                                           ; pEffect
				call #L(EEex::Opcode_Hook_ApplySpell_ShouldFlipSplprotSourceAndTarget)

				test rax, rax
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
				jnz #L(flip)

				#MANUAL_HOOK_EXIT(0)
				jmp #L(return)

				flip:
				mov rax, r8
				mov r8, r9
				mov r9, rax
				#MANUAL_HOOK_EXIT(1)
				jmp #L(return)
			]]},
		})
	)
	-- Manually define the ignored registers for the "flip" branch above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("Hook-CGameEffectApplySpell::ApplyEffect()-OverrideSplprotContext"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
		EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
	})

	--[[
	+-----------------------------------------------------------------+
	| Opcode #333                                                     |
	+-----------------------------------------------------------------+
	|   (param3 & 1) != 0 -> Only check saving throw once             |
	+-----------------------------------------------------------------+
	|   [Lua] EEex_Opcode_Hook_OnOp333CopiedSelf(effect: CGameEffect) |
	+-----------------------------------------------------------------+
	--]]

	EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CGameEffectStaticCharge::ApplyEffect()-CopyOp333Call"), 0, 9, 9, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(56)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			]]},
			EEex_GenLuaCall("EEex_Opcode_Hook_OnOp333CopiedSelf", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rax #ENDL", {rspOffset}}, "CGameEffect" end,
				},
			}),
			{[[
				call_error:
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--[[
	+------------------------------------------------------------------------------------------------+
	| Allow saving throw BIT23 to bypass opcode #101                                                 |
	+------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op101_ShouldEffectBypassImmunity(pEffect: CGameEffect*) -> bool |
	|       return:                                                                                  |
	|           false -> Don't alter engine behavior                                                 |
	|           true  -> Bypass opcode #101                                                          |
	+------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CImmunitiesEffect::OnList()-Entry"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(16)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx

				mov rcx, rdx                                                ; pEffect
				call #L(EEex::Opcode_Hook_Op101_ShouldEffectBypassImmunity)

				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE

				test al, al
				jz #L(return)

				xor rax, rax
				#MANUAL_HOOK_EXIT(1)
				ret
			]]},
		})
	)
	-- Manually define the ignored registers for the unusual `ret` above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("Hook-CImmunitiesEffect::OnList()-Entry"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
		EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
		EEex_HookIntegrityWatchdogRegister.R11
	})

	-----------------------------------
	--          New Opcodes          --
	-----------------------------------

	local genOpcodeDecode = function(args)

		local writeConstructor = function(vftable)
			return EEex_JITNear({[[
				push rbx
				sub rsp, 40h
				mov rax, qword ptr ss:[rsp+70h]
				mov rbx, rcx
				mov dword ptr ss:[rsp+30h], 0xFFFFFFFF
				mov dword ptr ss:[rsp+28h], 0x0
				mov qword ptr ss:[rsp+20h], rax
				call #L(CGameEffect::Construct)
				lea rax, qword ptr ds:[#$(1)] ]], {vftable}, [[ #ENDL
				mov qword ptr ds:[rbx], rax
				mov rax, rbx
				add rsp, 40h
				pop rbx
				ret
			]]})
		end

		local writeCopy = function(vftable)
			return EEex_JITNear({[[
				mov qword ptr ss:[rsp+8h], rbx
				mov qword ptr ss:[rsp+10h], rbp
				mov qword ptr ss:[rsp+18h], rsi
				push rdi
				sub rsp, 40h
				mov rsi, rcx
				call #L(CGameEffect::GetItemEffect)
				mov ecx, 158h
				mov rbp, rax
				call #L(operator_new)
				xor edi, edi
				mov rbx, rax
				test rax, rax
				je _1
				mov rdx, qword ptr ds:[rsi+88h]
				lea r8, qword ptr ds:[rsi+80h]
				mov r9d, dword ptr ds:[rsi+110h]
				mov rcx, rax
				mov dword ptr ss:[rsp+30h], 0xFFFFFFFF
				mov dword ptr ss:[rsp+28h], edi
				mov qword ptr ss:[rsp+20h], rdx
				mov rdx, rbp
				call #L(CGameEffect::Construct)
				lea rax, qword ptr ds:[#$(1)] ]], {vftable}, [[ #ENDL
				mov qword ptr ds:[rbx], rax
				jmp _2
				_1:
				mov rbx, rdi
				_2:
				mov edx, 30h
				mov rcx, rbp
				call #L(Hardcoded_free) ; SDL_FreeRW
				test rsi, rsi
				lea rdx, qword ptr ds:[rsi+8h]
				mov rcx, rbx
				cmove rdx, rdi
				call #L(CGameEffect::CopyFromBase)
				mov rbp, qword ptr ss:[rsp+58h]
				mov rax, rbx
				mov rbx, qword ptr ss:[rsp+50h]
				mov rsi, qword ptr ss:[rsp+60h]
				add rsp, 40h
				pop rdi
				ret
			]]})
		end

		local genDecode = function(constructor)
			return {[[
				mov ecx, #$(1) ]], {CGameEffect.sizeof}, [[ #ENDL
				call #L(operator_new)
				mov rcx, rax                                      ; this
				test rax, rax
				jz #L(Hook-CGameEffect::DecodeEffect()-Fail)
				mov rax, qword ptr ds:[rsi]                       ; target
				mov qword ptr [rsp+20h], rax
				mov r9d, ebp                                      ; sourceID
				mov r8, r14                                       ; source
				mov rdx, rdi                                      ; effect
				call #$(1) ]], {constructor}, [[ #ENDL
				jmp #L(Hook-CGameEffect::DecodeEffect()-Success)
			]]}
		end

		local vtblsize = _G["CGameEffect::vtbl"].sizeof
		local newvtbl = EEex_Malloc(vtblsize)
		EEex_Memcpy(newvtbl, EEex_Label("Data-CGameEffect::vftable"), vtblsize)

		EEex_WriteArgs(newvtbl, args, {
			{ "__vecDelDtor",  0  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "Copy",          1  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.DEFAULT, writeCopy(newvtbl) },
			{ "ApplyEffect",   2  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "ResolveEffect", 3  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "OnAdd",         4  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "OnAddSpecific", 5  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "OnLoad",        6  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "CheckSave",     7  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "UsesDice",      8  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "DisplayString", 9  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
			{ "OnRemove",      10 * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		})

		return genDecode(writeConstructor(newvtbl))
	end

	--[[
	+----------------------------------------------------------------------------------------------------------------------+
	| New Opcode #400 (SetTemporaryAIScript)                                                                               |
	+----------------------------------------------------------------------------------------------------------------------+
	|   Temporarily set a script level and restore the old script when the effect is removed.                              |
	|   NOTE: This is dangerous! Script changes from any other mechanism will be lost when the effect expires.             |
	+----------------------------------------------------------------------------------------------------------------------+
	|   param2   -> Script level to set                                                                                    |
	|   resource -> Script to set                                                                                          |
	+----------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_SetTemporaryAIScript_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int |
	|       return:                                                                                                        |
	|            0 -> Halt effect list processing                                                                          |
	|           !0 -> Continue effect list processing                                                                      |
	+----------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_SetTemporaryAIScript_OnRemove(pEffect: CGameEffect*, pSprite: CGameSprite*)           |
	+----------------------------------------------------------------------------------------------------------------------+
	--]]

	local EEex_SetTemporaryAIScript = genOpcodeDecode({

		["ApplyEffect"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_SetTemporaryAIScript_ApplyEffect)
			#DESTROY_SHADOW_SPACE
			ret
		]]},

		["OnRemove"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_SetTemporaryAIScript_OnRemove)
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	})

	--[[
	+-----------------------------------------------------------------------------------------------------------------+
	| New Opcode #401 (SetExtendedStat)                                                                               |
	+-----------------------------------------------------------------------------------------------------------------+
	|   Modify the value of an extended stat. All operations are clamped such that results outside of the stat's      |
	|   range will resolve to the exceeded extrema.                                                                   |
	|                                                                                                                 |
	|   Extended stats are those with ids outside of the vanilla range in STATS.IDS.                                  |
	|   Extended stat minimums, maximums, and defaults are defined in X-STATS.2DA.                                    |
	+-----------------------------------------------------------------------------------------------------------------+
	|   param1  -> Modification amount                                                                                |
	|                                                                                                                 |
	|   param2  -> Modification type:                                                                                 |
	|                  0 -> Sum     - stat = stat + param1                                                            |
	|                  1 -> Set     - stat = param1                                                                   |
	|                  2 -> Percent - stat = stat * param1 / 100                                                      |
	|                                                                                                                 |
	|   special -> Extended stat id                                                                                   |
	+-----------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_SetExtendedStat_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int |
	|       return:                                                                                                   |
	|            0 -> Halt effect list processing                                                                     |
	|           !0 -> Continue effect list processing                                                                 |
	+-----------------------------------------------------------------------------------------------------------------+
	--]]

	local EEex_SetExtendedStat = genOpcodeDecode({
		["ApplyEffect"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_SetExtendedStat_ApplyEffect)
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	})

	--[[
	+-----------------------------------------------------------------------------------------------------------------+
	| New Opcode #402 (InvokeLua)                                                                                     |
	+-----------------------------------------------------------------------------------------------------------------+
	|   Invoke a global Lua function. Note that the function name must be 8 characters or less, and be ALL UPPERCASE. |
	|                                                                                                                 |
	|   The function's signature is: FUNC(op402: CGameEffect, sprite: CGameSprite)                                    |
	+-----------------------------------------------------------------------------------------------------------------+
	|   resource -> Global Lua function name                                                                          |
	+-----------------------------------------------------------------------------------------------------------------+
	|   [JIT]                                                                                                         |
	+-----------------------------------------------------------------------------------------------------------------+
	--]]

	local EEex_InvokeLua = genOpcodeDecode({

		["ApplyEffect"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(64)
			mov rax, qword ptr ds:[rcx+30h] ; res
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
			mov byte ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], 0

			]], EEex_GenLuaCall(nil, {
				["functionSrc"] = {[[
					lea rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rcx, rbx
					#ALIGN
					call #L(Hardcoded_lua_getglobal)
					#ALIGN_END
				]]},
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),
	})

	--[[
	+---------------------------------------------------------------------------------------------------------------+
	| New Opcode #403 (ScreenEffects)                                                                               |
	+---------------------------------------------------------------------------------------------------------------+
	|   Register a global Lua function that is called whenever an effect is added to the target creature. If this   |
	|   function returns `true` the effect being added is blocked. Note that the function name must be 8 characters |
	|   or less, and be ALL UPPERCASE.                                                                              |
	|                                                                                                               |
	|   The function's signature is: FUNC(op403: CGameEffect, effect: CGameEffect, sprite: CGameSprite) -> boolean  |
	+---------------------------------------------------------------------------------------------------------------+
	|   resource -> Global Lua function name                                                                        |
	+---------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ScreenEffects_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int |
	|       return:                                                                                                 |
	|            0 -> Halt effect list processing                                                                   |
	|           !0 -> Continue effect list processing                                                               |
	+---------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnCheckAdd(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int                |
	|       return:                                                                                                 |
	|            0 -> Don't alter engine behavior                                                                   |
	|           !0 -> Block effect                                                                                  |
	+---------------------------------------------------------------------------------------------------------------+
	--]]

	--------------------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_ScreenEffects_ApplyEffect() --
	--------------------------------------------------------------

	local EEex_ScreenEffects = genOpcodeDecode({
		["ApplyEffect"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_ScreenEffects_ApplyEffect)
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	})

	-----------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_OnCheckAdd() --
	-----------------------------------------------

	local effectBlockedHack = EEex_Malloc(0x8)

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameEffect::CheckAdd()-LastProbabilityJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(8)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx

				mov rdx, r14                          ; pSprite
				mov rcx, rdi                          ; pEffect
				call #L(EEex::Opcode_Hook_OnCheckAdd)

				mov qword ptr ds:[#$(1)], rax ]], {effectBlockedHack}, [[ #ENDL

				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
				test rax, rax
				jz #L(jmp_fail)

				#MANUAL_HOOK_EXIT(0)
				jmp #L(Hook-CGameEffect::CheckAdd()-ProbabilityFailed)
			]]},
		})
	)

	EEex_HookConditionalJumpOnSuccess(EEex_Label("Hook-CGameSprite::AddEffect()-noSave-Override"), 3, {[[
		cmp qword ptr ds:[#$(1)], 0 ]], {effectBlockedHack}, [[ #ENDL
		jnz #L(jmp_fail)
	]]})

	--[[
	+-------------------------------------------------------------------------------------------------------------------+
	| New Opcode #408 (ProjectileMutator)                                                                               |
	+-------------------------------------------------------------------------------------------------------------------+
	|   Register a global Lua table that (potentially) contains several different functions that mutate projectiles.    |
	|   Note that the table name must be 8 characters or less, and be ALL UPPERCASE.                                    |
	|                                                                                                                   |
	|   The function signatures are:                                                                                    |
	|                                                                                                                   |
	|       typeMutator(context: table) -> number                                                                       |
	|                                                                                                                   |
	|           context:                                                                                                |
	|                                                                                                                   |
	|               decodeSource: EEex_Projectile_DecodeSource - The source of the hook	                                |
	|                                                                                                                   |
	|               originatingEffect: CGameEffect | nil - The op408 effect that registered the mutator table           |
	|                                                                                                                   |
	|               originatingSprite: CGameSprite | nil - The sprite that is decoding (creating) the projectile        |
	|                                                                                                                   |
	|               projectileType: number - The projectile type about to be decoded. This is equivalent to the value   |
	|                                        at .SPL->Ability Header->[+0x26]. Subtract one from this value to get the  |
	|                                        corresponding PROJECTL.IDS index.                                          |
	|                                                                                                                   |
	|           return -> The new projectile type, or nil if the type should not be overridden. This is equivalent to   |
	|                     the value at .SPL->Ability Header->[+0x26]. Subtract one from this value to get the           |
	|                     corresponding PROJECTL.IDS index.                                                             |
	|                                                                                                                   |
	|       projectileMutator(context: table)                                                                           |
	|                                                                                                                   |
	|           context:                                                                                                |
	|                                                                                                                   |
	|               decodeSource: EEex_Projectile_DecodeSource - The source of the hook                                 |
	|                                                                                                                   |
	|               originatingEffect: CGameEffect | nil - The op408 effect that registered the mutator table           |
	|                                                                                                                   |
	|               originatingSprite: CGameSprite | nil - The sprite that is decoding (creating) the projectile        |
	|                                                                                                                   |
	|               projectile: CProjectile - The projectile about to be returned from the decoding process             |
	|                                                                                                                   |
	|       effectMutator(context: table)                                                                               |
	|                                                                                                                   |
	|           context:                                                                                                |
	|                                                                                                                   |
	|               addEffectSource: EEex_Projectile_AddEffectSource - The source of the hook                           |
	|                                                                                                                   |
	|               effect: CGameEffect - The effect that is being added to projectile                                  |
	|                                                                                                                   |
	|               originatingEffect: CGameEffect | nil - The op408 effect that registered the mutator table           |
	|                                                                                                                   |
	|               originatingSprite: CGameSprite | nil - The sprite that decoded (created) the projectile             |
	|                                                                                                                   |
	|               projectile: CProjectile - The projectile that `effect` is being added to                            |
	|                                                                                                                   |
	+-------------------------------------------------------------------------------------------------------------------+
	|   resource -> Global Lua table name                                                                               |
	+-------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ProjectileMutator_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int |
	|       return:                                                                                                     |
	|            0 -> Don't alter engine behavior                                                                       |
	|           !0 -> Block effect                                                                                      |
	+-------------------------------------------------------------------------------------------------------------------+
	--]]

	local EEex_ProjectileMutator = genOpcodeDecode({
		["ApplyEffect"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_ProjectileMutator_ApplyEffect)
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	})

	--[[
	+----------------------------------------------------------------------------------------------------------------------+
	| New Opcode #409 (EnableActionListener)                                                                               |
	+----------------------------------------------------------------------------------------------------------------------+
	|   Enable an action listener previously registered by EEex_Action_AddEnabledSpriteStartedActionListener(). The action |
	|   listener will then be called whenever the target sprite starts a new action. Note that the function name must be 8 |
	|   characters or less, and be ALL UPPERCASE.                                                                          |
	|                                                                                                                      |
	|   The function's signature is: listener(sprite: CGameSprite, action: CAIAction, op409: CGameEffect)                  |
	+----------------------------------------------------------------------------------------------------------------------+
	|   param1:                                                                                                            |
	|        0 -> Action listener disabled                                                                                 |
	|       !0 -> Action listener enabled                                                                                  |
	|                                                                                                                      |
	|   resource -> The name of the function as registered by EEex_Action_AddEnabledSpriteStartedActionListener()          |
	+----------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_EnableActionListener_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int |
	|       return:                                                                                                        |
	|            0 -> Don't alter engine behavior                                                                          |
	|           !0 -> Block effect                                                                                         |
	+----------------------------------------------------------------------------------------------------------------------+
	--]]

	local EEex_EnableActionListener = genOpcodeDecode({
		["ApplyEffect"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_EnableActionListener_ApplyEffect)
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	})

	--[[
	+-------------------------------------+
	| [JIT] Decode switch for new opcodes |
	+-------------------------------------+
	--]]

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameEffect::DecodeEffect()-DefaultJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({[[

			mov qword ptr ss:[rsp+60h], r15 ; save non-volatile register since I resume control flow from an EEex
											; opcode to somewhere that expects this stack location to be filled

			cmp eax, 400
			jne _401
			]], EEex_SetTemporaryAIScript, [[

			_401:
			cmp eax, 401
			jne _402
			]], EEex_SetExtendedStat, [[

			_402:
			cmp eax, 402
			jne _403
			]], EEex_InvokeLua, [[

			_403:
			cmp eax, 403
			jne _408
			]], EEex_ScreenEffects, [[

			_408:
			cmp eax, 408
			jne _409
			]], EEex_ProjectileMutator, [[

			_409:
			cmp eax, 409
			jne #L(jmp_success)
			]], EEex_EnableActionListener, [[
		]]})
	)
	EEex_HookIntegrityWatchdog_IgnoreStackSizes(EEex_Label("Hook-CGameEffect::DecodeEffect()-DefaultJmp"), {{0x60, 8}})

	EEex_EnableCodeProtection()

end)()
