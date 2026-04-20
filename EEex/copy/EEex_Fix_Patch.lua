
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
	+------------------------------------------------------------------------------------------------------------------+
	| BUG: v2.6.6.0 - opcode 180 (CGameEffectRestrictEquipItem) is enforced by equip validation, but inventory UI      |
	| paths only query CImmunitiesItemTypeEquipList::OnList(), so item-specific restrictions never get the usual red   |
	| tint / usability denial in inventory.                                                                            |
	+------------------------------------------------------------------------------------------------------------------+
	| Fix the UI-side checks in CInfGame::CheckItemUsable(short, ...) and CInfGame::GetItemTint(CItem*) so they        |
	| consult CImmunitiesItemEquipList::OnList() first, then fall back to the engine's original item-type check.       |
	|                                                                                                                  |
	| This is intentionally limited to the UI helper paths. The actual equip validation code already checks both       |
	| opcode 180's item-resref list and opcode 181's item-type list; the missing red overlay was caused by the UI      |
	| only consulting the latter.                                                                                      |
	+------------------------------------------------------------------------------------------------------------------+
	--]]

	local hookRestrictEquipItemUI = function(address, spriteRegister, itemRegister)
		-- `address` is the original call to CImmunitiesItemTypeEquipList::OnList().
		-- Replace that call with a small shim that:
		--   1) checks CImmunitiesItemEquipList::OnList() using the item's resref
		--   2) if no opcode 180 match is found, replays the engine's original item-type call
		--
		-- The caller-specific registers differ between the two UI helpers, so the
		-- sprite/item registers are supplied by the two call sites below.
		--
		-- Original helper signatures:
		--   CImmunitiesItemEquipList::OnList(
		--       rcx = CImmunitiesItemEquipList*,
		--       rdx = CResRef*,
		--       r8  = unsigned long* outRef,
		--       r9  = CGameEffect** outEffect
		--   )
		--
		--   CImmunitiesItemTypeEquipList::OnList(
		--       rcx = CImmunitiesItemTypeEquipList*,
		--       edx = unsigned long itemType,
		--       r8  = unsigned long* outRef,
		--       r9  = CGameEffect** outEffect
		--   )
		--
		-- This means only rcx/rdx differ between the opcode 180 and opcode 181 checks.
		-- r8/r9 must be preserved so the surrounding engine code sees the exact same
		-- out-parameter locations no matter which helper returns first.
		--
		-- Use EEex_HookRemoveCall() specifically because this patch is replacing a
		-- single direct `call CImmunitiesItemTypeEquipList::OnList` instruction.
		-- That gives us two things we want:
		--   1) the original call is suppressed unless we explicitly replay it
		--   2) `#L(original)` still remains available, so we can fall back to the
		--      engine's original opcode 181 behavior after our opcode 180 check misses
		--
		-- Other common hook styles are a worse fit here:
		--   - EEex_HookAfterCall(): too late, because the type-only check would already
		--     have run before we could inject the item-resref check
		--   - EEex_HookBeforeCall(): can run before the original call, but it is built
		--     around preserving the original call rather than replacing it conditionally
		--   - EEex_HookBeforeRestore()/EEex_HookAfterRestore(): workable in principle,
		--     but unnecessarily low-level here because the target is already a clean
		--     disp32 call site and HookRemoveCall gives us the original target for free
		EEex_HookRemoveCall(address, EEex_FlattenTable({
			{[[
				; Allocate 0x40 bytes so we have:
				;   - 0x20 bytes of Windows x64 shadow space for our nested calls
				;   - 0x20 bytes of scratch space to save the original rcx/rdx/r8/r9
				sub rsp, 40h

				; Preserve the original call arguments. If the item-resref check misses,
				; we must invoke the engine's original item-type helper with the same
				; rcx/rdx/r8/r9 argument bundle it was about to receive.
				mov qword ptr ss:[rsp+20h], rcx
				mov qword ptr ss:[rsp+28h], rdx
				mov qword ptr ss:[rsp+30h], r8
				mov qword ptr ss:[rsp+38h], r9

				; Mirror the engine's equip-list base selection from the equip-validation
				; paths that already support opcode 180:
				;   0x1588 -> m_derivedStats.m_cImmunitiesItemEquip
				;   0x2230 -> m_tempStats.m_cImmunitiesItemEquip (alternate copy used by the same UI path)
				;
				; The engine uses `ebx` here as the same derived/base-state selector that
				; the nearby item-type check already uses.
				mov eax, 2230h
				mov ecx, 1588h
				test ebx, ebx
				cmove ecx, eax
				add rcx, ]], spriteRegister, [[

				; CImmunitiesItemEquipList::OnList() is keyed by the item's CResRef,
				; which begins at item + 0x10.
				lea rdx, qword ptr ds:[]], itemRegister, [[+10h]

				; Reuse the caller's original out-parameter storage.
				mov r8, qword ptr ss:[rsp+30h]
				mov r9, qword ptr ss:[rsp+38h]
				call #L(CImmunitiesItemEquipList::OnList)

				; A hit means opcode 180 already populated the out-parameters and return
				; value exactly as the surrounding UI code expects. Skip the original
				; item-type helper in that case.
				test eax, eax
				jnz return_from_hook

				; No opcode 180 match: restore the original arguments and fall back to
				; the engine's item-type helper so opcode 181 behavior remains unchanged.
				mov rcx, qword ptr ss:[rsp+20h]
				mov rdx, qword ptr ss:[rsp+28h]
				mov r8, qword ptr ss:[rsp+30h]
				mov r9, qword ptr ss:[rsp+38h]
				call #L(original)

				return_from_hook:
				; Match the stack depth expected by the hook trampoline before jumping
				; back to the instruction after the original removed call.
				add rsp, 40h
				jmp #L(return)
			]]},
		}))
	end

	-- CInfGame::CheckItemUsable(short, CItem*, ...) stores:
	--   rsi -> sprite
	--   rdi -> item
	--
	-- The loader DB label for this hook lands directly on the original
	-- `call CImmunitiesItemTypeEquipList::OnList` inside the short-portrait
	-- usability helper.
	hookRestrictEquipItemUI(
		EEex_Label("Hook-CInfGame::CheckItemUsable(short)-CImmunitiesItemTypeEquipList::OnList()"),
		"rsi",
		"rdi"
	)

	-- CInfGame::GetItemTint(CItem*) stores:
	--   r13 -> sprite
	--   rsi -> item
	--
	-- This is the path responsible for the red inventory overlay itself.
	-- The hook shape is the same as CheckItemUsable(short, ...); only the source
	-- registers differ because the surrounding function uses a different register
	-- allocation.
	hookRestrictEquipItemUI(
		EEex_Label("Hook-CInfGame::GetItemTint()-CImmunitiesItemTypeEquipList::OnList()"),
		"r13",
		"rsi"
	)

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
