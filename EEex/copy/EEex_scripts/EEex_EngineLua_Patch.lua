
(function()

	EEex_DisableCodeProtection()

	----------------------------------------------------------------------------------------------------------------
	-- /START Lua INI handling fix                                                                                --
	----------------------------------------------------------------------------------------------------------------
	--     The engine uses a custom Lua function (luaL_loadfilexptr) to execute Baldur.lua (opened with _wfopen). --
	--     Since stdio functions have to be run within the same C runtime instance, these functions must be       --
	--     redirected when using an external Lua DLL.                                                             --
	--                                                                                                            --
	--     This redirection is being done regardless of InfinityLoader's LuaPatchMode to add a name to the Lua    --
	--     chunk, so any errors thrown while executing Baldur.lua will show the file name.                        --
	----------------------------------------------------------------------------------------------------------------

	-- Redirect the _wfopen() call in OpenIniFile()
	EEex_ReplaceCall(EEex_Label("Hook-OpenIniFile()-_wfopen()"), EEex_Label("lua_wfopen"))

	-- Redirect the luaL_loadfilexptr() call in chReadIniFile()
	EEex_HookRemoveCall(EEex_Label("Hook-chReadIniFile()-luaL_loadfilexptr()"), {[[
		mov r9, ]], EEex_WriteStringCache("Baldur.lua"), [[ #ENDL
		call #L(luaL_loadfilexnamedptr) ; Custom Lua function in LuaProvider.dll which names the chunk created from the FILE*
	]]})

	-- A unique pattern cannot be established inside chWriteInifile() - replace it entirely to redirect its fclose() call
	EEex_JITAt(EEex_Label("chWriteInifile"), {"jmp #L(EEex::Override_chWriteInifile)"})

	-- It's difficult to replace the fprintf() call in Infinity_WriteINILine() since a unique pattern can't be
	-- established for that function. The only way to patch it is to grab its address after it has been
	-- exported to Lua and replace it entirely.

	EEex_EngineLua_OnUIFunctionsLoaded = function()
		EEex_DisableCodeProtection()
		EEex_JITAt(EEex_CFuncToPtr(Infinity_WriteINILine), {[[
			jmp #L(EEex::Override_Infinity_WriteINILine)
		]]})
		EEex_EnableCodeProtection()
	end

	EEex_HookAfterCall(EEex_Label("Hook-dimmInit()-uiLoadFunctions()"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(32)
		]]},
		EEex_GenLuaCall("EEex_EngineLua_OnUIFunctionsLoaded"),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	-- Disable backup INI processing, (runs if Baldur.lua had a syntax / runtime error), to prevent crash
	-- due to the above stdio redirects for INI processing. The backup processing appears to parse
	-- Baldur.lua as the old Baldur.ini SQL format.
	EEex_ForceJump(EEex_Label("Hook-chReadIniFile()-CheckDoBackupProcessingJmp"))

	-------------------------------
	-- /END Lua INI handling fix --
	-------------------------------

	EEex_EnableCodeProtection()

end)()
