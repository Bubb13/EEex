
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
	+-------------------------------------------------------------------------------------------------------------------------------+
	| Opcodes #25 / #78 / #98 / #232 / #272 - param2 BIT16: Haste/Slow-neutral timing                                               |
	+-------------------------------------------------------------------------------------------------------------------------------+
	|   Vanilla advances these effects with per-AI-update clocks, and Haste / Slow change how often a sprite gets an AI update      |
	|   (twice / half as often). With param2 BIT16 (0x10000) set, they follow game time instead, exactly like vanilla at normal     |
	|   speed, whatever the sprite's Haste / Slow state:                                                                            |
	|                                                                                                                               |
	|   op25 (Poison), op78 (Disease), op98 (Regeneration), op272 (Use EFF File on Repeat):                                         |
	|       One effect "second" per game second (15 game ticks), and the effect's remaining duration follows game time. After the   |
	|       sprite was not processed for a while (Time Stop victim, Imprisonment, inactive area) at most one second is processed,   |
	|       like vanilla. Rest / area re-entry (CompressTime) is processed the vanilla way.                                         |
	|   op232 (Cast Spell on Condition):                                                                                            |
	|       Status conditions (e.g. "HP below 50%") are polled every 101 game ticks, vanilla's normal-speed cadence, instead of     |
	|       every 101 AI updates. Event conditions (e.g. "hit by") are unchanged.                                                   |
	|                                                                                                                               |
	|   param2 -> The vanilla value in the low word (op232: low byte), plus BIT16 (0x10000) for the neutral timing. Vanilla only    |
	|             reads that low word / byte, so the bit is ignored without EEex. Everything else works as in vanilla.              |
	|                                                                                                                               |
	|   op177 / op182 / op183 / op283 call their decoded .EFF child's ApplyEffect() directly. The persistent effect hooks sit       |
	|   inside the child ApplyEffect() functions, and a CContingency keeps a full copy of its effect, so .EFF children are covered. |
	+-------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_OnPersistantEffectAddTail(pEffect: CGameEffect*, pPersistantEffect: CPersistantEffect*)        |
	|       Marks the persistent effect op25 / op78 / op98 / op272 just created as neutral (or not)                                 |
	+-------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ProcessEffectList_AIUpdatePersistantEffects(pList, pSprite, nDelta)                            |
	|   [EEex.dll] EEex::Opcode_Hook_HandlePersistantEffects_AIUpdatePersistantEffects(pList, pSprite, nDelta)                      |
	|       Same arguments as CPersistantEffectListRegenerated::AIUpdate(), which they reimplement (with the neutral timing)        |
	+-------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ContingencyCheck(pSprite: CGameSprite*)                                                        |
	|       Reimplements CGameSprite::ContingencyCheck(), then runs the neutral op232 pass when it is due                           |
	+-------------------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Opcode_Hook_ContingencyList_ShouldProcess(pList: CContingencyList*, pContingency: CContingency*) -> bool   |
	|       return:                                                                                                                 |
	|           -> false - Skip the contingency in this pass                                                                        |
	|           -> true  - Evaluate it (vanilla behavior)                                                                           |
	+-------------------------------------------------------------------------------------------------------------------------------+
	| Why these hooks (every engine fact below is verified for BG2:EE, BG:EE, and IWD:EE):                                          |
	|   * AddTail() sites: EEex_HookBeforeCallWithLabels() on the five calls adding a new CPersistantEffect{Poison,Regeneration,    |
	|     Disease,ApplyEffect} to m_derivedStats.m_cRegeneratedPersistantEffectList. These are the only places creating those       |
	|     classes (besides Copy()). rcx = the list, rdx = rbx = the new effect, and the effect being applied is in a nonvolatile    |
	|     register (rdi / rsi). rcx / rdx are preserved around the call; r8-r11 / rax are not AddTail() arguments.                  |
	|   * List update: EEex_HookBeforeCallWithLabels() replaces both calls to CPersistantEffectListRegenerated::AIUpdate()          |
	|     (ProcessEffectList() and HandlePersistantEffects(), its only callers) with the C++ reimplementation, same arguments.      |
	|   * ContingencyCheck(): EEex_JITAt() writes a `jmp` over its first instruction. Its only caller is ProcessAI(), nothing       |
	|     branches into its body, and it is fully reimplemented in C++ with the exact same Win64 ABI.                               |
	|   * CContingencyList::Process(): EEex_HookConditionalJumpOnFailWithLabels() on the per-node `je` that skips non-status        |
	|     triggers. On its fall-through, r13 = the list, rsi = the CContingency; rax / rcx / rdx / r8-r11 are dead on both paths.   |
	+-------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_Utility_NewScope(function()

		-- These labels are only shipped in v2.7.3.0's pattern database (pattern_dbs/v2.7.3.0.db).
		-- On other engine versions all of them are absent: vanilla timing is kept.
		local labelNames = {
			["addPoison"]            = "Hook-CGameEffectPoison::ApplyEffect()-AddTail",
			["addRegeneration"]      = "Hook-CGameEffectRegeneration::ApplyEffect()-AddTail",
			["addDisease1"]          = "Hook-CGameEffectDisease::ApplyEffect()-AddTail-1",
			["addDisease2"]          = "Hook-CGameEffectDisease::ApplyEffect()-AddTail-2",
			["addRepeating"]         = "Hook-CGameEffectRepeatingApplyEffect::ApplyEffect()-AddTail",
			["callProcessEffectList"] = "Hook-CGameSprite::ProcessEffectList()-CPersistantEffectListRegenerated::AIUpdate()",
			["callHandlePersistant"] = "Hook-CGameSprite::HandlePersistantEffects()-CPersistantEffectListRegenerated::AIUpdate()",
			["listAIUpdate"]         = "CPersistantEffectListRegenerated::AIUpdate",
			["aiPoison"]             = "CPersistantEffectPoison::AIUpdate",
			["aiDisease"]            = "CPersistantEffectDisease::AIUpdate",
			["aiRegeneration"]       = "CPersistantEffectRegeneration::AIUpdate",
			["aiApplyEffect"]        = "CPersistantEffectApplyEffect::AIUpdate",
			["contingencyCheck"]     = "Hook-CGameSprite::ContingencyCheck()-FirstInstruction",
			["processFilter"]        = "Hook-CContingencyList::Process()-StatusTriggerJmp",
		}

		local addresses = {}
		local foundCount = 0
		local missing = {}
		for key, labelName in pairs(labelNames) do
			local address = EEex_TryLabel(labelName)
			addresses[key] = address
			if address ~= nil then
				foundCount = foundCount + 1
			else
				table.insert(missing, labelName)
			end
		end

		if foundCount == 0 then
			return -- Engine version without these labels: keep vanilla timing
		end

		if #missing > 0 then
			-- Installing only some hooks would mark effects that are never ticked neutrally (or the reverse)
			table.sort(missing)
			EEex_Error("Neutral timing: incomplete pattern database, missing "..table.concat(missing, ", "))
		end

		-------------------------------------------------------------------------------------------------------
		-- The short pattern signatures only locate the sites. Validate every instruction the hooks (and the --
		-- C++ reimplementations) rely on before writing anything, so a mismatch never leaves a half-applied --
		-- change behind.                                                                                    --
		-------------------------------------------------------------------------------------------------------

		-- `address` must hold `bytes` (`false` matches any byte), optionally followed by an unsigned 32-bit value `u32`
		local expectInstruction = function(address, bytes, u32, description)
			for i = 1, #bytes do
				local byte = bytes[i]
				if byte ~= false and EEex_ReadU8(address + i - 1) ~= byte then
					EEex_Error(string.format("Neutral timing: expected `%s` at %s", description, EEex_ToHex(address)))
				end
			end
			if u32 ~= nil and EEex_ReadU32(address + #bytes) ~= u32 then
				EEex_Error(string.format("Neutral timing: unexpected 32-bit operand in `%s` at %s", description, EEex_ToHex(address)))
			end
		end

		-- The rel32 operand `operandOffset` bytes into the instruction at `address` (call / jmp / RIP-relative operand,
		-- relative to the end of the operand, which ends each of these instructions) must reach `target`
		local expectRel32Target = function(address, operandOffset, target, description)
			if address + operandOffset + 4 + EEex_Read32(address + operandOffset) ~= target then
				EEex_Error(string.format("Neutral timing: `%s` at %s does not reach %s", description, EEex_ToHex(address), EEex_ToHex(target)))
			end
		end

		local spriteDerivedStatsOffset = EEex_OffsetOf("CGameSprite.m_derivedStats")
		local regeneratedListOffset = spriteDerivedStatsOffset + EEex_OffsetOf("CDerivedStats.m_cRegeneratedPersistantEffectList")
		local contingencyListOffset = spriteDerivedStatsOffset + EEex_OffsetOf("CDerivedStats.m_cContingencyList")
		local countdownOffset = EEex_OffsetOf("CGameSprite.m_nLastContingencyCheck")
		local nodeHeadOffset = EEex_OffsetOf("CPtrList.m_pNodeHead")
		local nodeDataOffset = 2 * EEex_PtrSize -- CPtrList::CNode { pNext, pPrev, data }
		local listCounterOffset = EEex_OffsetOf("CPersistantEffectListRegenerated.m_nCounter")
		local effectDoneOffset = EEex_OffsetOf("CPersistantEffect.m_done")
		local effectDeletedOffset = EEex_OffsetOf("CPersistantEffect.m_deleted")
		local effectCounterOffset = EEex_OffsetOf("CPersistantEffect.m_counter")
		-- CPersistantEffectDamage::m_duration. That class is missing from the bindings / generated headers: EEex.dll
		-- static_asserts the same offset in its CPersistantEffectDamageLayout mirror.
		local effectDurationOffset = 0x28
		local objectGameOffset = EEex_OffsetOf("EEex_CBaldurChitin.m_pObjectGame")
		local worldTimeActiveOffset = EEex_OffsetOf("EEex_CInfGame.m_worldTime.m_active")
		-- Game ticks per game second, EEex.dll's ENGINE_TICKS_PER_SECOND (validated below in every persistent AIUpdate())
		local ticksPerSecond = 15

		local addTailAddress = EEex_Label("CObList::AddTail")
		local removeAtAddress = EEex_Label("CObList::RemoveAt")
		local processAddress = EEex_Label("CContingencyList::Process")

		-- 1) The five AddTail() sites (S = the call):
		--     S-10  lea rcx, qword ptr [<sprite>+m_derivedStats.m_cRegeneratedPersistantEffectList]
		--     S-3   mov rdx, rbx                   ; the new persistent effect
		--     S     call CObList::AddTail
		--    `effectRegister` holds the CGameEffect being applied.
		local addTailSites = {
			{ ["key"] = "addPoison",       ["spriteModRM"] = 0x8D, ["effectRegister"] = "rdi" }, -- sprite: rbp
			{ ["key"] = "addRegeneration", ["spriteModRM"] = 0x8D, ["effectRegister"] = "rdi" }, -- sprite: rbp
			{ ["key"] = "addDisease1",     ["spriteModRM"] = 0x8F, ["effectRegister"] = "rsi" }, -- sprite: rdi
			{ ["key"] = "addDisease2",     ["spriteModRM"] = 0x8F, ["effectRegister"] = "rsi" }, -- sprite: rdi
			{ ["key"] = "addRepeating",    ["spriteModRM"] = 0x8E, ["effectRegister"] = "rdi" }, -- sprite: rsi
		}
		for _, site in ipairs(addTailSites) do
			local S = addresses[site.key]
			expectInstruction(S - 10, {0x48, 0x8D, site.spriteModRM}, regeneratedListOffset, site.key..": lea rcx, [<sprite>+list]")
			expectInstruction(S - 3, {0x48, 0x8B, 0xD3}, nil, site.key..": mov rdx, rbx")
			expectInstruction(S, {0xE8}, nil, site.key..": call AddTail")
			expectRel32Target(S, 1, addTailAddress, site.key..": call AddTail")
		end

		-- 2) The two calls to CPersistantEffectListRegenerated::AIUpdate() (S = the call):
		--     S-13  lea rcx, qword ptr [rsi+m_derivedStats.m_cRegeneratedPersistantEffectList]
		--     S-6   mov r8d, r13d (ProcessEffectList(), r13d = 1) / mov r8d, r14d (HandlePersistantEffects(), nDelta)
		--     S-3   mov rdx, rsi                   ; the sprite
		--     S     call CPersistantEffectListRegenerated::AIUpdate
		local listCallSites = {
			{ ["key"] = "callProcessEffectList", ["deltaModRM"] = 0xC5 },
			{ ["key"] = "callHandlePersistant",  ["deltaModRM"] = 0xC6 },
		}
		for _, site in ipairs(listCallSites) do
			local S = addresses[site.key]
			expectInstruction(S - 13, {0x48, 0x8D, 0x8E}, regeneratedListOffset, site.key..": lea rcx, [rsi+list]")
			expectInstruction(S - 6, {0x45, 0x8B, site.deltaModRM}, nil, site.key..": mov r8d, <delta>")
			expectInstruction(S - 3, {0x48, 0x8B, 0xD6}, nil, site.key..": mov rdx, rsi")
			expectInstruction(S, {0xE8}, nil, site.key..": call list AIUpdate")
			expectRel32Target(S, 1, addresses.listAIUpdate, site.key..": call list AIUpdate")
		end

		-- 3) CPersistantEffectListRegenerated::AIUpdate(this = rcx, pSprite = rdx, nDelta = r8d) (L), the instructions
		--    EEex.dll's reimplementation mirrors (the rest is register saves / restores and branches):
		--     L+0x13  mov rdi, qword ptr [rcx+m_pNodeHead]       L+0x52  cmp dword ptr [rbx+m_deleted], 0
		--     L+0x17  mov r14d, r8d                              L+0x58  cmp dword ptr [rbx+m_done], 0
		--     L+0x1A  mov r15, rdx                               L+0x5E  mov rdx, rbp
		--     L+0x1D  mov rsi, rcx                               L+0x61  mov rcx, rsi
		--     L+0x30  mov rbx, qword ptr [rdi+data]              L+0x64  call CObList::RemoveAt
		--     L+0x34  mov rdi, qword ptr [rdi]                   L+0x69  mov rax, qword ptr [rbx]
		--     L+0x37  cmp dword ptr [rbx+m_deleted], 0           L+0x6C  mov edx, 1
		--     L+0x3D  mov eax, dword ptr [rsi+m_nCounter]        L+0x71  mov rcx, rbx
		--     L+0x40  mov r8d, r14d                              L+0x74  call qword ptr [rax]   ; delete, flag 1
		--     L+0x43  mov dword ptr [rbx+m_counter], eax         L+0x7E  inc dword ptr [rsi+m_nCounter]
		--     L+0x46  mov rdx, r15                               L+0x88  inc dword ptr [rcx+m_nCounter]   ; empty list
		--     L+0x49  mov rax, qword ptr [rbx]
		--     L+0x4C  mov rcx, rbx
		--     L+0x4F  call qword ptr [rax+0x8]                   ; AIUpdate(pSprite, nDelta)
		local L = addresses.listAIUpdate
		expectInstruction(L + 0x13, {0x48, 0x8B, 0x79, nodeHeadOffset}, nil, "list: mov rdi, qword ptr [rcx+m_pNodeHead]")
		expectInstruction(L + 0x17, {0x45, 0x8B, 0xF0}, nil, "list: mov r14d, r8d")
		expectInstruction(L + 0x1A, {0x4C, 0x8B, 0xFA}, nil, "list: mov r15, rdx")
		expectInstruction(L + 0x1D, {0x48, 0x8B, 0xF1}, nil, "list: mov rsi, rcx")
		expectInstruction(L + 0x30, {0x48, 0x8B, 0x5F, nodeDataOffset}, nil, "list: mov rbx, qword ptr [rdi+data]")
		expectInstruction(L + 0x34, {0x48, 0x8B, 0x3F}, nil, "list: mov rdi, qword ptr [rdi]")
		expectInstruction(L + 0x37, {0x83, 0x7B, effectDeletedOffset, 0x00}, nil, "list: cmp dword ptr [rbx+m_deleted], 0")
		expectInstruction(L + 0x3D, {0x8B, 0x46, listCounterOffset}, nil, "list: mov eax, dword ptr [rsi+m_nCounter]")
		expectInstruction(L + 0x40, {0x45, 0x8B, 0xC6}, nil, "list: mov r8d, r14d")
		expectInstruction(L + 0x43, {0x89, 0x43, effectCounterOffset}, nil, "list: mov dword ptr [rbx+m_counter], eax")
		expectInstruction(L + 0x46, {0x49, 0x8B, 0xD7}, nil, "list: mov rdx, r15")
		expectInstruction(L + 0x49, {0x48, 0x8B, 0x03}, nil, "list: mov rax, qword ptr [rbx]")
		expectInstruction(L + 0x4C, {0x48, 0x8B, 0xCB}, nil, "list: mov rcx, rbx")
		expectInstruction(L + 0x4F, {0xFF, 0x50, 0x08}, nil, "list: call qword ptr [rax+0x8]")
		expectInstruction(L + 0x52, {0x83, 0x7B, effectDeletedOffset, 0x00}, nil, "list: cmp dword ptr [rbx+m_deleted], 0")
		expectInstruction(L + 0x58, {0x83, 0x7B, effectDoneOffset, 0x00}, nil, "list: cmp dword ptr [rbx+m_done], 0")
		expectInstruction(L + 0x5E, {0x48, 0x8B, 0xD5}, nil, "list: mov rdx, rbp")
		expectInstruction(L + 0x61, {0x48, 0x8B, 0xCE}, nil, "list: mov rcx, rsi")
		expectInstruction(L + 0x64, {0xE8}, nil, "list: call RemoveAt")
		expectInstruction(L + 0x69, {0x48, 0x8B, 0x03}, nil, "list: mov rax, qword ptr [rbx]")
		expectInstruction(L + 0x6C, {0xBA, 0x01, 0x00, 0x00, 0x00}, nil, "list: mov edx, 1")
		expectInstruction(L + 0x71, {0x48, 0x8B, 0xCB}, nil, "list: mov rcx, rbx")
		expectInstruction(L + 0x74, {0xFF, 0x10}, nil, "list: call qword ptr [rax]")
		expectInstruction(L + 0x7E, {0xFF, 0x46, listCounterOffset}, nil, "list: inc dword ptr [rsi+m_nCounter]")
		expectInstruction(L + 0x88, {0xFF, 0x41, listCounterOffset}, nil, "list: inc dword ptr [rcx+m_nCounter]")
		expectRel32Target(L + 0x64, 1, removeAtAddress, "list: call RemoveAt")

		-- 4) The timing prologue of the four persistent AIUpdate(this = rbx, nDelta = r11d) functions (A), the
		--    instructions EEex.dll's neutral inputs rely on (see its updateRegeneratedPersistantEffects()):
		--     mov ecx, dword ptr [rbx+m_duration]         ; old m_duration
		--     mov r10d, dword ptr [rbx+m_counter]
		--     inc r10d / add r10d, k                      ; m_counter + k, k in [1, 14]: m_counter = 0 is never a boundary
		--     mov dword ptr [rbx+m_counter], r10d
		--     sub r9d, r11d                               ; m_duration - nDelta
		--     mov dword ptr [rbx+m_duration], r9d
		--     imul ecx, edx, 15 (x2)                      ; the `% 15` second boundary checks
		local persistantPrologues = {
			{ ["key"] = "aiPoison",       ["k"] = 2, ["offsets"] = {0x66, 0x6E, 0x78, 0x84, 0x8C, 0x92, 0xEB, 0x116} },
			{ ["key"] = "aiDisease",      ["k"] = 1, ["offsets"] = {0x66, 0x6E, 0x78, 0x83, 0x8B, 0x91, 0xEA, 0x118} },
			{ ["key"] = "aiRegeneration", ["k"] = 1, ["offsets"] = {0x50, 0x58, 0x62, 0x6D, 0x75, 0x7B, 0xD4, 0xFF} },
			{ ["key"] = "aiApplyEffect",  ["k"] = 1, ["offsets"] = {0x78, 0x80, 0x8A, 0x95, 0x9D, 0xA3, 0xFA, 0x11B} },
		}
		for _, prologue in ipairs(persistantPrologues) do
			local A = addresses[prologue.key]
			local o = prologue.offsets
			local increment = prologue.k == 1 and {0x41, 0xFF, 0xC2} or {0x41, 0x83, 0xC2, prologue.k}
			if prologue.k < 1 or prologue.k > ticksPerSecond - 1 then
				EEex_Error("Neutral timing: invalid m_counter increment for "..prologue.key)
			end
			expectInstruction(A + o[1], {0x8B, 0x4B, effectDurationOffset}, nil, prologue.key..": mov ecx, dword ptr [rbx+m_duration]")
			expectInstruction(A + o[2], {0x44, 0x8B, 0x53, effectCounterOffset}, nil, prologue.key..": mov r10d, dword ptr [rbx+m_counter]")
			expectInstruction(A + o[3], increment, nil, prologue.key..": m_counter + k")
			expectInstruction(A + o[4], {0x44, 0x89, 0x53, effectCounterOffset}, nil, prologue.key..": mov dword ptr [rbx+m_counter], r10d")
			expectInstruction(A + o[5], {0x45, 0x2B, 0xCB}, nil, prologue.key..": sub r9d, r11d")
			expectInstruction(A + o[6], {0x44, 0x89, 0x4B, effectDurationOffset}, nil, prologue.key..": mov dword ptr [rbx+m_duration], r9d")
			expectInstruction(A + o[7], {0x6B, 0xCA, ticksPerSecond}, nil, prologue.key..": imul ecx, edx, 15")
			expectInstruction(A + o[8], {0x6B, 0xCA, ticksPerSecond}, nil, prologue.key..": imul ecx, edx, 15")
		end

		-- 5) CGameSprite::ContingencyCheck(this = rcx) (C), complete (60 bytes), the function EEex.dll replaces:
		--     C+0x00  mov rax, qword ptr [rip+g_pBaldurChitin]
		--     C+0x07  mov r8, rcx
		--     C+0x0A  mov rdx, qword ptr [rax+m_pObjectGame]
		--     C+0x11  cmp byte ptr [rdx+m_worldTime.m_active], 0
		--     C+0x18  je C+0x2D
		--     C+0x1A  mov eax, dword ptr [rcx+m_nLastContingencyCheck]
		--     C+0x20  test eax, eax / jle C+0x2D / dec eax
		--     C+0x26  mov dword ptr [rcx+m_nLastContingencyCheck], eax
		--     C+0x2C  ret
		--     C+0x2D  add rcx, m_derivedStats.m_cContingencyList
		--     C+0x34  mov rdx, r8
		--     C+0x37  jmp CContingencyList::Process
		local C = addresses.contingencyCheck
		expectInstruction(C + 0x00, {0x48, 0x8B, 0x05}, nil, "ContingencyCheck: mov rax, qword ptr [rip+g_pBaldurChitin]")
		expectInstruction(C + 0x07, {0x4C, 0x8B, 0xC1}, nil, "ContingencyCheck: mov r8, rcx")
		expectInstruction(C + 0x0A, {0x48, 0x8B, 0x90}, objectGameOffset, "ContingencyCheck: mov rdx, qword ptr [rax+m_pObjectGame]")
		expectInstruction(C + 0x11, {0x80, 0xBA}, worldTimeActiveOffset, "ContingencyCheck: cmp byte ptr [rdx+m_worldTime.m_active], 0")
		expectInstruction(C + 0x17, {0x00, 0x74, 0x13}, nil, "ContingencyCheck: ... 0 / je +0x13")
		expectInstruction(C + 0x1A, {0x8B, 0x81}, countdownOffset, "ContingencyCheck: mov eax, dword ptr [rcx+m_nLastContingencyCheck]")
		expectInstruction(C + 0x20, {0x85, 0xC0, 0x7E, 0x09, 0xFF, 0xC8, 0x89, 0x81}, countdownOffset, "ContingencyCheck: test / jle / dec / mov")
		expectInstruction(C + 0x2C, {0xC3}, nil, "ContingencyCheck: ret")
		expectInstruction(C + 0x2D, {0x48, 0x81, 0xC1}, contingencyListOffset, "ContingencyCheck: add rcx, m_cContingencyList")
		expectInstruction(C + 0x34, {0x49, 0x8B, 0xD0}, nil, "ContingencyCheck: mov rdx, r8")
		expectInstruction(C + 0x37, {0xE9}, nil, "ContingencyCheck: jmp CContingencyList::Process")
		expectRel32Target(C + 0x00, 3, EEex_Label("g_pBaldurChitin"), "ContingencyCheck: [rip+g_pBaldurChitin]")
		expectRel32Target(C + 0x37, 1, processAddress, "ContingencyCheck: jmp CContingencyList::Process")

		-- 6) CContingencyList::Process(this = r13, pSprite = r14) (P), the per-node status-trigger test (F = the `je`), the
		--    gate EEex.dll opens for its neutral pass, and the reset value it reads back:
		--     F-17  mov rsi, qword ptr [r15+data]          ; the node's CContingency
		--     F-13  mov r15, qword ptr [r15]               ; next node
		--     F-10  movzx eax, word ptr [rsi]              ; m_cTrigger.m_triggerID
		--     F-7   test word ptr [rip+STATUSTRIGGER], ax
		--     F     je <next node>
		--     P+0x56  cmp dword ptr [r14+m_nLastContingencyCheck], 0 / jg <epilogue>
		--     P+0x98  mov dword ptr [r14+m_nLastContingencyCheck], <reset value>
		local F = addresses.processFilter
		expectInstruction(F - 17, {0x49, 0x8B, 0x77, nodeDataOffset}, nil, "Process: mov rsi, qword ptr [r15+data]")
		expectInstruction(F - 13, {0x4D, 0x8B, 0x3F}, nil, "Process: mov r15, qword ptr [r15]")
		expectInstruction(F - 10, {0x0F, 0xB7, 0x06}, nil, "Process: movzx eax, word ptr [rsi]")
		expectInstruction(F - 7, {0x66, 0x85, 0x05}, nil, "Process: test word ptr [rip+STATUSTRIGGER], ax")
		expectInstruction(F, {0x0F, 0x84}, nil, "Process: je rel32")
		expectInstruction(processAddress + 0x56, {0x41, 0x83, 0xBE}, countdownOffset, "Process: cmp dword ptr [r14+m_nLastContingencyCheck], 0")
		expectInstruction(processAddress + 0x5E, {0x0F, 0x8F}, nil, "Process: jg rel32")
		expectInstruction(processAddress + 0x98, {0x41, 0xC7, 0x86}, countdownOffset, "Process: mov dword ptr [r14+m_nLastContingencyCheck], <reset>")
		if EEex_ReadU32(processAddress + 0x98 + 7) == 0 then
			-- EEex.dll detects that its neutral pass ran from this value being written
			EEex_Error("Neutral timing: CContingencyList::Process() resets m_nLastContingencyCheck to 0")
		end

		-- Resolve the native side up front (errors if the matching EEex.dll does not export it)
		EEex_Label("EEex::Opcode_Hook_OnPersistantEffectAddTail")
		EEex_Label("EEex::Opcode_Hook_ProcessEffectList_AIUpdatePersistantEffects")
		EEex_Label("EEex::Opcode_Hook_HandlePersistantEffects_AIUpdatePersistantEffects")
		EEex_Label("EEex::Opcode_Hook_ContingencyCheck")
		EEex_Label("EEex::Opcode_Hook_ContingencyList_ShouldProcess")

		--------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_OnPersistantEffectAddTail() --
		--------------------------------------------------------

		-- Mark the persistent effect about to be added (rdx) from the effect being applied. rcx / rdx are the AddTail()
		-- arguments and are preserved; rax / r8-r11 are volatile and no AddTail() argument.
		for _, site in ipairs(addTailSites) do
			EEex_HookBeforeCallWithLabels(addresses[site.key], {
				{"hook_integrity_watchdog_ignore_registers", {
					EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
					EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
				}}},
				{[[
					#MAKE_SHADOW_SPACE(16)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx

					                                                      ; rdx already pPersistantEffect
					mov rcx, #$(1) ]], {site.effectRegister}, [[ #ENDL    ; pEffect
					call #L(EEex::Opcode_Hook_OnPersistantEffectAddTail)

					mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
				]]}
			)
		end

		-----------------------------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_*_AIUpdatePersistantEffects()                    --
		-----------------------------------------------------------------------------------

		-- Call the C++ reimplementation instead of CPersistantEffectListRegenerated::AIUpdate() (rcx / rdx / r8d are
		-- already its arguments). The replaced call clobbers every volatile register anyway.
		for _, site in ipairs({
			{"callProcessEffectList", "EEex::Opcode_Hook_ProcessEffectList_AIUpdatePersistantEffects"},
			{"callHandlePersistant", "EEex::Opcode_Hook_HandlePersistantEffects_AIUpdatePersistantEffects"}, })
		do
			EEex_HookBeforeCallWithLabels(addresses[site[1]], {
				{"hook_integrity_watchdog_ignore_registers", {
					EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
					EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
					EEex_HookIntegrityWatchdogRegister.R11
				}}},
				{
					"call #L("..site[2]..") ; Same arguments as the replaced call\n",
					"jmp #L(return_skip)\n",
				}
			)
		end

		---------------------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_ContingencyList_ShouldProcess() --
		---------------------------------------------------------------------

		-- On a status trigger (the `je` falls through), let EEex.dll decide whether this pass evaluates the contingency.
		-- Skipping takes the `je`'s own target (the next node).
		EEex_HookConditionalJumpOnFailWithLabels(F, 0, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
				EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
				EEex_HookIntegrityWatchdogRegister.R11
			}}},
			{[[
				mov rdx, rsi                                         ; pContingency
				mov rcx, r13                                         ; pList
				call #L(EEex::Opcode_Hook_ContingencyList_ShouldProcess)
				test al, al
				jz #L(jmp_success)                                   ; Not in this pass: skip to the next node
			]]}
		)

		--------------------------------------------------------
		-- [EEex.dll] EEex::Opcode_Hook_ContingencyCheck() --
		--------------------------------------------------------

		-- Replace CGameSprite::ContingencyCheck() entirely (same argument, same stack, no return value)
		EEex_JITAt(C, {[[
			jmp #L(EEex::Opcode_Hook_ContingencyCheck)
		]]})
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
