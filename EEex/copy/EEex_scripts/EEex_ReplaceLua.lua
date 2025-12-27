
(function()

	EEex_DisableCodeProtection()

	-------------------------------------------------------------------------------------------------------
	-- Initialize EEex.dll and replace the engine's bootstrap code to make it use the external Lua state --
	-------------------------------------------------------------------------------------------------------

	EEex_InitLuaBindings("LuaBindings-v2.6.6.0")
	EEex_InitLuaBindings("EEex")

	EEex_JITAt(EEex_Label("bootstrapLua"), {"jmp #L(EEex::Override_bootstrapLua)"})

	-----------------------------------------------------------------------------------
	-- /START Lua function redirection                                               --
	-----------------------------------------------------------------------------------
	--     Redirect in-engine Lua functions to point to the [General].LuaLibrary DLL --
	-----------------------------------------------------------------------------------

	local redirectLuaProc = function(funcName)
		EEex_JITAt(EEex_Label(funcName), {[[
			jmp ]], EEex_GetLuaLibraryProc(funcName)
		})
	end

	redirectLuaProc("lua_atpanic")
	redirectLuaProc("lua_callk")
	redirectLuaProc("lua_checkstack")
	redirectLuaProc("lua_concat")
	redirectLuaProc("lua_createtable")
	redirectLuaProc("lua_error")
	redirectLuaProc("lua_gc")
	redirectLuaProc("lua_getfield")
	redirectLuaProc("lua_getglobal")
	redirectLuaProc("lua_getinfo")
	redirectLuaProc("lua_getlocal")
	redirectLuaProc("lua_getmetatable")
	redirectLuaProc("lua_gettable")
	redirectLuaProc("lua_gettop")

	-- redirectLuaProc("lua_getuservalue") -- Only used in:
	--     lpeg library [Program Options].Cucumber mode

	redirectLuaProc("lua_insert")
	redirectLuaProc("lua_iscfunction")
	redirectLuaProc("lua_isnumber")
	redirectLuaProc("lua_isstring")
	redirectLuaProc("lua_isuserdata")
	redirectLuaProc("lua_len")
	redirectLuaProc("lua_load")
	redirectLuaProc("lua_newstate")
	redirectLuaProc("lua_newuserdata")
	redirectLuaProc("lua_next")
	redirectLuaProc("lua_pcallk")
	redirectLuaProc("lua_pushboolean")
	redirectLuaProc("lua_pushcclosure")
	redirectLuaProc("lua_pushfstring")
	redirectLuaProc("lua_pushinteger")
	redirectLuaProc("lua_pushlightuserdata")
	redirectLuaProc("lua_pushlstring")
	redirectLuaProc("lua_pushnil")
	redirectLuaProc("lua_pushnumber")
	redirectLuaProc("lua_pushstring")
	redirectLuaProc("lua_pushvalue")
	redirectLuaProc("lua_pushvfstring")
	redirectLuaProc("lua_rawequal")
	redirectLuaProc("lua_rawget")
	redirectLuaProc("lua_rawgeti")
	redirectLuaProc("lua_rawlen")
	redirectLuaProc("lua_rawset")
	redirectLuaProc("lua_rawseti")
	redirectLuaProc("lua_remove")
	redirectLuaProc("lua_resume")
	redirectLuaProc("lua_setfield")
	redirectLuaProc("lua_setglobal")
	redirectLuaProc("lua_setmetatable")
	redirectLuaProc("lua_settable")
	redirectLuaProc("lua_settop")
	redirectLuaProc("lua_setupvalue")

	-- redirectLuaProc("lua_setuservalue") -- Only used in:
	--     debug library (replaced)
	--     lpeg library ([Program Options].Cucumber mode)

	redirectLuaProc("lua_toboolean")
	redirectLuaProc("lua_tocfunction")
	redirectLuaProc("lua_tointegerx")
	redirectLuaProc("lua_tolstring")
	redirectLuaProc("lua_tonumberx")

	-- redirectLuaProc("lua_tounsignedx") -- Only used in:
	--     bit32 library (removed)
	--     luaL_setfuncs() (replaced)
	--     math library (replaced)

	redirectLuaProc("lua_touserdata")
	redirectLuaProc("lua_type")
	redirectLuaProc("lua_typename")
	redirectLuaProc("lua_xmove")
	redirectLuaProc("luaL_addlstring")
	redirectLuaProc("luaL_addstring")
	redirectLuaProc("luaL_addvalue")
	redirectLuaProc("luaL_argerror")
	redirectLuaProc("luaL_checkinteger")
	redirectLuaProc("luaL_checknumber")
	redirectLuaProc("luaL_checkudata")
	redirectLuaProc("luaL_error")
	redirectLuaProc("luaL_getmetafield")

	-- redirectLuaProc("luaL_getsubtable") -- Only used in:
	--     debug library (replaced)
	--     luaL_requiref() (removed)
	--     package library (replaced)

	redirectLuaProc("luaL_gsub")
	redirectLuaProc("luaL_len")
	redirectLuaProc("luaL_loadbufferx")
	redirectLuaProc("luaL_loadfilex")
	redirectLuaProc("luaL_loadstring")
	redirectLuaProc("luaL_newmetatable")
	redirectLuaProc("luaL_newstate")
	redirectLuaProc("luaL_optlstring")

	-- redirectLuaProc("luaL_prepbuffsize") -- Only used in:
	--     lpeg library ([Program Options].Cucumber mode)
	--     luaL_addlstring() (replaced)
	--     luaL_addstring() (replaced)
	--     luaL_addvalue() (replaced)
	--     luaL_gsub() (replaced)
	--     mime_core library ([Program Options].Cucumber mode)
	--     socket_core library ([Program Options].Cucumber mode)
	--     string library (replaced)

	redirectLuaProc("luaL_pushresult")
	redirectLuaProc("luaL_ref")

	-- redirectLuaProc("luaL_requiref") -- Only used in:
	--     bootstrapLua() (calls to luaL_requiref() removed)
	--     enableCucumberSupport() ([Program Options].Cucumber mode)

	redirectLuaProc("luaL_setfuncs")

	-- redirectLuaProc("luaL_tolstring") -- Only used in:
	--     string library (replaced)

	redirectLuaProc("luaL_traceback")
	redirectLuaProc("luaL_where")
	redirectLuaProc("luaopen_base")

	-- redirectLuaProc("luaopen_bit32") -- Removed

	-- redirectLuaProc("luaopen_coroutine") -- Only used in:
	--     enableCucumberSupport() ([Program Options].Cucumber mode)

	redirectLuaProc("luaopen_debug")
	redirectLuaProc("luaopen_math")
	redirectLuaProc("luaopen_package")
	redirectLuaProc("luaopen_string")
	redirectLuaProc("luaopen_table")

	-----------------------------------
	-- /END Lua function redirection --
	-----------------------------------

	-- Replace all inlined uses of LUA_REGISTRYINDEX = -1001000 (Lua 5.2) with LUA_REGISTRYINDEX = -10000 (LuaJIT)
	for _, address in ipairs(EEex_Label("Data-LUA_REGISTRYINDEX")) do
		EEex_Write32(address, -10000)
	end

	EEex_EnableCodeProtection()

end)()
