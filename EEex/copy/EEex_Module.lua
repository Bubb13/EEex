
EEex_Module_Private_EffectMenu = EEex_Options_Register("EEex_Module_EffectMenu", EEex_Options_Option.new({
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Effect Menu Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_EmptyContainer = EEex_Options_Register("EEex_Module_EmptyContainer", EEex_Options_Option.new({
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Empty Container Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_Scale = EEex_Options_Register("EEex_Module_Scale", EEex_Options_Option.new({
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Scale Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_TimeStep = EEex_Options_Register("EEex_Module_TimeStep", EEex_Options_Option.new({
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Time Step Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_Timer = EEex_Options_Register("EEex_Module_Timer", EEex_Options_Option.new({
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Timer Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Options_AddTab("EEex_Options_TRANSLATION_Modules_TabTitle", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_Module_EffectMenu",
			["label"]       = "EEex_Options_TRANSLATION_Modules_EnableEffectMenu",
			["description"] = "EEex_Options_TRANSLATION_Modules_EnableEffectMenu_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_Module_EmptyContainer",
			["label"]       = "EEex_Options_TRANSLATION_Modules_EnableEmptyContainer",
			["description"] = "EEex_Options_TRANSLATION_Modules_EnableEmptyContainer_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_Module_Scale",
			["label"]       = "EEex_Options_TRANSLATION_Modules_EnableScaleModule",
			["description"] = "EEex_Options_TRANSLATION_Modules_EnableScaleModule_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_Module_TimeStep",
			["label"]       = "EEex_Options_TRANSLATION_Modules_EnableTimeStep",
			["description"] = "EEex_Options_TRANSLATION_Modules_EnableTimeStep_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_Module_Timer",
			["label"]       = "EEex_Options_TRANSLATION_Modules_EnableTimerModule",
			["description"] = "EEex_Options_TRANSLATION_Modules_EnableTimerModule_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
	},
} end)
