
(function()

	EEex_DisableCodeProtection()

	local EEex_Marshal_Patch_Private_VolatileRegisterIgnores = {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX,
			EEex_HookIntegrityWatchdogRegister.RCX,
			EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11,
		}},
	}

	local EEex_Marshal_Patch_Private_EntryStackVolatileRegisterIgnores = EEex_FlattenTable({
		{{"stack_mod", 8}},
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
	})

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameArea::Marshal(unsigned char**,unsigned int*,unsigned char)-FirstInstruction"), 0, 8, 8,
		EEex_Marshal_Patch_Private_EntryStackVolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(40)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9

			call #L(EEex::UDAux_Hook_OnBeforeAreaMarshal)

			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameArea::Marshal(unsigned char**,unsigned int*,unsigned char)-AfterMarshal"), 0, 8, 8,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			call #L(EEex::UDAux_Hook_OnAfterAreaMarshal)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameContainer::Marshal(SAreaFileWrapper*)-FirstInstruction"), 0, 5, 5,
		EEex_Marshal_Patch_Private_EntryStackVolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(40)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9

			call #L(EEex::UDAux_Hook_OnAreaContainerMarshal)

			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameArea::Unmarshal(unsigned char*,unsigned int,unsigned char)-FirstInstruction"), 0, 8, 8,
		EEex_Marshal_Patch_Private_EntryStackVolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(40)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9

			call #L(EEex::UDAux_Hook_OnBeforeAreaUnmarshal)

			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameArea::Unmarshal(unsigned char*,unsigned int,unsigned char)-AfterUnmarshal"), 0, 8, 8,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov ecx, r12d
			call #L(EEex::UDAux_Hook_OnAfterAreaUnmarshal)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameContainer::CGameContainer(CGameArea*,CAreaFileContainer*,...)-AfterConstruct"), 0, 7, 7,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov rcx, r13
			call #L(EEex::UDAux_Hook_OnAfterAreaContainerConstruct)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_EnableCodeProtection()

end)()
