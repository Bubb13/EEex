
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
	| Call a hook immediately after a sprite has had both of its effect lists evaluated,  |
	| and once the engine permits the sprite's effect list to be evaluated once again     |
	+-------------------------------------------------------------------------------------+
	|   Used to implement listeners that act as "final" operations on a sprite            |
	+-------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_AfterListsResolved(pSprite: CGameSprite*)            |
	+-------------------------------------------------------------------------------------+
	|   [Lua] EEex_Opcode_LuaHook_AfterListsResolved(sprite: CGameSprite)                 |
	+-------------------------------------------------------------------------------------+
	|   [Lua] EEex_Sprite_LuaHook_OnSpellDisableStateChanged(sprite: CGameSprite)         |
	+-------------------------------------------------------------------------------------+
	--]]

	for _, entry in ipairs({
		{"Hook-CGameSprite::ProcessEffectList()-AfterListsResolved-1", 7},
		{"Hook-CGameSprite::ProcessEffectList()-AfterListsResolved-2", 3}, })
	do
		EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label(entry[1]), entry[2], {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
				EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
				EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				mov rcx, rsi                                  ; pSprite
				call #L(EEex::Opcode_Hook_AfterListsResolved)
			]]}
		)
	end

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::ProcessEffectList()-AfterListsResolved-3"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rcx, rsi                                  ; pSprite
			call #L(EEex::Opcode_Hook_AfterListsResolved)
		]]}
	)

	--[[
	+-----------------------------------------------------------------------------------------------+
	| Flush coalesced lists-resolved listeners near the end of the sprite's real AI processing pass |
	+-----------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_FlushDeferredAfterListsResolved(pSprite: CGameSprite*)         |
	+-----------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameSprite::ProcessAI()-BeforeReturn"), 0, 8, 8, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			mov rcx, rsi                                               ; pSprite
			call #L(EEex::Opcode_Hook_FlushDeferredAfterListsResolved)
		]]}
	)

	--------------------------------------
	--          Opcode Changes          --
	--------------------------------------

	--[[
	+------------------------------------------------------------------------------------+
	| Opcode #146                                                                        |
	+------------------------------------------------------------------------------------+
	|   (special & 1) != 0 and param2 == 0 -> Queue SpellNoDec() instead of ForceSpell() |
	+------------------------------------------------------------------------------------+
	|   [JIT]                                                                            |
	+------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameEffectCastSpell::ApplyEffect()-CMessageHandler::AddMessage()"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			test dword ptr ds:[rsi+#OFFSET_OF(CGameEffect.m_special)], 1                    ; (this->m_special & 1) != 0 ?
			jz #L(return)                                                                   ;     no  -> keep ForceSpell()
			mov word ptr ds:[rdx+#OFFSET_OF(CMessageInsertAction.m_action.m_actionID)], 191 ;     yes -> swap to SpellNoDec()
		]]}
	)

	--[[
	+----------------------------------------------------------------------------------------------+
	| Opcode #148                                                                                  |
	+----------------------------------------------------------------------------------------------+
	|   (special & 1) != 0 and param2 == 0 -> Queue SpellPointNoDec() instead of ForceSpellPoint() |
	+----------------------------------------------------------------------------------------------+
	|   [JIT]                                                                                      |
	+----------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameEffectCastSpellPoint::ApplyEffect()-CMessageHandler::AddMessage()"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			test dword ptr ds:[rdi+#OFFSET_OF(CGameEffect.m_special)], 1                    ; (this->m_special & 1) != 0 ?
			jz #L(return)                                                                   ;     no  -> keep ForceSpellPoint()
			mov word ptr ds:[rdx+#OFFSET_OF(CMessageInsertAction.m_action.m_actionID)], 192 ;     yes -> swap to SpellPointNoDec()
		]]}
	)

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
	|           -> false - Effect not handled                                                          |
	|           -> true  - Effect handled (skip normal code)                                           |
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
	+------------------------------------------------------------------------------------+
	| Opcode #219                                                                        |
	+------------------------------------------------------------------------------------+
	|   param3 != 0 -> Override the engine's hardcoded protection bonus of 2 with param3 |
	+------------------------------------------------------------------------------------+
	|   [JIT]                                                                            |
	+------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameEffectProtectionCircle::ApplyEffect()-AddTail"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			; rbx -> CGameEffect*
			; rdi -> CSelectiveBonus*

			mov eax, dword ptr ds:[rbx+#OFFSET_OF(CGameEffect.m_effectAmount2)]
			test eax, eax
			jz #L(return)

			mov dword ptr ds:[rdi+#OFFSET_OF(CSelectiveBonus.m_bonus)], eax
		]]}
	)

	--[[
	+------------------------------------------------------------------------------------------------------------------------------------------+
	| Opcode #248                                                                                                                              |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	|   (special & 1) != 0 -> .EFF bypasses op120                                                                                              |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnOp248AddTail(pOp248: CGameEffect*, pExtraEffect: CGameEffect*)                                          |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	|   [Lua] [EEex_Mix_Patch.lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp248(sprite: CGameSprite, targetSprite: CGameSprite, blocked: boolean) |
	+------------------------------------------------------------------------------------------------------------------------------------------+
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

	--[[
	+------------------------------------------------------------------------------------------------------------------------------------------+
	| Opcode #249                                                                                                                              |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	|   (special & 1) != 0 -> .EFF bypasses op120                                                                                              |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnOp249AddTail(pOp249: CGameEffect*, pExtraEffect: CGameEffect*)                                          |
	+------------------------------------------------------------------------------------------------------------------------------------------+
	|   [Lua] [EEex_Mix_Patch.lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp249(sprite: CGameSprite, targetSprite: CGameSprite, blocked: boolean) |
	+------------------------------------------------------------------------------------------------------------------------------------------+
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
	|           -> false - Don't alter engine behavior                                                     |
	|           -> true  - Suppress wild surge feedback string and visuals                                 |
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
	| Opcode #319 - Add SPLPROT modes                                                                          |
	+----------------------------------------------------------------------------------------------------------+
	|   power == 2 -> Not usable by (SPLPROT)                                                                  |
	|   power == 3 -> Usable by (SPLPROT)                                                                      |
	|       param1 -> SPLPROT Value                                                                            |
	|       param2 -> SPLPROT Row                                                                              |
	+----------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] CGameEffectUsability::Override_CheckUsability(pSprite: CGameSprite*) -> int                 |
	|       return:                                                                                            |
	|           ->  0 - Block the sprite from using the item                                                   |
	|           -> !0 - Allow the sprite to use the item                                                       |
	+----------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op319_IsInverted(pEffect: CGameEffect*) -> bool                           |
	|       return:                                                                                            |
	|           -> false - op319 is in a "Usable by" mode                                                      |
	|           -> true  - op319 is in a "Not usable by" mode                                                  |
	+----------------------------------------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-CGameEffectUsability::CheckUsability()-FirstInstruction"), {[[
		jmp #L(CGameEffectUsability::Override_CheckUsability)
	]]})

	EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CItem::GetUsabilityText()-IsOp319InvertedJmp"), 4, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
														; rcx is already pEffect
			call #L(EEex::Opcode_Hook_Op319_IsInverted)
			test al, al
		]]}
	)

	--[[
	+----------------------------------------------------------------------------------------------------------+
	| Opcode #326                                                                                              |
	+----------------------------------------------------------------------------------------------------------+
	|   (special & 1) != 0 -> Flip what SPLPROT.2DA considers the "source" and "target" sprites                |
	+----------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ApplySpell_ShouldFlipSplprotSourceAndTarget(pEffect: CGameEffect*) -> int |
	|       return:                                                                                            |
	|           ->  0 - Don't alter engine behavior                                                            |
	|           -> !0 - Flip what SPLPROT.2DA considers the "source" and "target" sprites                      |
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
	+------------------------------------------------------------------------------------------------------+
	| Opcode #342                                                                                          |
	+------------------------------------------------------------------------------------------------------+
	|   param2 == 5  -> Override `combat_round_<param1>` in animation INI to `resource`:                   |
	|       param1   -> Combat round slot                                                                  |
	|       resource -> Resref of RNDBASE*-like .BMP                                                       |
	+------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op342_OnUnhandledParam2(pEffect: CGameEffect*, pSprite: CGameSprite*) |
	|                                                                                                      |
	|   [EEex.dll] EEex::Sprite_Hook_OnGetAttackFrameType(pSprite: CGameSprite*, numAttacks: byte) -> byte |
	|       return: Palette index of fetched pixel in RNDBASE*-like .BMP                                   |
	+------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameEffectOverrideAnimation::ApplyEffect()-LastParam2Jmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8,  EEex_HookIntegrityWatchdogRegister.R9,  EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			mov rcx, rsi                                       ; pEffect
			mov rdx, rdi                                       ; pSprite
			call #L(EEex::Opcode_Hook_Op342_OnUnhandledParam2)
		]]}
	)

	local patchGetAttackFrameType = function(label, spriteRegister)
		EEex_HookNOPsWithLabels(EEex_Label(label), 1, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
				EEex_HookIntegrityWatchdogRegister.R8,  EEex_HookIntegrityWatchdogRegister.R9,  EEex_HookIntegrityWatchdogRegister.R10,
				EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				mov rcx, #$(1) ]], {spriteRegister}, [[ #ENDL   ; pSprite
																; dl already numAttacks
				call #L(EEex::Sprite_Hook_OnGetAttackFrameType)
			]]}
		)
	end

	patchGetAttackFrameType("Hook-CGameSprite::OneSwing()-GetAttackFrameType()", "rdi")
	patchGetAttackFrameType("Hook-CGameSprite::Swing()-GetAttackFrameType()", "rbx")

	--[[
	+--------------------------------------------------------------------------------------------------------------------------+
	| Opcode #346 - Support every school an unsigned byte can hold (0-255), not only the 12 the engine can store               |
	+--------------------------------------------------------------------------------------------------------------------------+
	|   Vanilla CGameEffectSaveVsSchoolMod::ApplyEffect() rejects special >= 12 (the length of                                 |
	|   CDerivedStatsTemplate.m_nSchoolSaveBonus), and CGameEffect::CheckSave() only reads the bonus for m_school < 12.        |
	|   Schools 12-255 (MSCHOOL.2DA rows) are stored by EEex.dll next to every CDerivedStats instance, with the very same      |
	|   lifecycle as m_nSchoolSaveBonus: Reload() / BonusInit() zero it, operator=() copies it, operator+=() sums it.          |
	|                                                                                                                          |
	|   param1  -> Save bonus (only its low 16 bits are used, and sums wrap around at 16 bits, exactly like vanilla)           |
	|   param2  -> 0 = Cumulative (summed in m_bonusStats), 1 = Flat (set in m_derivedStats), anything else does nothing       |
	|   special -> School (MSCHOOL.2DA row), 0-255. Higher values keep the vanilla out-of-range behavior: nothing is applied,  |
	|              and the rest of the effect list is not processed this pass.                                                 |
	|                                                                                                                          |
	|   op177 / op182 / op183 / op283 call the ApplyEffect() of their decoded .EFF child directly (through its vtable), so     |
	|   replacing the function itself covers them as well. New Opcode #420 (SaveVsSecondaryTypeMod), defined below, shares     |
	|   the CheckSave() and BonusInit() hooks of this section, and is only defined when they are installed.                    |
	+--------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_SaveVsSchoolMod_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int          |
	|       return:                                                                                                            |
	|           ->  0 - Halt effect list processing                                                                            |
	|           -> !0 - Continue effect list processing                                                                        |
	+--------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_CheckSave_GetExtendedSaveBonus(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int       |
	|       return -> Save bonus vs. m_school 12-255 (op346) + save bonus vs. m_secondaryType 0-255 (op420)                    |
	+--------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Stats_Hook_OnBonusInit(pStats: CDerivedStats*)                                                        |
	+--------------------------------------------------------------------------------------------------------------------------+
	| Why these hooks (every engine fact below is verified for BG2:EE, BG:EE, and IWD:EE):                                     |
	|   * ApplyEffect(): EEex_JITAt() writes a `jmp` over its first instruction. The function is only reached through its      |
	|     vtable, nothing branches into its body, and it is fully reimplemented in C++ with the exact same Win64 ABI. All of   |
	|     its vanilla code is validated below, so the C++ reimplementation is known to match the engine it replaces.           |
	|   * CheckSave(): EEex_HookBeforeRestoreWithLabels() on the merge point right after the vanilla school bonus block (both  |
	|     the `m_school >= 12` jump and the in-range path land there). rbx = effect, rsi = target sprite, edi = running save   |
	|     total. rax / rcx / r10 / r11 / flags are dead there; rdx / r8 / r9 are preserved regardless.                         |
	|   * BonusInit(): EEex_HookBeforeRestoreWithLabels() on its first instruction (rcx = this). ProcessEffectList() resets    |
	|     m_bonusStats with it, which none of the existing EEex stats hooks (EEex_Stats_Patch.lua) observe. It is installed    |
	|     here, and not in EEex_Stats_Patch.lua, so the op346 / op420 hooks are always installed all together or not at all.   |
	+--------------------------------------------------------------------------------------------------------------------------+
	--]]

	-- New Opcode #420 is only defined when this is true
	local saveBonusHooksInstalled = EEex_Utility_NewScope(function()

		-- These labels are only shipped in v2.7.3.0's pattern database (pattern_dbs/v2.7.3.0.db).
		-- On other engine versions all of them are absent: vanilla op346 behavior is kept, and op420 is not defined.
		local applyEffectAddress = EEex_TryLabel("Hook-CGameEffectSaveVsSchoolMod::ApplyEffect()-FirstInstruction")
		local checkSaveAddress = EEex_TryLabel("Hook-CGameEffect::CheckSave()-AfterSchoolSaveBonus")
		local bonusInitAddress = EEex_TryLabel("Hook-CDerivedStats::BonusInit()-FirstInstruction")

		if applyEffectAddress == nil and checkSaveAddress == nil and bonusInitAddress == nil then
			return false -- Engine version without these labels: keep vanilla op346 behavior
		end

		if applyEffectAddress == nil or checkSaveAddress == nil or bonusInitAddress == nil then
			-- Installing only some hooks would store save bonuses that are never read / never reset
			EEex_Error("op346 / op420: incomplete pattern database, expected the ApplyEffect(), CheckSave(), and BonusInit() labels")
		end

		----------------------------------------------------------------------------------------------------------
		-- The short pattern signatures only locate the three sites. Validate every instruction the hooks (and  --
		-- the C++ reimplementation of op346) rely on before writing anything, so a mismatch never leaves a     --
		-- half-applied change behind.                                                                          --
		----------------------------------------------------------------------------------------------------------

		-- `address` must hold `bytes` (`false` matches any byte), optionally followed by an unsigned 32-bit value `u32`
		local expectInstruction = function(address, bytes, u32, description)
			for i = 1, #bytes do
				local byte = bytes[i]
				if byte ~= false and EEex_ReadU8(address + i - 1) ~= byte then
					EEex_Error(string.format("op346 / op420: expected `%s` at %s", description, EEex_ToHex(address)))
				end
			end
			if u32 ~= nil and EEex_ReadU32(address + #bytes) ~= u32 then
				EEex_Error(string.format("op346 / op420: unexpected 32-bit operand in `%s` at %s", description, EEex_ToHex(address)))
			end
		end

		-- The rel8 branch (2 bytes, e.g. `jcc rel8`) at `address` must land on `target`. rel8 is relative to its end.
		local expectBranchTarget = function(address, target, description)
			if address + 2 + EEex_Read8(address + 1) ~= target then
				EEex_Error(string.format("op346 / op420: `%s` at %s does not branch to %s", description, EEex_ToHex(address), EEex_ToHex(target)))
			end
		end

		-- Number of schools the engine can store itself: the int16 element count of CDerivedStatsTemplate.m_nSchoolSaveBonus
		-- (12 in v2.7.3.0). EEex.dll derives the very same constant (VANILLA_SCHOOL_SAVE_BONUS_COUNT) from its headers.
		local vanillaSchoolCount = _G[CDerivedStatsTemplate["usertype_m_nSchoolSaveBonus"]].sizeof / 2

		local effectSpecialOffset = EEex_OffsetOf("CGameEffect.m_special")
		local effectParam1Offset = EEex_OffsetOf("CGameEffect.m_effectAmount")
		local effectParam2Offset = EEex_OffsetOf("CGameEffect.m_dWFlags")
		local effectSchoolOffset = EEex_OffsetOf("CGameEffect.m_school")
		local effectSaveModOffset = EEex_OffsetOf("CGameEffect.m_saveMod")
		local effectSourceIdOffset = EEex_OffsetOf("CGameEffect.m_sourceId")
		local schoolSaveBonusOffset = EEex_OffsetOf("CDerivedStats.m_nSchoolSaveBonus")
		local spriteDerivedStatsOffset = EEex_OffsetOf("CGameSprite.m_derivedStats")
		local spriteTempStatsOffset = EEex_OffsetOf("CGameSprite.m_tempStats")
		local spriteBonusStatsOffset = EEex_OffsetOf("CGameSprite.m_bonusStats")
		local spriteAllowEffectListCallOffset = EEex_OffsetOf("CGameSprite.m_bAllowEffectListCall")

		-- 1) CGameEffectSaveVsSchoolMod::ApplyEffect(this = rcx, pSprite = rdx), all 67 bytes (A = applyEffectAddress).
		--    This is exactly what EEex::Opcode_Hook_SaveVsSchoolMod_ApplyEffect() reimplements for special < 12.
		--     A+0   mov r9d, dword ptr [rcx+m_special]
		--     A+4   mov r8, rcx
		--     A+7   cmp r9d, <vanilla school count>
		--     A+11  jb A+16
		--     A+13  xor eax, eax / ret                                ; special out of range: return 0
		--     A+16  mov ecx, dword ptr [rcx+m_dWFlags]                ; param2
		--     A+19  test ecx, ecx / je A+45                           ; param2 == 0 -> cumulative
		--     A+23  cmp ecx, 1 / jne A+61                             ; param2 != 1 -> return 1
		--     A+28  movzx eax, word ptr [r8+m_effectAmount]           ; param1 (low 16 bits)
		--     A+33  mov word ptr [rdx+2*r9+m_derivedStats.m_nSchoolSaveBonus], ax
		--     A+42  mov eax, ecx / ret                                ; return 1
		--     A+45  movzx eax, word ptr [r8+m_effectAmount]
		--     A+50  lea rcx, [rdx+2*r9]
		--     A+54  add word ptr [rcx+m_bonusStats.m_nSchoolSaveBonus], ax
		--     A+61  mov eax, 1 / ret
		local A = applyEffectAddress
		expectInstruction(A + 0, {0x44, 0x8B, 0x49, effectSpecialOffset}, nil, "mov r9d, dword ptr [rcx+m_special]")
		expectInstruction(A + 4, {0x4C, 0x8B, 0xC1}, nil, "mov r8, rcx")
		expectInstruction(A + 7, {0x41, 0x83, 0xF9, vanillaSchoolCount}, nil, "cmp r9d, <vanilla school count>")
		expectInstruction(A + 11, {0x72}, nil, "jb rel8")
		expectBranchTarget(A + 11, A + 16, "jb rel8")
		expectInstruction(A + 13, {0x33, 0xC0, 0xC3}, nil, "xor eax, eax / ret")
		expectInstruction(A + 16, {0x8B, 0x49, effectParam2Offset}, nil, "mov ecx, dword ptr [rcx+m_dWFlags]")
		expectInstruction(A + 19, {0x85, 0xC9, 0x74}, nil, "test ecx, ecx / je rel8")
		expectBranchTarget(A + 21, A + 45, "je rel8")
		expectInstruction(A + 23, {0x83, 0xF9, 0x01, 0x75}, nil, "cmp ecx, 1 / jne rel8")
		expectBranchTarget(A + 26, A + 61, "jne rel8")
		expectInstruction(A + 28, {0x41, 0x0F, 0xB7, 0x40, effectParam1Offset}, nil, "movzx eax, word ptr [r8+m_effectAmount]")
		expectInstruction(A + 33, {0x66, 0x42, 0x89, 0x84, 0x4A}, spriteDerivedStatsOffset + schoolSaveBonusOffset,
			"mov word ptr [rdx+2*r9+m_derivedStats.m_nSchoolSaveBonus], ax")
		expectInstruction(A + 42, {0x8B, 0xC1, 0xC3}, nil, "mov eax, ecx / ret")
		expectInstruction(A + 45, {0x41, 0x0F, 0xB7, 0x40, effectParam1Offset}, nil, "movzx eax, word ptr [r8+m_effectAmount]")
		expectInstruction(A + 50, {0x4A, 0x8D, 0x0C, 0x4A}, nil, "lea rcx, [rdx+2*r9]")
		expectInstruction(A + 54, {0x66, 0x01, 0x81}, spriteBonusStatsOffset + schoolSaveBonusOffset,
			"add word ptr [rcx+m_bonusStats.m_nSchoolSaveBonus], ax")
		expectInstruction(A + 61, {0xB8, 0x01, 0x00, 0x00, 0x00, 0xC3}, nil, "mov eax, 1 / ret")

		-- 2) CGameEffect::CheckSave(), the save bonus block around the hooked merge point (C = checkSaveAddress).
		--    rbx = this (the effect being saved against), rsi = the target sprite, edi = the running save total.
		--     C-87  add edi, dword ptr [rbx+m_saveMod]
		--     C-84  mov ecx, dword ptr [rbx+m_school]
		--     C-81  test ecx, ecx / je C-38                           ; school 0: no specialist bonus
		--           ...                                               ; mage specialist check (school in ecx again):
		--     C-51  mov ecx, dword ptr [rbx+m_school]
		--     C-48  movzx eax, al
		--     C-45  cmp eax, ecx / jne C-38
		--     C-41  add edi, 2                                        ; specialist vs. own school
		--     C-38  cmp ecx, <vanilla school count>
		--     C-35  jae C                                             ; school out of the engine's range: skip
		--     C-33  cmp dword ptr [rsi+m_bAllowEffectListCall], 0
		--     C-26  mov eax, m_derivedStats
		--     C-21  mov edx, m_tempStats
		--     C-16  cmove eax, edx                                    ; GetActiveStats()
		--     C-13  add rax, rsi
		--     C-10  movsx ecx, word ptr [rax+2*rcx+m_nSchoolSaveBonus]
		--     C-2   add edi, ecx
		--     C     mov ecx, dword ptr [rbx+m_sourceId]               ; hooked (6 bytes, restored after the hook)
		--     C+6   cmp ecx, -1                                       ; flags are overwritten right after the hook
		local C = checkSaveAddress
		expectInstruction(C - 87, {0x03, 0x7B, effectSaveModOffset}, nil, "add edi, dword ptr [rbx+m_saveMod]")
		expectInstruction(C - 84, {0x8B, 0x4B, effectSchoolOffset}, nil, "mov ecx, dword ptr [rbx+m_school]")
		expectInstruction(C - 81, {0x85, 0xC9, 0x74}, nil, "test ecx, ecx / je rel8")
		expectBranchTarget(C - 79, C - 38, "je rel8")
		expectInstruction(C - 51, {0x8B, 0x4B, effectSchoolOffset}, nil, "mov ecx, dword ptr [rbx+m_school]")
		expectInstruction(C - 48, {0x0F, 0xB6, 0xC0}, nil, "movzx eax, al")
		expectInstruction(C - 45, {0x3B, 0xC1, 0x75}, nil, "cmp eax, ecx / jne rel8")
		expectBranchTarget(C - 43, C - 38, "jne rel8")
		expectInstruction(C - 41, {0x83, 0xC7, 0x02}, nil, "add edi, 2")
		expectInstruction(C - 38, {0x83, 0xF9, vanillaSchoolCount}, nil, "cmp ecx, <vanilla school count>")
		expectInstruction(C - 35, {0x73}, nil, "jae rel8")
		expectBranchTarget(C - 35, C, "jae rel8")
		expectInstruction(C - 33, {0x83, 0xBE}, spriteAllowEffectListCallOffset, "cmp dword ptr [rsi+m_bAllowEffectListCall], 0")
		expectInstruction(C - 27, {0x00}, nil, "cmp dword ptr [rsi+m_bAllowEffectListCall], 0")
		expectInstruction(C - 26, {0xB8}, spriteDerivedStatsOffset, "mov eax, m_derivedStats")
		expectInstruction(C - 21, {0xBA}, spriteTempStatsOffset, "mov edx, m_tempStats")
		expectInstruction(C - 16, {0x0F, 0x44, 0xC2}, nil, "cmove eax, edx")
		expectInstruction(C - 13, {0x48, 0x03, 0xC6}, nil, "add rax, rsi")
		expectInstruction(C - 10, {0x0F, 0xBF, 0x8C, 0x48}, schoolSaveBonusOffset, "movsx ecx, word ptr [rax+2*rcx+m_nSchoolSaveBonus]")
		expectInstruction(C - 2, {0x03, 0xF9}, nil, "add edi, ecx")
		expectInstruction(C, {0x8B, 0x8B}, effectSourceIdOffset, "mov ecx, dword ptr [rbx+m_sourceId]")
		expectInstruction(C + 6, {0x83, 0xF9, 0xFF}, nil, "cmp ecx, -1")

		-- 3) CDerivedStats::BonusInit(this = rcx), first instructions (B = bonusInitAddress). The hook restores the first one.
		--     B+0   mov qword ptr [rsp+0x10], rbx
		--     B+5   push rdi
		--     B+6   sub rsp, 0x40
		local B = bonusInitAddress
		expectInstruction(B + 0, {0x48, 0x89, 0x5C, 0x24, 0x10}, nil, "mov qword ptr [rsp+0x10], rbx")
		expectInstruction(B + 5, {0x57}, nil, "push rdi")
		expectInstruction(B + 6, {0x48, 0x83, 0xEC, 0x40}, nil, "sub rsp, 0x40")

		-- Resolve the native side up front (errors if the matching EEex.dll does not export it)
		EEex_Label("EEex::Opcode_Hook_SaveVsSchoolMod_ApplyEffect")
		EEex_Label("EEex::Opcode_Hook_CheckSave_GetExtendedSaveBonus")
		EEex_Label("EEex::Stats_Hook_OnBonusInit")
		EEex_Label("EEex::Opcode_Hook_SaveVsSecondaryTypeMod_ApplyEffect") -- New Opcode #420, decoded further below

		-----------------------------------------------
		-- [EEex.dll] EEex::Stats_Hook_OnBonusInit() --
		-----------------------------------------------

		-- Zero the EEex-side save bonuses whenever the engine zeroes m_nSchoolSaveBonus via BonusInit(). Runs before the
		-- function's first instruction, so rcx (this) is saved / restored around the call; the other volatile registers
		-- carry no arguments into BonusInit().
		EEex_HookBeforeRestoreWithLabels(B, 0, 5, 5, {
			{"stack_mod", 8},
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
				EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				#MAKE_SHADOW_SPACE(8)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

				                                      ; rcx already pStats
				call #L(EEex::Stats_Hook_OnBonusInit)

				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]}
		)

		-------------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_CheckSave_GetExtendedSaveBonus() --
		-------------------------------------------------------------------

		-- Add the op346 (schools 12-255) and op420 save bonuses to the running save total. rdi is written on purpose.
		EEex_HookBeforeRestoreWithLabels(C, 0, 6, 6, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDI,
				EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				#MAKE_SHADOW_SPACE(24)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r9

				mov rdx, rsi                                              ; pSprite
				mov rcx, rbx                                              ; pEffect
				call #L(EEex::Opcode_Hook_CheckSave_GetExtendedSaveBonus)
				add edi, eax                                              ; Running save total += extended save bonus

				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]}
		)

		----------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_SaveVsSchoolMod_ApplyEffect() --
		----------------------------------------------------------------

		-- Replace CGameEffectSaveVsSchoolMod::ApplyEffect() entirely (same arguments, same stack, same return register)
		EEex_JITAt(A, {[[
			jmp #L(EEex::Opcode_Hook_SaveVsSchoolMod_ApplyEffect)
		]]})

		return true
	end)

	--[[
	+------------------------------------------------------------------------------------------------+
	| Allow saving throw BIT23 to bypass opcode #101                                                 |
	+------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op101_ShouldEffectBypassImmunity(pEffect: CGameEffect*) -> bool |
	|       return:                                                                                  |
	|           -> false - Don't alter engine behavior                                               |
	|           -> true  - Bypass opcode #101                                                        |
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
	|           ->  0 - Halt effect list processing                                                                        |
	|           -> !0 - Continue effect list processing                                                                    |
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
	|                  -> 0 (Sum)     - stat = stat + param1                                                          |
	|                  -> 1 (Set)     - stat = param1                                                                 |
	|                  -> 2 (Percent) - stat = stat * param1 / 100                                                    |
	|                                                                                                                 |
	|   special -> Extended stat id                                                                                   |
	+-----------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_SetExtendedStat_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int |
	|       return:                                                                                                   |
	|           ->  0 - Halt effect list processing                                                                   |
	|           -> !0 - Continue effect list processing                                                               |
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
	|           ->  0 - Halt effect list processing                                                                 |
	|           -> !0 - Continue effect list processing                                                             |
	+---------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ScreenEffects_OnRemove(pEffect: CGameEffect*, pSprite: CGameSprite*)           |
	+---------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnCheckAdd(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int                |
	|       return:                                                                                                 |
	|           ->  0 - Don't alter engine behavior                                                                 |
	|           -> !0 - Block effect                                                                                |
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

		["OnRemove"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_ScreenEffects_OnRemove)
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
	|           ->  0 - Halt effect list processing                                                                     |
	|           -> !0 - Continue effect list processing                                                                 |
	+-------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ProjectileMutator_OnRemove(pEffect: CGameEffect*, pSprite: CGameSprite*)           |
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

		["OnRemove"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_ProjectileMutator_OnRemove)
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
	|       ->  0 - Action listener disabled                                                                               |
	|       -> !0 - Action listener enabled                                                                                |
	|                                                                                                                      |
	|   resource -> The name of the function as registered by EEex_Action_AddEnabledSpriteStartedActionListener()          |
	+----------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_EnableActionListener_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int |
	|       return:                                                                                                        |
	|           ->  0 - Halt effect list processing                                                                        |
	|           -> !0 - Continue effect list processing                                                                    |
	+----------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_EnableActionListener_OnRemove(pEffect: CGameEffect*, pSprite: CGameSprite*)           |
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

		["OnRemove"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_EnableActionListener_OnRemove)
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	})

	--[[
	+-------------------------------------------------------------------------------------------------------------------------+
	| New Opcode #420 (SaveVsSecondaryTypeMod)                                                                                |
	+-------------------------------------------------------------------------------------------------------------------------+
	|   Opcode #346 for secondary types (MSECTYPE.2DA rows) instead of schools: modifies the target's saving throws against   |
	|   effects whose secondary type is `special`. The bonus is added to the save roll by CGameEffect::CheckSave(), next to   |
	|   the op346 school bonus, through the hooks of the "Opcode #346" section above. This opcode is only defined when        |
	|   those hooks are installed (v2.7.3.0).                                                                                 |
	|                                                                                                                         |
	|   Like op346, it also works through op177 / op182 / op183 / op283: their .EFF child is decoded by                       |
	|   CGameEffect::DecodeEffect() (the switch below) and its ApplyEffect() only stores a value, never the effect itself.    |
	+-------------------------------------------------------------------------------------------------------------------------+
	|   param1  -> Save bonus (only its low 16 bits are used, and sums wrap around at 16 bits, exactly like op346)            |
	|   param2  -> 0 = Cumulative (summed in m_bonusStats), 1 = Flat (set in m_derivedStats), anything else does nothing      |
	|   special -> Secondary type (MSECTYPE.2DA row), 0-255. Higher values behave like an out-of-range op346: nothing is      |
	|              applied, and the rest of the effect list is not processed this pass.                                       |
	+-------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_SaveVsSecondaryTypeMod_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int  |
	|       return:                                                                                                           |
	|           ->  0 - Halt effect list processing                                                                           |
	|           -> !0 - Continue effect list processing                                                                       |
	+-------------------------------------------------------------------------------------------------------------------------+
	--]]

	local EEex_SaveVsSecondaryTypeMod = saveBonusHooksInstalled and genOpcodeDecode({
		["ApplyEffect"] = {[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE
			call #L(EEex::Opcode_Hook_SaveVsSecondaryTypeMod_ApplyEffect)
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}) or nil

	-- Decode switch case for op420, or a plain fallthrough to the engine's default case when op420 is not defined
	local op420DecodeCase = EEex_SaveVsSecondaryTypeMod ~= nil
		and EEex_FlattenTable({
			{[[
				cmp eax, 420
				jne #L(jmp_success)
			]]},
			EEex_SaveVsSecondaryTypeMod,
		})
		or {[[
			jmp #L(jmp_success)
		]]}

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
			jne _420
			]], EEex_EnableActionListener, [[

			_420:
			]], op420DecodeCase, [[
		]]})
	)
	EEex_HookIntegrityWatchdog_IgnoreStackSizes(EEex_Label("Hook-CGameEffect::DecodeEffect()-DefaultJmp"), {{0x60, 8}})

	EEex_EnableCodeProtection()

end)()
