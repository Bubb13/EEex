
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

	-- rcx = CGameArea*, rdx = unsigned char**, r8 = unsigned int*, r9b = version.
	-- Start a per-area UDAux collection before vanilla container marshal callbacks fire.
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

	-- The vanilla blob has been allocated and sized; append the X-UDA1.0 extension now.
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameArea::Marshal(unsigned char**,unsigned int*,unsigned char)-AfterMarshal"), 0, 8, 8,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			call #L(EEex::UDAux_Hook_OnAfterAreaMarshal)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- Container marshal order is the stable save ordinal used by the area UDAux payload.
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

	-- Parse X-UDA1.0 before vanilla unmarshal constructs CGameContainer instances.
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

	-- r12d holds the CGameArea::Unmarshal result at this epilogue path.
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameArea::Unmarshal(unsigned char*,unsigned int,unsigned char)-AfterUnmarshal"), 0, 8, 8,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov ecx, r12d
			call #L(EEex::UDAux_Hook_OnAfterAreaUnmarshal)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- r13 is the newly constructed CGameContainer; its item list has been populated.
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameContainer::CGameContainer(CGameArea*,CAreaFileContainer*,...)-AfterConstruct"), 0, 7, 7,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov rcx, r13
			call #L(EEex::UDAux_Hook_OnAfterAreaContainerConstruct)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- rcx = CStore*. Delete item aux before the destructor drains m_lInventory.
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CStore::~CStore()-FirstInstruction"), 0, 5, 5,
		EEex_Marshal_Patch_Private_EntryStackVolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

			call #L(EEex::UDAux_Hook_OnBeforeStoreInventoryClear)

			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- At this call: rcx = CRes*, rdx = marshalled STO buffer, r8d = size, rsi = CStore*.
	-- The hook may replace rdx/r8d with a buffer containing the X-UDS1.0 payload.
	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CStore::Marshal()-dimmServiceFromMemory"),
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(24)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], r9
			mov dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-20)], r8d

			mov rcx, rsi
			lea r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-20)]
			call #L(EEex::UDAux_Hook_OnStoreMarshalData)

			mov rdx, rax
			mov r8d, dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-20)]
			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- rbx = CStore*. Existing runtime CStoreFileItem nodes are about to be freed.
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CStore::SetResRef(CResRef const&)-BeforeInventoryClear"), 0, 7, 7,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov rcx, rbx
			call #L(EEex::UDAux_Hook_OnBeforeStoreInventoryClear)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- rbx = CStore*, rdi = demanded raw STO data, [rsp+20h] = CResStore* helper.
	-- Import only records aux data here; runtime item pointers do not exist yet.
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CStore::SetResRef(CResRef const&)-BeforeHeaderRead"), 0, 10, 10,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			mov r8, qword ptr ss:[rsp+20h]
			#MAKE_SHADOW_SPACE(8)
			mov rcx, rbx
			mov rdx, rdi
			call #L(EEex::UDAux_Hook_OnBeforeStoreLoad)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	-- rbx still names the CStore after inventory/drink/spell arrays are rebuilt.
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CStore::SetResRef(CResRef const&)-AfterInventoryPopulate"), 0, 6, 6,
		EEex_Marshal_Patch_Private_VolatileRegisterIgnores,
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov rcx, rbx
			call #L(EEex::UDAux_Hook_OnAfterStoreLoad)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_EnableCodeProtection()

end)()
