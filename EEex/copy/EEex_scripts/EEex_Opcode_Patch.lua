
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
	+---------------------------------------------------------------------------------------------------------------------------+
	| Opcode #74 (Blindness) - Every consequence is tied to STATE_BLIND (100% curable), every hardcoded value is softcoded      |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   Vanilla bakes the permanent (timings 1 / 4 / 7) +4 AC / THAC0 penalty into m_baseStats and deletes the effect, while    |
	|   op75 (CureBlindness) only clears STATE_BLIND: the penalty could never be cured. Now ApplyEffect() only sets STATE_BLIND |
	|   (permanent: in m_baseStats too, and the effect is kept so its values persist), and at the end of every effect list      |
	|   pass every consequence (AC, THAC0, portrait icon, visual range, record screen tooltip) follows STATE_BLIND alone.       |
	|                                                                                                                           |
	|   m_effectAmount2 (EFF V2 0x60) -> THAC0 bonus   (positive = better, like op54), 0 = vanilla (+4 THAC0)                   |
	|   m_effectAmount3 (EFF V2 0x64) -> AC bonus      (positive = better, like op0),  0 = vanilla (+4 AC)                      |
	|   m_effectAmount4 (EFF V2 0x68) -> Portrait icon (STATDESC.2DA row),              0 = vanilla (8)                         |
	|   special         (EFF V2 0x48) -> Visual range  (clamped to 255),                0 = vanilla (2)                         |
	|   param1 / param2 keep their vanilla meaning (param2 != 0: random duration from the dice in param1, IWD style).           |
	|   With several op74s in one pass, the first one applied supplies the values. STATE_BLIND without any op74 (e.g. from      |
	|   the .CRE file, or left in m_baseStats by a permanent .EFF child) uses the vanilla values.                               |
	|                                                                                                                           |
	|   op177 / op182 / op183 / op283 call the ApplyEffect() of their decoded .EFF child directly (through its vtable), so the  |
	|   replaced ApplyEffect() covers them as well.                                                                             |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Blindness_ApplyEffect(pEffect: CGameEffect*, pSprite: CGameSprite*) -> int                 |
	|       return -> 1 - Continue effect list processing (like vanilla)                                                        |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Blindness_OnRemove(pEffect: CGameEffect*, pSprite: CGameSprite*)                           |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op74_ApplyBlindnessConsequences(pSprite: CGameSprite*)                                     |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op74_GetBlindVisualRange(pSprite: CGameSprite*) -> int                                     |
	|       return -> The visual range to use while blind                                                                       |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_Op74_AppendStatBreakdown(pSprite: CGameSprite*, pArmorClassText: CString*,                 |
	|                                                         pTHAC0Text: CString*)                                             |
	+---------------------------------------------------------------------------------------------------------------------------+
	| Why these hooks (every engine fact below is verified for BG2:EE, BG:EE, and IWD:EE):                                      |
	|   * CGameEffectBlindness::ApplyEffect() / OnRemove(): EEex_JITAt() writes a 5-byte `jmp` (to a near stub jumping to       |
	|     EEex.dll) over their first instruction. Both are only reached through the vtable (no direct callers, no identical     |
	|     code folding), nothing branches into them, and every one of their vanilla bytes is validated below.                   |
	|   * CGameSprite::ProcessEffectList(): EEex_HookBeforeCallWithLabels() on its only CheckStatsChange() call. Every path     |
	|     from the resolved effect lists (and CheckCutSceneStateOverride()) goes through it, nothing in between touches AC /    |
	|     THAC0, and m_portraitIcons was emptied before the lists were applied (icons are rebuilt on every pass).               |
	|   * CGameSprite::CheckStatsChange(): EEex_HookNOPsWithLabels() replaces the `mov ecx, <vanilla blind visual range>`       |
	|     that only runs when m_derivedStats has STATE_BLIND. rbx = this there.                                                 |
	|   * CGameSprite::GetStatBreakdown(): EEex_ForceJump() makes the timed effect loop skip its per-op74 "+4" tooltip lines,   |
	|     and EEex_HookBeforeRestoreWithLabels() on the loop exit appends the real lines once, to the same two texts.           |
	|   * The vanilla values (STATE_BLIND bit, permanent timing, AC / THAC0 deltas, icon, visual range) and the three engine    |
	|     functions EEex.dll calls are read from the validated instructions and written into EEex.dll: nothing is duplicated.   |
	|   * The per-pass blindness data lives in EEex's per-CDerivedStats data, which EEex_Stats_Patch.lua resets on              |
	|     CDerivedStats::Reload() (start of every pass) and copies on CDerivedStats::operator=(), like the stats themselves.    |
	+---------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_Utility_NewScope(function()

		-- These labels are only shipped in v2.7.3.0's pattern database (pattern_dbs/v2.7.3.0.db).
		-- On other engine versions all of them are absent, and vanilla op74 behavior is kept.
		local siteLabels = {
			["applyEffect"] = "Hook-CGameEffectBlindness::ApplyEffect()-FirstInstruction",
			["onRemove"] = "Hook-CGameEffectBlindness::OnRemove()-FirstInstruction",
			["checkStatsChangeCall"] = "Hook-CGameSprite::ProcessEffectList()-CheckStatsChange()",
			["visualRange"] = "Hook-CGameSprite::CheckStatsChange()-BlindVisualRange",
			["breakdownJne"] = "Hook-CGameSprite::GetStatBreakdown()-BlindnessEffectJne",
			["breakdownExit"] = "Hook-CGameSprite::GetStatBreakdown()-AfterTimedEffectLoop",
		}

		local site = {}
		local labelCount = 0
		local foundCount = 0
		for key, label in pairs(siteLabels) do
			labelCount = labelCount + 1
			site[key] = EEex_TryLabel(label)
			if site[key] ~= nil then
				foundCount = foundCount + 1
			end
		end

		if foundCount == 0 then
			return -- Engine version without these labels: keep vanilla op74 behavior
		end

		if foundCount ~= labelCount then
			-- Some hooks without the others would e.g. drop the penalties without ever applying them again
			EEex_Error("Opcode #74: incomplete pattern database, expected all six op74 hook labels")
		end

		----------------------------------------------------------------------------------------------------------
		-- The short pattern signatures only locate the six sites. Validate every instruction the hooks (and    --
		-- the C++ replacements of ApplyEffect() / OnRemove()) rely on before writing anything, so a mismatch   --
		-- never leaves a half-applied change behind.                                                           --
		----------------------------------------------------------------------------------------------------------

		-- `address` must hold `bytes` (`false` matches any byte), optionally followed by an unsigned 32-bit value `u32`
		local expectInstruction = function(address, bytes, u32, description)
			for i = 1, #bytes do
				local byte = bytes[i]
				if byte ~= false and EEex_ReadU8(address + i - 1) ~= byte then
					EEex_Error(string.format("Opcode #74: expected `%s` at %s", description, EEex_ToHex(address)))
				end
			end
			if u32 ~= nil and EEex_ReadU32(address + #bytes) ~= u32 then
				EEex_Error(string.format("Opcode #74: unexpected 32-bit operand in `%s` at %s", description, EEex_ToHex(address)))
			end
		end

		-- Destination of the jcc / jmp / call (rel8 or rel32) encoded at `address`
		local branchTarget = function(address)
			local _, destination = EEex_GetJmpInfo(address)
			return destination
		end

		-- The jcc / jmp / call at `address` must land on `target`
		local expectBranchTarget = function(address, target, description)
			if branchTarget(address) ~= target then
				EEex_Error(string.format("Opcode #74: `%s` at %s does not branch to %s", description, EEex_ToHex(address), EEex_ToHex(target)))
			end
		end

		-- Every value read at `offsets` (relative to `base`) by `readFunc` must be the same; returns it
		local expectSameValue = function(readFunc, base, offsets, description)
			local value = readFunc(base + offsets[1])
			for i = 2, #offsets do
				if readFunc(base + offsets[i]) ~= value then
					EEex_Error(string.format("Opcode #74: the vanilla code disagrees on %s", description))
				end
			end
			return value
		end

		-- The opcode this feature is about: GetStatBreakdown() compares CGameEffect.m_effectId with it
		local blindnessOpcode = 74

		local effectIdOffset = EEex_OffsetOf("CGameEffect.m_effectId")
		local durationTypeOffset = EEex_OffsetOf("CGameEffect.m_durationType")
		local doneOffset = EEex_OffsetOf("CGameEffect.m_done")
		local baseGeneralStateOffset = EEex_OffsetOf("CGameSprite.m_baseStats.m_generalState")
		local baseArmorClassOffset = EEex_OffsetOf("CGameSprite.m_baseStats.m_armorClass")
		local baseTHAC0Offset = EEex_OffsetOf("CGameSprite.m_baseStats.m_toHitArmorClass0Base")
		local derivedGeneralStateOffset = EEex_OffsetOf("CGameSprite.m_derivedStats.m_generalState")
		local derivedArmorClassOffset = EEex_OffsetOf("CGameSprite.m_derivedStats.m_nArmorClass")
		local derivedTHAC0Offset = EEex_OffsetOf("CGameSprite.m_derivedStats.m_nTHAC0")
		local derivedVisualRangeOffset = EEex_OffsetOf("CGameSprite.m_derivedStats.m_nVisualRange")
		local spriteVisualRangeOffset = EEex_OffsetOf("CGameSprite.m_nVisualRange")

		-- 1) CGameEffectBlindness::ApplyEffect(this = rcx, pSprite = rdx), all 216 bytes (A = site.applyEffect).
		--    Replaced by EEex::Opcode_Hook_Blindness_ApplyEffect(), which keeps the STATE_BLIND writes and drops the rest.
		--     A+0x00  prologue (rbx = pSprite, rdi = this)
		--     A+0x0A  cmp dword ptr [rcx+m_durationType], <permanent>  ; jne A+0x95 (not permanent)
		--     A+0x16  base:    if (!bt <bit>) { bts; base AC / THAC0 += <delta>; AddPortraitIcon(<icon>) }
		--     A+0x48  derived: if (!bt <bit>) { bts; derived THAC0 / AC += <delta>; AddPortraitIcon(<icon>) }
		--     A+0x7B  m_done = 1 / return 1
		--     A+0x95  derived: if (!bt <bit>) { bts; derived THAC0 / AC += <delta>; AddPortraitIcon(<icon>) } / return 1
		local A = site.applyEffect
		expectInstruction(A + 0x00, {0x48, 0x89, 0x5C, 0x24, 0x08}, nil, "mov qword ptr [rsp+8], rbx")
		expectInstruction(A + 0x05, {0x57}, nil, "push rdi")
		expectInstruction(A + 0x06, {0x48, 0x83, 0xEC, 0x20}, nil, "sub rsp, 0x20")
		expectInstruction(A + 0x0A, {0x83, 0x79, durationTypeOffset}, nil, "cmp dword ptr [rcx+m_durationType], imm8")
		expectInstruction(A + 0x0E, {0x48, 0x8B, 0xDA}, nil, "mov rbx, rdx")
		expectInstruction(A + 0x11, {0x48, 0x8B, 0xF9}, nil, "mov rdi, rcx")
		expectInstruction(A + 0x14, {0x75}, nil, "jne rel8")
		expectBranchTarget(A + 0x14, A + 0x95, "jne rel8")
		expectInstruction(A + 0x16, {0x8B, 0x82}, baseGeneralStateOffset, "mov eax, dword ptr [rdx+m_baseStats.m_generalState]")
		expectInstruction(A + 0x1C, {0x0F, 0xBA, 0xE0}, nil, "bt eax, imm8")
		expectInstruction(A + 0x20, {0x72}, nil, "jb rel8")
		expectBranchTarget(A + 0x20, A + 0x48, "jb rel8")
		expectInstruction(A + 0x22, {0x0F, 0xBA, 0xE8}, nil, "bts eax, imm8")
		expectInstruction(A + 0x26, {0x48, 0x8B, 0xCB}, nil, "mov rcx, rbx")
		expectInstruction(A + 0x29, {0x89, 0x82}, baseGeneralStateOffset, "mov dword ptr [rdx+m_baseStats.m_generalState], eax")
		expectInstruction(A + 0x2F, {0x80, 0x82}, baseTHAC0Offset, "add byte ptr [rdx+m_baseStats.m_toHitArmorClass0Base], imm8")
		expectInstruction(A + 0x36, {0x66, 0x83, 0x82}, baseArmorClassOffset, "add word ptr [rdx+m_baseStats.m_armorClass], imm8")
		expectInstruction(A + 0x3E, {0xBA}, nil, "mov edx, imm32")
		expectInstruction(A + 0x43, {0xE8}, nil, "call rel32")
		expectInstruction(A + 0x48, {0x8B, 0x83}, derivedGeneralStateOffset, "mov eax, dword ptr [rbx+m_derivedStats.m_generalState]")
		expectInstruction(A + 0x4E, {0x0F, 0xBA, 0xE0}, nil, "bt eax, imm8")
		expectInstruction(A + 0x52, {0x72}, nil, "jb rel8")
		expectBranchTarget(A + 0x52, A + 0x7B, "jb rel8")
		expectInstruction(A + 0x54, {0x0F, 0xBA, 0xE8}, nil, "bts eax, imm8")
		expectInstruction(A + 0x58, {0xBA}, nil, "mov edx, imm32")
		expectInstruction(A + 0x5D, {0x89, 0x83}, derivedGeneralStateOffset, "mov dword ptr [rbx+m_derivedStats.m_generalState], eax")
		expectInstruction(A + 0x63, {0x48, 0x8B, 0xCB}, nil, "mov rcx, rbx")
		expectInstruction(A + 0x66, {0x66, 0x83, 0x83}, derivedTHAC0Offset, "add word ptr [rbx+m_derivedStats.m_nTHAC0], imm8")
		expectInstruction(A + 0x6E, {0x66, 0x83, 0x83}, derivedArmorClassOffset, "add word ptr [rbx+m_derivedStats.m_nArmorClass], imm8")
		expectInstruction(A + 0x76, {0xE8}, nil, "call rel32")
		expectInstruction(A + 0x7B, {0xC7, 0x87}, doneOffset, "mov dword ptr [rdi+m_done], imm32")
		expectInstruction(A + 0x81, {}, 1, "mov dword ptr [rdi+m_done], 1")
		expectInstruction(A + 0x85, {0xB8, 0x01, 0x00, 0x00, 0x00}, nil, "mov eax, 1")
		expectInstruction(A + 0x8A, {0x48, 0x8B, 0x5C, 0x24, 0x30}, nil, "mov rbx, qword ptr [rsp+0x30]")
		expectInstruction(A + 0x8F, {0x48, 0x83, 0xC4, 0x20}, nil, "add rsp, 0x20")
		expectInstruction(A + 0x93, {0x5F, 0xC3}, nil, "pop rdi / ret")
		expectInstruction(A + 0x95, {0x8B, 0x82}, derivedGeneralStateOffset, "mov eax, dword ptr [rdx+m_derivedStats.m_generalState]")
		expectInstruction(A + 0x9B, {0x0F, 0xBA, 0xE0}, nil, "bt eax, imm8")
		expectInstruction(A + 0x9F, {0x72}, nil, "jb rel8")
		expectBranchTarget(A + 0x9F, A + 0xC8, "jb rel8")
		expectInstruction(A + 0xA1, {0x0F, 0xBA, 0xE8}, nil, "bts eax, imm8")
		expectInstruction(A + 0xA5, {0x48, 0x8B, 0xCB}, nil, "mov rcx, rbx")
		expectInstruction(A + 0xA8, {0x89, 0x82}, derivedGeneralStateOffset, "mov dword ptr [rdx+m_derivedStats.m_generalState], eax")
		expectInstruction(A + 0xAE, {0x66, 0x83, 0x82}, derivedTHAC0Offset, "add word ptr [rdx+m_derivedStats.m_nTHAC0], imm8")
		expectInstruction(A + 0xB6, {0x66, 0x83, 0x82}, derivedArmorClassOffset, "add word ptr [rdx+m_derivedStats.m_nArmorClass], imm8")
		expectInstruction(A + 0xBE, {0xBA}, nil, "mov edx, imm32")
		expectInstruction(A + 0xC3, {0xE8}, nil, "call rel32")
		expectInstruction(A + 0xC8, {0x48, 0x8B, 0x5C, 0x24, 0x30}, nil, "mov rbx, qword ptr [rsp+0x30]")
		expectInstruction(A + 0xCD, {0xB8, 0x01, 0x00, 0x00, 0x00}, nil, "mov eax, 1")
		expectInstruction(A + 0xD2, {0x48, 0x83, 0xC4, 0x20}, nil, "add rsp, 0x20")
		expectInstruction(A + 0xD6, {0x5F, 0xC3}, nil, "pop rdi / ret")

		-- The vanilla values, each used consistently by every path of ApplyEffect()
		local permanentDurationType = EEex_ReadU8(A + 0x0D)                                                    -- cmp's imm8
		local stateBlindBit = expectSameValue(EEex_ReadU8, A, {0x1F, 0x25, 0x51, 0x57, 0x9E, 0xA4}, "the STATE_BLIND bit")
		local stateBlindMask = EEex_LShift(1, stateBlindBit)
		local vanillaTHAC0Delta = expectSameValue(EEex_Read8, A, {0x35, 0x6D, 0xB5}, "the THAC0 penalty")      -- base / derived / derived
		local vanillaArmorClassDelta = expectSameValue(EEex_Read8, A, {0x3D, 0x75, 0xBD}, "the AC penalty")   -- base / derived / derived
		local vanillaPortraitIcon = expectSameValue(EEex_Read32, A, {0x3F, 0x59, 0xBF}, "the portrait icon")
		local addPortraitIcon = expectSameValue(branchTarget, A, {0x43, 0x76, 0xC3}, "CGameSprite::AddPortraitIcon()")

		-- 2) CGameEffectBlindness::OnRemove(this = rcx, pSprite = rdx), all 13 bytes (R = site.onRemove):
		--     mov rcx, rdx / mov edx, <icon> / jmp CGameSprite::RemovePortraitIcon()
		local R = site.onRemove
		expectInstruction(R + 0x0, {0x48, 0x8B, 0xCA}, nil, "mov rcx, rdx")
		expectInstruction(R + 0x3, {0xBA}, vanillaPortraitIcon, "mov edx, <vanilla portrait icon>")
		expectInstruction(R + 0x8, {0xE9}, nil, "jmp rel32")
		local removePortraitIcon = branchTarget(R + 0x8)

		-- 3) CGameSprite::ProcessEffectList(), its only CheckStatsChange() call (C = site.checkStatsChangeCall)
		--     C-3  mov rcx, rsi   ; rsi = this
		--     C    call CGameSprite::CheckStatsChange()
		local C = site.checkStatsChangeCall
		expectInstruction(C - 0x3, {0x48, 0x8B, 0xCE}, nil, "mov rcx, rsi")
		expectInstruction(C + 0x0, {0xE8}, nil, "call rel32")

		-- 4) CGameSprite::CheckStatsChange(), the blind visual range block (D = site.visualRange). rbx = this.
		--     D-0x9   test dword ptr [r15], STATE_BLIND                ; r15 = &m_derivedStats.m_generalState
		--     D-0x2   je D+0xD
		--     D       mov ecx, <vanilla blind visual range>            ; replaced by the hook (5 bytes)
		--     D+0x5   mov dword ptr [rbx+m_derivedStats.m_nVisualRange], ecx
		--     D+0xB   jmp D+0x13
		--     D+0xD   mov ecx, dword ptr [rbx+m_derivedStats.m_nVisualRange]
		--     D+0x13  movzx eax, byte ptr [rbx+m_nVisualRange]         ; compared with ecx (flags overwritten)
		--     D+0x1A  cmp eax, ecx
		local D = site.visualRange
		expectInstruction(D - 0x9, {0x41, 0xF7, 0x07}, stateBlindMask, "test dword ptr [r15], STATE_BLIND")
		expectInstruction(D - 0x2, {0x74}, nil, "je rel8")
		expectBranchTarget(D - 0x2, D + 0xD, "je rel8")
		expectInstruction(D + 0x0, {0xB9}, nil, "mov ecx, imm32")
		expectInstruction(D + 0x5, {0x89, 0x8B}, derivedVisualRangeOffset, "mov dword ptr [rbx+m_derivedStats.m_nVisualRange], ecx")
		expectInstruction(D + 0xB, {0xEB}, nil, "jmp rel8")
		expectBranchTarget(D + 0xB, D + 0x13, "jmp rel8")
		expectInstruction(D + 0xD, {0x8B, 0x8B}, derivedVisualRangeOffset, "mov ecx, dword ptr [rbx+m_derivedStats.m_nVisualRange]")
		expectInstruction(D + 0x13, {0x0F, 0xB6, 0x83}, spriteVisualRangeOffset, "movzx eax, byte ptr [rbx+m_nVisualRange]")
		expectInstruction(D + 0x1A, {0x3B, 0xC1}, nil, "cmp eax, ecx")
		local vanillaVisualRange = EEex_Read32(D + 0x1)

		-- 5) CGameSprite::GetStatBreakdown(this = r12), the timed effect loop's op74 tooltip block (E = site.breakdownJne)
		--    and the loop exit (F = site.breakdownExit), which directly follows it.
		--     E-0x4   cmp dword ptr [rsi+m_effectId], 74
		--     E       jne E+0x89                                       ; forced into `jmp E+0x89` (skip the vanilla lines)
		--     E+0x6   test dword ptr [r12+m_derivedStats.m_generalState], STATE_BLIND / je E+0x89
		--     E+0x1F  mov edx, <icon> / ... / call CRuleTables::GetCharacterStateDescription()   ; r15 = rule tables
		--     E+0x3B  mov r9d, <AC delta> / ... / CString::Format() / *[rbp+<AC slot>] += line
		--     E+0x62  mov r9d, <THAC0 delta> / ... / CString::Format() / *[rbp+<THAC0 slot>] += line
		--     E+0x89  mov r14, qword ptr [r14] / test r14, r14 / jne <loop>
		--     F       cmp dword ptr [rbp+disp8], 0 / mov r15, qword ptr [rsp+disp32]  ; hooked, both restored (12 bytes)
		local E = site.breakdownJne
		local F = site.breakdownExit
		expectInstruction(E - 0x4, {0x83, 0x7E, effectIdOffset, blindnessOpcode}, nil, "cmp dword ptr [rsi+m_effectId], 74")
		expectInstruction(E + 0x0, {0x0F, 0x85}, nil, "jne rel32")
		expectBranchTarget(E + 0x0, E + 0x89, "jne rel32")
		expectInstruction(E + 0x6, {0x41, 0xF7, 0x84, 0x24}, derivedGeneralStateOffset, "test dword ptr [r12+m_derivedStats.m_generalState], imm32")
		expectInstruction(E + 0xE, {}, stateBlindMask, "test dword ptr [r12+m_derivedStats.m_generalState], STATE_BLIND")
		expectInstruction(E + 0x12, {0x74}, nil, "je rel8")
		expectBranchTarget(E + 0x12, E + 0x89, "je rel8")
		expectInstruction(E + 0x14, {0x48, 0x8B, 0x05}, nil, "mov rax, qword ptr [rip+rel32]")
		expectInstruction(E + 0x1B, {0x4C, 0x8D, 0x45, false}, nil, "lea r8, [rbp+disp8]")
		expectInstruction(E + 0x1F, {0xBA}, vanillaPortraitIcon, "mov edx, <vanilla portrait icon>")  -- Label row == icon row
		expectInstruction(E + 0x24, {0x48, 0x89, 0x45, false}, nil, "mov qword ptr [rbp+disp8], rax")
		expectInstruction(E + 0x28, {0x49, 0x8B, 0xCF}, nil, "mov rcx, r15")
		expectInstruction(E + 0x2B, {0xE8}, nil, "call rel32")
		expectInstruction(E + 0x30, {0x4C, 0x8B, 0x45, false}, nil, "mov r8, qword ptr [rbp+disp8]")
		expectInstruction(E + 0x34, {0x48, 0x8D, 0x15}, nil, "lea rdx, [rip+rel32]")
		expectInstruction(E + 0x3B, {0x41, 0xB9}, vanillaArmorClassDelta, "mov r9d, <vanilla AC delta>")
		expectInstruction(E + 0x41, {0x48, 0x8D, 0x4D, false}, nil, "lea rcx, [rbp+disp8]")
		expectInstruction(E + 0x45, {0xE8}, nil, "call rel32")
		expectInstruction(E + 0x4A, {0x48, 0x8B, 0x4D, false}, nil, "mov rcx, qword ptr [rbp+disp8]")
		expectInstruction(E + 0x4E, {0x48, 0x8D, 0x55, false}, nil, "lea rdx, [rbp+disp8]")
		expectInstruction(E + 0x52, {0xE8}, nil, "call rel32")
		expectInstruction(E + 0x57, {0x4C, 0x8B, 0x45, false}, nil, "mov r8, qword ptr [rbp+disp8]")
		expectInstruction(E + 0x5B, {0x48, 0x8D, 0x15}, nil, "lea rdx, [rip+rel32]")
		expectInstruction(E + 0x62, {0x41, 0xB9}, vanillaTHAC0Delta, "mov r9d, <vanilla THAC0 delta>")
		expectInstruction(E + 0x68, {0x48, 0x8D, 0x4C, 0x24, false}, nil, "lea rcx, [rsp+disp8]")
		expectInstruction(E + 0x6D, {0xE8}, nil, "call rel32")
		expectInstruction(E + 0x72, {0x48, 0x8B, 0x4D, false}, nil, "mov rcx, qword ptr [rbp+disp8]")
		expectInstruction(E + 0x76, {0x48, 0x8D, 0x54, 0x24, false}, nil, "lea rdx, [rsp+disp8]")
		expectInstruction(E + 0x7B, {0xE8}, nil, "call rel32")
		expectInstruction(E + 0x80, {0x48, 0x8D, 0x4D, false}, nil, "lea rcx, [rbp+disp8]")
		expectInstruction(E + 0x84, {0xE8}, nil, "call rel32")
		expectInstruction(E + 0x89, {0x4D, 0x8B, 0x36}, nil, "mov r14, qword ptr [r14]")
		expectInstruction(E + 0x8C, {0x4D, 0x85, 0xF6}, nil, "test r14, r14")
		expectInstruction(E + 0x8F, {0x0F, 0x85}, nil, "jne rel32")
		if F ~= E + 0x95 then
			EEex_Error("Opcode #74: GetStatBreakdown()'s loop exit does not directly follow the op74 tooltip block")
		end
		expectInstruction(F + 0x0, {0x83, 0x7D, false, 0x00}, nil, "cmp dword ptr [rbp+disp8], 0")
		expectInstruction(F + 0x4, {0x4C, 0x8B, 0xBC, 0x24}, nil, "mov r15, qword ptr [rsp+disp32]")
		expectInstruction(F + 0xC, {0x4C, 0x8B, 0xB4, 0x24}, nil, "mov r14, qword ptr [rsp+disp32]")

		-- Both vanilla lines use CString::Format() and CString::operator+=(), so they are the same kind of output
		if branchTarget(E + 0x45) ~= branchTarget(E + 0x6D) or branchTarget(E + 0x52) ~= branchTarget(E + 0x7B) then
			EEex_Error("Opcode #74: GetStatBreakdown()'s two tooltip lines are not produced the same way")
		end

		local getCharacterStateDescription = branchTarget(E + 0x2B)
		-- The AC / THAC0 texts vanilla appends to (the 1st / 3rd CString* arguments, spilled to these rbp slots)
		local armorClassTextOperand = string.format("rbp%+d", EEex_Read8(E + 0x4D))
		local thac0TextOperand = string.format("rbp%+d", EEex_Read8(E + 0x75))

		-- Resolve the native side up front (errors if the matching EEex.dll does not export it)
		local slots = {
			["stateBlindMask"] = EEex_Label("EEex::Opcode_Op74_StateBlindMask"),
			["permanentDurationType"] = EEex_Label("EEex::Opcode_Op74_PermanentDurationType"),
			["vanillaArmorClassDelta"] = EEex_Label("EEex::Opcode_Op74_VanillaArmorClassDelta"),
			["vanillaTHAC0Delta"] = EEex_Label("EEex::Opcode_Op74_VanillaTHAC0Delta"),
			["vanillaPortraitIcon"] = EEex_Label("EEex::Opcode_Op74_VanillaPortraitIcon"),
			["vanillaVisualRange"] = EEex_Label("EEex::Opcode_Op74_VanillaVisualRange"),
			["addPortraitIcon"] = EEex_Label("EEex::Opcode_Op74_AddPortraitIcon"),
			["removePortraitIcon"] = EEex_Label("EEex::Opcode_Op74_RemovePortraitIcon"),
			["getCharacterStateDescription"] = EEex_Label("EEex::Opcode_Op74_GetCharacterStateDescription"),
		}
		local applyEffectHook = EEex_Label("EEex::Opcode_Hook_Blindness_ApplyEffect")
		local onRemoveHook = EEex_Label("EEex::Opcode_Hook_Blindness_OnRemove")
		EEex_Label("EEex::Opcode_Hook_Op74_ApplyBlindnessConsequences")
		EEex_Label("EEex::Opcode_Hook_Op74_GetBlindVisualRange")
		EEex_Label("EEex::Opcode_Hook_Op74_AppendStatBreakdown")

		---------------------------------------------------------------------------------
		-- Hand the vanilla values and engine functions to EEex.dll (before any hook) --
		---------------------------------------------------------------------------------

		EEex_Write32(slots.stateBlindMask, stateBlindMask)
		EEex_Write32(slots.permanentDurationType, permanentDurationType)
		EEex_Write32(slots.vanillaArmorClassDelta, vanillaArmorClassDelta)
		EEex_Write32(slots.vanillaTHAC0Delta, vanillaTHAC0Delta)
		EEex_Write32(slots.vanillaPortraitIcon, vanillaPortraitIcon)
		EEex_Write32(slots.vanillaVisualRange, vanillaVisualRange)
		EEex_WritePtr(slots.addPortraitIcon, addPortraitIcon)
		EEex_WritePtr(slots.removePortraitIcon, removePortraitIcon)
		EEex_WritePtr(slots.getCharacterStateDescription, getCharacterStateDescription)

		---------------------------------------------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_Blindness_ApplyEffect() / EEex::Opcode_Hook_Blindness_OnRemove() --
		---------------------------------------------------------------------------------------------------

		-- Replace both functions entirely (same arguments, same stack, same return register). The 5-byte `jmp rel32` goes
		-- to a near stub holding the jump to EEex.dll, so the write always fits, even in OnRemove()'s 13 bytes.
		EEex_JITAt(A, {"jmp short ", EEex_JITNear({"jmp ", applyEffectHook, "#ENDL"}), "#ENDL"})
		EEex_JITAt(R, {"jmp short ", EEex_JITNear({"jmp ", onRemoveHook, "#ENDL"}), "#ENDL"})

		----------------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_Op74_ApplyBlindnessConsequences() --
		----------------------------------------------------------------------

		-- Right before ProcessEffectList() calls CheckStatsChange(this = rcx = rsi). CheckStatsChange() takes no other
		-- argument; rdx / r8 / r9 are preserved anyway, and rcx is reloaded for the original call.
		EEex_HookBeforeCallWithLabels(C, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				#MAKE_SHADOW_SPACE(24)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r9

				                                                         ; rcx already pSprite (`mov rcx, rsi`)
				call #L(EEex::Opcode_Hook_Op74_ApplyBlindnessConsequences)

				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
				mov rcx, rsi                                             ; CheckStatsChange()'s `this` again
			]]}
		)

		--------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_Op74_GetBlindVisualRange() --
		--------------------------------------------------------------

		-- Replaces `mov ecx, <vanilla blind visual range>` (5 bytes) and returns to the engine's
		-- `mov dword ptr [rbx+m_derivedStats.m_nVisualRange], ecx`. rbx = this. rax / r10 / r11 are dead there, and the
		-- flags are overwritten (`cmp eax, ecx`) before being read; rdx / r8 / r9 and xmm0-xmm5 are preserved.
		EEex_HookNOPsWithLabels(D, 0, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX,
				EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				#MAKE_SHADOW_SPACE(120)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r9
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-40)], xmm0
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-56)], xmm1
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-72)], xmm2
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-88)], xmm3
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-104)], xmm4
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-120)], xmm5

				mov rcx, rbx                                       ; pSprite
				call #L(EEex::Opcode_Hook_Op74_GetBlindVisualRange)
				mov ecx, eax                                       ; What the replaced `mov ecx, imm32` produced

				movdqu xmm5, [rsp+#SHADOW_SPACE_BOTTOM(-120)]
				movdqu xmm4, [rsp+#SHADOW_SPACE_BOTTOM(-104)]
				movdqu xmm3, [rsp+#SHADOW_SPACE_BOTTOM(-88)]
				movdqu xmm2, [rsp+#SHADOW_SPACE_BOTTOM(-72)]
				movdqu xmm1, [rsp+#SHADOW_SPACE_BOTTOM(-56)]
				movdqu xmm0, [rsp+#SHADOW_SPACE_BOTTOM(-40)]
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]}
		)

		--------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_Op74_AppendStatBreakdown() --
		--------------------------------------------------------------

		-- The timed effect loop never prints the vanilla per-op74 lines: `jne <next effect>` becomes `jmp <next effect>`
		EEex_ForceJump(E)

		-- At the loop exit (both the "empty list" jump and the loop's fallthrough land on its first byte). r12 = this. The
		-- two restored instructions overwrite the flags and reload r15. rax / rcx / rdx / r10 / r11 are dead there; r8 /
		-- r9 and xmm0-xmm5 are preserved.
		EEex_HookBeforeRestoreWithLabels(F, 0, 12, 12, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
				EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				#MAKE_SHADOW_SPACE(112)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], r9
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-32)], xmm0
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-48)], xmm1
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-64)], xmm2
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-80)], xmm3
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-96)], xmm4
				movdqu [rsp+#SHADOW_SPACE_BOTTOM(-112)], xmm5

				mov r8, qword ptr ss:[#$(1)]                       ; pTHAC0Text (3rd argument, spilled by the prologue)
				mov rdx, qword ptr ss:[#$(2)]                      ; pArmorClassText (1st argument, spilled by the prologue)
				mov rcx, r12                                       ; pSprite
				call #L(EEex::Opcode_Hook_Op74_AppendStatBreakdown)

				movdqu xmm5, [rsp+#SHADOW_SPACE_BOTTOM(-112)]
				movdqu xmm4, [rsp+#SHADOW_SPACE_BOTTOM(-96)]
				movdqu xmm3, [rsp+#SHADOW_SPACE_BOTTOM(-80)]
				movdqu xmm2, [rsp+#SHADOW_SPACE_BOTTOM(-64)]
				movdqu xmm1, [rsp+#SHADOW_SPACE_BOTTOM(-48)]
				movdqu xmm0, [rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]], {thac0TextOperand, armorClassTextOperand}}
		)
	end)

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
