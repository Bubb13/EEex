
(function()

    EEex_DisableCodeProtection()

    EEex_HookRelativeBranch(0x1401364D6, {[[
        mov rax, #L(Hardcoded_InternalLuaState)
        jmp #L(return)
    ]]})

    local nopCall = function(address)
        EEex_JITAt(address, {[[
            #REPEAT(5,nop #ENDL)
        ]]})
    end

    nopCall(0x1401364f9)
    nopCall(0x14013650a)
    nopCall(0x140136553)
    nopCall(0x140136564)
    nopCall(0x140136584)
    nopCall(0x140136595)
    nopCall(0x1401365b5)
    nopCall(0x1401365c6)
    nopCall(0x1401365e6)
    nopCall(0x1401365f7)
    nopCall(0x140136617)
    nopCall(0x140136628)

    local redirect = function(funcName)
        EEex_JITAt(EEex_Label(funcName), {[[
            jmp ]], EEex_GetLuaLibraryProc(funcName)
        })
    end

    redirect("lua_atpanic")
    redirect("lua_callk")
    redirect("lua_checkstack")
    redirect("lua_concat")
    redirect("lua_createtable")
    redirect("lua_error")
    redirect("lua_gc")
    redirect("lua_getfield")
    redirect("lua_getglobal")
    redirect("lua_getinfo")
    redirect("lua_getlocal")
    redirect("lua_getmetatable")
    redirect("lua_gettable")
    redirect("lua_gettop")
    --redirect("lua_getuservalue")
    redirect("lua_insert")
    redirect("lua_iscfunction")
    redirect("lua_isnumber")
    redirect("lua_isstring")
    redirect("lua_isuserdata")
    redirect("lua_len")
    redirect("lua_load")
    redirect("lua_newstate")
    redirect("lua_newuserdata")
    redirect("lua_next")
    redirect("lua_pcallk")
    redirect("lua_pushboolean")
    redirect("lua_pushcclosure")
    redirect("lua_pushfstring")
    redirect("lua_pushinteger")
    redirect("lua_pushlightuserdata")
    redirect("lua_pushlstring")
    redirect("lua_pushnil")
    redirect("lua_pushnumber")
    redirect("lua_pushstring")
    redirect("lua_pushvalue")
    redirect("lua_pushvfstring")
    redirect("lua_rawequal")
    redirect("lua_rawget")
    redirect("lua_rawgeti")
    redirect("lua_rawlen")
    redirect("lua_rawset")
    redirect("lua_rawseti")
    redirect("lua_remove")
    redirect("lua_resume")
    redirect("lua_setfield")
    redirect("lua_setglobal")
    redirect("lua_setmetatable")
    redirect("lua_settable")
    redirect("lua_settop")
    redirect("lua_setupvalue")
    --redirect("lua_setuservalue")
    redirect("lua_toboolean")
    redirect("lua_tocfunction")
    redirect("lua_tointegerx")
    redirect("lua_tolstring")
    redirect("lua_tonumberx")
    --redirect("lua_tounsignedx")
    redirect("lua_touserdata")
    redirect("lua_type")
    redirect("lua_typename")
    redirect("lua_xmove")
    redirect("luaL_addlstring")
    redirect("luaL_addstring")
    redirect("luaL_addvalue")
    redirect("luaL_argerror")
    redirect("luaL_checkinteger")
    redirect("luaL_checknumber")
    redirect("luaL_checkudata")
    redirect("luaL_error")
    redirect("luaL_getmetafield")
    --redirect("luaL_getsubtable")
    redirect("luaL_gsub")
    redirect("luaL_len")
    redirect("luaL_loadbufferx")
    redirect("luaL_loadfilex")
    redirect("luaL_loadstring")
    redirect("luaL_newmetatable")
    redirect("luaL_newstate")
    redirect("luaL_optlstring")
    --redirect("luaL_prepbuffsize")
    redirect("luaL_pushresult")
    redirect("luaL_ref")
    --redirect("luaL_requiref")
    redirect("luaL_setfuncs")
    --redirect("luaL_tolstring")
    redirect("luaL_traceback")
    redirect("luaL_where")
    redirect("luaopen_base")
    --redirect("luaopen_bit32")
    --redirect("luaopen_coroutine")
    redirect("luaopen_debug")
    redirect("luaopen_math")
    redirect("luaopen_package")
    redirect("luaopen_string")
    redirect("luaopen_table")

    EEex_HookRelativeBranch(0x140408421, {[[
        call #$(1) ]], {EEex_GetLuaLibraryProc("wrapper_wfopen")}, [[ #ENDL
        jmp #L(return)
    ]]})

    EEex_HookRelativeBranch(0x1403CD696, {[[
        call #$(1) ]], {EEex_GetLuaLibraryProc("wrapper_fprintf")}, [[ #ENDL
        jmp #L(return)
    ]]})

    EEex_HookRelativeBranch(0x140408781, {[[
        call #$(1) ]], {EEex_GetLuaLibraryProc("wrapper_fclose")}, [[ #ENDL
        jmp #L(return)
    ]]})

    EEex_HookRelativeBranch(0x1404084E5, {[[
        call #$(1) ]], {EEex_GetLuaLibraryProc("luaL_loadfilexptr")}, [[ #ENDL
        jmp #L(return)
    ]]})

    for _, address in ipairs({
        0x1400d5153, 0x1400d6f8f, 0x1400d7a80, 0x1400d7c01, 0x1400d9101, 0x1400d91a7, 0x1400d93fa,0x1400d9481, 0x1400d9cf2,
        0x1400e18a9, 0x1400e1ac6, 0x1400e1c86, 0x1400e2be5, 0x1400e2d65, 0x1400e7f71, 0x1400e8028, 0x1400e9145, 0x1400e9206,
        0x1400e9d1b, 0x1400e9e13, 0x1400e9f13, 0x1400fc78c, 0x1400fff22, 0x140100059, 0x1401003b1, 0x140100432, 0x1401005a1,
        0x14010066a, 0x14010070a, 0x140111a3f, 0x140111b5b, 0x14011244b, 0x14011282d, 0x1401128a2, 0x140112bc6, 0x140112d4f,
        0x140112dc2, 0x140112f08, 0x140112f7d, 0x140112ffd, 0x140113038, 0x140113094, 0x1401130be, 0x14011311e, 0x140113187,
        0x140113255, 0x1401132f4, 0x140113394, 0x140113458, 0x140113561, 0x1401136ea, 0x140113726, 0x140113798, 0x1401138b6,
        0x140113952, 0x140113a51, 0x140113aa3, 0x140113ae2, 0x140113b50, 0x140113bbe, 0x140113be7, 0x140113c10, 0x140113c66,
        0x140113c88, 0x140113ccc, 0x140113edc, 0x14011400e, 0x14011426d, 0x140114347, 0x1403c1ed9, 0x1403c1fa4, 0x1403c20b8,
        0x1403c219b, 0x1403c2d83, 0x1403c2eb8, 0x1403c2f48, 0x1403c3018, 0x1403c3151, 0x1403c31f1, 0x1403c3689, 0x1403c379c,
        0x1403c385d, 0x1403c3921, 0x1403c3a0a, 0x1403c3cfc, 0x1403c3d8d, 0x1403c3e5c, 0x1403c450e, 0x1403c467b, 0x1403c470c,
        0x1403c479d, 0x1403c482e, 0x1403c48bf, 0x1403c4950, 0x1403c49e1, 0x1403c4a72, 0x1403c4b03, 0x1403c4c52, 0x1403c5620,
        0x1403c5719, 0x1403c5828, 0x1403c5918, 0x1403c5a2e, 0x1403c5b9e, 0x1403c5c79, 0x1403c5db1, 0x1403c602d, 0x1403c60be,
        0x1403c888d, 0x1403cb552, 0x1403cbc69, 0x1403d2863, 0x1404004d0, 0x140400505, 0x14040053a, 0x140400fd7, 0x140402a48,
        0x140403879, 0x140404564, 0x140404608})
    do
        EEex_WriteU8(address + 1, 0xF0)
        EEex_WriteU8(address + 2, 0xD8)
        EEex_WriteU8(address + 3, 0xFF)
        EEex_WriteU8(address + 4, 0xFF)
    end

    EEex_EnableCodeProtection()

end)()
