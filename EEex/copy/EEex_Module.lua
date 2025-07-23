
EEex_Module_Private_EffectMenu = EEex_Options_Register(EEex_Options_Option.new({
	["id"]              = "EEex_Module_EffectMenu",
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Effect Menu Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_EmptyContainer = EEex_Options_Register(EEex_Options_Option.new({
	["id"]              = "EEex_Module_EmptyContainer",
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Empty Container Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_Scale = EEex_Options_Register(EEex_Options_Option.new({
	["id"]              = "EEex_Module_Scale",
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Scale Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_TimeStep = EEex_Options_Register(EEex_Options_Option.new({
	["id"]              = "EEex_Module_TimeStep",
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Time Step Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Module_Private_Timer = EEex_Options_Register(EEex_Options_Option.new({
	["id"]              = "EEex_Module_Timer",
	["default"]         = 0,
	["type"]            = EEex_Options_ToggleType.new(),
	["accessor"]        = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]         = EEex_Options_NumberINIStorage.new({ ["path"] = "EEex.ini", ["section"] = "Timer Module", ["key"] = "Enable" }),
	["requiresRestart"] = true,
}))

EEex_Options_AddTab("Modules", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["name"]            = "Enable Effect Menu Module",
			["optionID"]        = "EEex_Module_EffectMenu",
			["widget"]          = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["name"]            = "Enable Empty Container Module",
			["optionID"]        = "EEex_Module_EmptyContainer",
			["widget"]          = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["name"]            = "Enable Scale Module",
			["optionID"]        = "EEex_Module_Scale",
			["widget"]          = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["name"]            = "Enable Time Step Module",
			["optionID"]        = "EEex_Module_TimeStep",
			["widget"]          = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["name"]            = "Enable Timer Module",
			["optionID"]        = "EEex_Module_Timer",
			["widget"]          = EEex_Options_ToggleWidget.new(),
		}),
	},
} end)
