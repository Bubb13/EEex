
(function()

	EEex_DisableCodeProtection()

	--[[
	+-------------------------------------------------------------+
	| Initialize EEex data linked to CDerivedStats instances      |
	+-------------------------------------------------------------+
	|   [EEex.dll] Stats_Hook_OnConstruct(pStats: CDerivedStats*) |
	+-------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CDerivedStats::Construct()-FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rcx, rsi                          ; pStats
			call #L(EEex::Stats_Hook_OnConstruct)
		]]}
	)

	--[[
	+------------------------------------------------------------------+
	| Clean up EEex data linked to CDerivedStats instances             |
	+------------------------------------------------------------------+
	|   [EEex.dll] EEex::Stats_Hook_OnDestruct(pStats: CDerivedStats*) |
	+------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CDerivedStats::Destruct()-FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rcx, rdi                         ; pStats
			call #L(EEex::Stats_Hook_OnDestruct)
		]]}
	)

	--[[
	+----------------------------------------------------------------+
	| Reset EEex data linked to CDerivedStats instances              |
	+----------------------------------------------------------------+
	|   [EEex.dll] EEex::Stats_Hook_OnReload(pStats: CDerivedStats*) |
	+----------------------------------------------------------------+
	--]]

	local statsReloadTemplate = function(spriteRegStr)
		return EEex_FlattenTable({
			{[[
				; Extended op346 schools are cached in sprite aux data instead of CDerivedStats, but this
				; hook runs inside native reload code, so preserve the volatile register set around the calls below.
				; This shared template now owns the shadow-space frame for every reload hook site that reuses it.
				; Keeping #MAKE_SHADOW_SPACE / #DESTROY_SHADOW_SPACE here avoids duplicating or double-freeing that
				; frame in wrapper trampolines like the special `rbx` caller below.
				#MAKE_SHADOW_SPACE(96)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r10
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r11
			]]},
			{[[
				mov rcx, #$(1) ]], {spriteRegStr}, [[ ; pSprite
				call #L(EEex::Stats_Hook_OnReload)
			]]},
			-- Vanilla op346 rows 0..11 rebuild into real CDerivedStats fields during reload. EEex rows 12..255
			-- live in sprite aux storage instead, so clear that derived cache here before the rebuilt effect state
			-- starts using it again. This handles the "same sprite, new stats state" lifetime case.
			EEex_GenLuaCall("EEex_Opcode_Hook_ClearOp346ExtendedBonuses", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], "..spriteRegStr.." #ENDL", {rspOffset}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				; Common exit path for both success and Lua-call failure: restore the volatile registers we saved
				; above so the surrounding engine reload code resumes with its expected call-clobbered state.
				mov r11, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)]
				mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)]
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	end

	local callStatsReloadRbx = {"call #$(1) #ENDL",
		{
			EEex_JITNear(EEex_FlattenTable({
				{[[
					; This helper is entered via a real CALL, so the pushed return address shifts the stack by 8 bytes.
					; Only the alignment hint stays here: statsReloadTemplate() itself allocates and destroys the
					; shared shadow-space frame, so doing that again in this trampoline would double-adjust rsp.
					#STACK_MOD(8) ; This was called, the ret ptr broke alignment
				]]},
				statsReloadTemplate("rbx"),
				{[[
					; The shared template has already restored registers and destroyed its shadow space, so this
					; trampoline only needs to return to the original caller once the `rbx`-based reload work is done.
					ret
				]]},
			})),
		},
	}

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::QuickLoad()-CDerivedStats::Reload()"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		statsReloadTemplate("rdi")
	)

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Unmarshal()-CDerivedStats::Reload()-1"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		callStatsReloadRbx
	)

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Unmarshal()-CDerivedStats::Reload()-2"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		callStatsReloadRbx
	)

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::ProcessEffectList()-CDerivedStats::Reload()"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		statsReloadTemplate("rsi")
	)

	--[[
	+-------------------------------------------------------------------------------------------------+
	| Associate EEex data linked to a CDerivedStats instance with a new CDerivedStats instance (copy) |
	+-------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Stats_Hook_OnEqu(pStats: CDerivedStats*, pOtherStats: CDerivedStats*)        |
	+-------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CDerivedStats::operator_equ()-FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			mov rdx, rsi                    ; pOtherStats
			mov rcx, r14                    ; pStats
			call #L(EEex::Stats_Hook_OnEqu)
		]]}
	)

	--[[
	+----------------------------------------------------------------------------------------------+
	| Apply bonus EEex CDerivedStats data to the regular EEex CDerivedStats data                   |
	+----------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Stats_Hook_OnPlusEqu(pStats: CDerivedStats*, pOtherStats: CDerivedStats*) |
	+----------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CDerivedStats::operator_plus_equ()-FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

			mov rdx, rdi                        ; pOtherStats
			mov rcx, rbx                        ; pStats
			call #L(EEex::Stats_Hook_OnPlusEqu)

			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	--[[
	+---------------------------------------------------------------------------------------------+
	| Allow engine to fetch extended stat values                                                  |
	+---------------------------------------------------------------------------------------------+
	|   * Extended stats are those with ids outside of the vanilla range in STATS.IDS             |
	|   * Extended stat minimums, maximums, and defaults are defined in X-STATS.2DA               |
	+---------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Stats_Hook_OnGettingUnknown(pStats: CDerivedStats*, nStatId: int) -> int |
	|       return -> The value of the extended stat                                              |
	+---------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CDerivedStats::GetAtOffset()-OutOfBoundsJmp"), 0, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE

				lea rdx, qword ptr ds:[rax+1]              ; nStatId
														   ; rcx already pStats
				call #L(EEex::Stats_Hook_OnGettingUnknown)

				#DESTROY_SHADOW_SPACE
				#MANUAL_HOOK_EXIT(0)
				ret
			]]},
		})
	)

	EEex_EnableCodeProtection()

end)()
