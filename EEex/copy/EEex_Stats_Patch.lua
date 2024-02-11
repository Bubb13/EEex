
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
		return {[[
			mov rcx, #$(1) ]], {spriteRegStr}, [[ ; pSprite
			call #L(EEex::Stats_Hook_OnReload)
		]]}
	end

	local callStatsReloadRbx = {"call #$(1) #ENDL",
		{
			EEex_JITNear(EEex_FlattenTable({
				{[[
					#STACK_MOD(8) ; This was called, the ret ptr broke alignment
					#MAKE_SHADOW_SPACE
				]]},
				statsReloadTemplate("rbx"),
				{[[
					#DESTROY_SHADOW_SPACE
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
	+------------------------------------------------------------------------------------------------+
	| Allow engine to fetch extended stat values                                                     |
	+------------------------------------------------------------------------------------------------+
	|   * Extended stats are those with ids outside of the vanilla range in STATS.IDS                |
	|   * Extended stat minimums, maximums, and defaults are defined in X-STATS.2DA                  |
	+------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Stats_Hook_OnGettingUnknown(pStats: CDerivedStats*, nStatId: int) -> number |
	|       return -> The value of the extended stat                                                 |
	+------------------------------------------------------------------------------------------------+
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
