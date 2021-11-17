
----------
-- Main --
----------

EEex_DoFile("EEex_Assembly")

EEex_LoadLuaBindings("LuaBindings-v2.6.6.0", function()
	EEex_Patterns = EEex_GetPatternMap()
	EEex_DoFile("EEex_LuaBindings_Patch")
end)

for k, v in pairs(EEex_Patterns) do
	--print(k.." => "..EEex_ToHex(v))
	EEex_DefineAssemblyLabel(k, v)
end

EEex_DoFile("EEex_Assembly_Patch")

EEex_DoFile("EEex_Actionbar")
EEex_DoFile("EEex_Actionbar_Patch")

EEex_DoFile("EEex_GameObject")

EEex_DoFile("EEex_Key")
EEex_DoFile("EEex_Key_Patch")

EEex_DoFile("EEex_Menu")
EEex_DoFile("EEex_Menu_Patch")

EEex_DoFile("EEex_Resource")

EEex_DoFile("EEex_Sprite")

EEex_DoFile("EEex_Utility")

EEex_Menu_AddLuaBindingsInitializedListener(function()
	EEex_DoFile("EEex_UserTypeLuaFunc")
	EEex_DoFile("EEex_UserDataGlobals")
end)
