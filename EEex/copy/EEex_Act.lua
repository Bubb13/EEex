--[[

Installs the EEex_Lua action into the exe.
No new Lua functionality is defined in this file.

--]]

function EEex_InstallNewActions()

	EEex_DisableCodeProtection()

	------------------------
	-- EEex_Lua(S:Chunk*) --
	------------------------

	local luaActorName = "EEex_LuaActorID"
	local luaActorAddress = EEex_Malloc(#luaActorName + 1)
	EEex_WriteString(luaActorAddress, luaActorName)

	local EEex_Lua = {[[

		!push_[esi+dword] #344
		!push_[dword] *_g_lua
		; TODO: Cache Lua chunks ;
		!call >_luaL_loadstring
		!add_esp_byte 08

		!push_[esi+byte] 34
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_dword ]], {luaActorAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_setglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

	]]}

	--------------------------------
	-- EEex_MatchObject(S:Chunk*) --
	--------------------------------

	-- Define Lua global used to pass current actorID to match function
	local matchObjectGlobalName = "EEex_MatchObjectID"
	local matchObjectGlobalAddress = EEex_Malloc(#matchObjectGlobalName + 1)
	EEex_WriteString(matchObjectGlobalAddress, matchObjectGlobalName)

	-- Define Lua global used to return result from match function
	local matchObjectReturnName = "EEex_MatchObject"
	local matchObjectReturnAddress = EEex_Malloc(#matchObjectReturnName + 1)
	EEex_WriteString(matchObjectReturnAddress, matchObjectReturnName)

	-- Define assembly globals used to flag and store data about current EEex_MatchObject call
	local matchObjectString = EEex_Malloc(0x4)
	local matchObjectOverride = EEex_Malloc(0x4)
	local matchObjectOverrideRange = EEex_Malloc(0x4)
	local matchObjectDoBacklist = EEex_Malloc(0x4)
	EEex_WriteDword(matchObjectOverride, 0x0)
	EEex_WriteDword(matchObjectOverrideRange, 0x0)
	EEex_WriteDword(matchObjectDoBacklist, 0x0)

	-- Effectively disables CGameArea::GetNearest() range check when flagged
	local matchObjectRangeHookJmp = EEex_Label("CGameArea::GetNearest()_RangeHook")
	local matchObjectRangeHookDest = matchObjectRangeHookJmp + EEex_ReadByte(matchObjectRangeHookJmp, 1) + 2
	local matchObjectRangeHook = EEex_WriteAssemblyAuto({[[
		!cmp_[dword]_byte ]], {matchObjectOverrideRange, 4}, [[ 00
		!jz_dword >return
		!mov_[dword]_dword ]], {matchObjectOverrideRange, 4}, [[ #0
		!mov_ecx #7FFFFFFF
		@return
		!jmp_dword, ]], {matchObjectRangeHookDest, 4, 4},
	})
	EEex_WriteAssembly(matchObjectRangeHookJmp, {"!jmp_dword", {matchObjectRangeHook, 4, 4}, "!nop !nop !nop !nop"})

	-- Define assembly function used to call the match function,
	-- setting EEex_MatchObjectID and using EEex_MatchObject as result
	local matchObjectCallChunk = EEex_WriteAssemblyAuto({[[

		!build_stack_frame
		!push_registers

		!mov_esi_[ebp+byte] 08

		!push_[dword], ]], {matchObjectString, 4}, [[
		!push_[dword] *_g_lua
		; TODO: Cache Lua chunks ;
		!call >_luaL_loadstring
		!add_esp_byte 08

		!push_[esi+byte] 34
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_dword ]], {matchObjectGlobalAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_setglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_dword ]], {matchObjectReturnAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_toboolean
		!add_esp_byte 08

		!push_eax

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!pop_eax

		!pop_registers
		!destroy_stack_frame
		!ret_word 04 00

	]]})

	-- Override CGameArea::GetNearest()'s first CAIObjectType::OfType() call,
	-- effectively replacing it with our match function's result
	local matchObjectOfType1Call = EEex_Label("CGameArea::GetNearest()_OfTypeHook1")
	local matchObjectOfType1Hook = EEex_WriteAssemblyAuto({[[

		!cmp_[dword]_byte ]], {matchObjectOverride, 4}, [[ 00
		!jz_dword >normal

		; Clear args normally pushed for CAIObjectType::OfType() off the stack ;
		!add_esp_byte 10

		!mov_eax_[ebp+byte] D8
		!cmp_byte:[eax+byte]_byte 04 31
		!jne_dword >not_a_sprite

		!push_eax
		!call ]], {matchObjectCallChunk, 4, 4}, [[
		!jmp_dword >return

		@not_a_sprite
		!xor_eax_eax
		!jmp_dword >return

		@normal
		!call >CAIObjectType::OfType

		@return
		!jmp_dword, ]], {matchObjectOfType1Call + 0x5, 4, 4},

	})
	EEex_WriteAssembly(matchObjectOfType1Call, {"!jmp_dword", {matchObjectOfType1Hook, 4, 4}})

	-- Override CGameArea::GetNearest()'s second CAIObjectType::OfType() call,
	-- effectively replacing it with our match function's result
	local matchObjectOfType2Call = EEex_Label("CGameArea::GetNearest()_OfTypeHook2")
	local matchObjectOfType2Hook = EEex_WriteAssemblyAuto({[[

		!cmp_[dword]_byte ]], {matchObjectOverride, 4}, [[ 00
		!jz_dword >normal

		; Clear args normally pushed for CAIObjectType::OfType() off the stack ;
		!add_esp_byte 10

		!mov_eax_[ebp+byte] D8
		!cmp_byte:[eax+byte]_byte 04 31
		!jne_dword >not_a_sprite

		!push_eax
		!call ]], {matchObjectCallChunk, 4, 4}, [[
		!jmp_dword >return

		@not_a_sprite
		!xor_eax_eax
		!jmp_dword >return

		@normal
		!call >CAIObjectType::OfType

		@return
		!jmp_dword, ]], {matchObjectOfType2Call + 0x5, 4, 4},

	})
	EEex_WriteAssembly(matchObjectOfType2Call, {"!jmp_dword", {matchObjectOfType2Hook, 4, 4}})

	-- Force CGameArea::GetNearest() to consider backlist 
	-- creatures while in an EEex_MatchObject call
	local listEndJumpAddress = EEex_Label("CGameArea::GetNearest()_BacklistHook")
	local listEndJumpDest = listEndJumpAddress + EEex_ReadDword(listEndJumpAddress + 0x2) + 0x6
	local listEndHook = EEex_WriteAssemblyAuto({[[

		!push_esi

		; There's still objects to process, let CGameArea::GetNearest continue normally ;
		!jnz_dword >do_jump

		; Check if I'm forcing a backlist pass ;
		!cmp_[dword]_byte ]], {matchObjectDoBacklist, 4}, [[ 00
		!jz_dword >resume

		; Unset backlist flag so I don't go into an infinite loop when I run out of backlist objects ;
		!mov_[dword]_dword ]], {matchObjectDoBacklist, 4}, [[ #0

		; Get area's backlist node head ;
		!mov_esi_[ebp+byte] BC ; -0x44 ;
		!mov_esi_[esi+dword] #900

		; Make sure the backlist node head isn't NULL ;
		!test_esi_esi
		!jz_dword >resume

		@loop_start
		; Reserve space on stack for CGameObject ptr ;
		!sub_esp_byte 04
		!push_esp ; ptr ;
		!mov_eax_[esi+byte] 08
		!push_eax ; index ;
		!call >CGameObjectArray::GetShare
		!add_esp_byte 08
		!test_al_al
		!jnz_dword >continue_loop

		; Make sure the backlist object is a CGameSprite ;
		!mov_eax_[esp]
		!cmp_byte:[eax+byte]_byte 04 31
		!je_dword >found_sprite

		@continue_loop
		; I didn't find a sprite, continue looking ;
		!add_esp_byte 04
		!mov_esi_[esi]
		!test_esi_esi
		!jnz_dword >loop_start
		!xor_ecx_ecx
		!jmp_dword >resume

		@found_sprite
		; I found a sprite, pass back my current node to CGameArea::GetNearest via ecx ;
		!add_esp_byte 04
		!mov_ecx_esi

		@do_jump
		; I found a sprite, override jmp and force CGameArea::GetNearest to continue processing ;
		!pop_esi
		!jmp_dword ]], {listEndJumpDest, 4, 4}, [[

		@resume
		; I didn't find anything, allow CGameArea::GetNearest to resume and terminate processing ;
        !pop_esi
		!jmp_dword ]], {listEndJumpAddress + 0x6, 4, 4},

	})
	EEex_WriteAssembly(listEndJumpAddress, {"!jmp_dword", {listEndHook, 4, 4}, "!nop"})

	-- Define dummy CAIObjectType to pass to CGameArea::GetNearest(),
	-- (never actually used, as EEex_MatchObject's hook overrides type evaluation)
	local matchObjectDummyType = EEex_ParseObjectString("None")

	local EEex_MatchObject = {[[

		!push_registers

		!mov_ebx_[esi+dword] #340

		!test_ebx_dword #1
		!jnz_dword >ignoreDead_override
		!push_byte 01 ; ignoreDead ;
		!jmp_dword >nNearest
		@ignoreDead_override
		!push_byte 00 ; ignoreDead ;

		@nNearest
		!push_[esi+dword] #338

		!test_ebx_dword #2
		!jnz_dword >ignoreSleeping_override
		!push_byte 01 ; ignoreSleeping ;
		!jmp_dword >seeInvisible
		@ignoreSleeping_override
		!push_byte 00 ; ignoreSleeping ;

		@seeInvisible
		!test_ebx_dword #4
		!jnz_dword >seeInvisible_override_false
		!test_ebx_dword #8
		!jnz_dword >seeInvisible_override_true
		!mov_edx_[esi]
		!mov_ecx_esi
		!call_[edx+dword] #B4 ; CGameSprite::GetCanSeeInvisible ;
		!push_eax
		!jmp_dword >checkLOS
		@seeInvisible_override_false
		!push_byte 00 ; seeInvisible ;
		!jmp_dword >checkLOS
		@seeInvisible_override_true
		!push_byte 01 ; seeInvisible ;

		@checkLOS
		!test_ebx_dword #10
		!jnz_dword >checkLOS_override
		!push_byte 01 ; checkLOS ;
		!jmp_dword >terrainTable
		@checkLOS_override
		!push_byte 00 ; checkLOS ;

		@terrainTable
		!lea_eax_[esi+dword] #2ABD ; terrainTable ;
		!push_eax

		!test_ebx_dword #20
		!jnz_dword >range_override_manual
		!test_ebx_dword #40
		!jnz_dword >range_override_max
		!mov_edx_[esi]
		!mov_ecx_esi
		!call_[edx+dword] #94 ; CGameSprite::GetVisualRange ;
		!jmp_dword >range
		@range_override_manual
		!mov_eax_[esi+dword] #33C
		!jmp_dword >range
		@range_override_max
		; Define that I want to override range (with the max value possible) ;
		!mov_[dword]_dword ]], {matchObjectOverrideRange, 4}, [[ #1
		!xor_eax_eax
		@range
		!push_eax

		!push_dword ]], {matchObjectDummyType, 4}, [[ ; type ;
		!push_[esi+byte] 34 ; startObject ;

		!mov_ecx_[esi+byte] 14 ; this ;

		; Define the Lua chunk that I'm using to match objects ;
		!mov_eax_[esi+dword] #344
		!mov_[dword]_eax ]], {matchObjectString, 4}, [[

		; Define that I am doing an EEex_MatchObject call ;
		!mov_[dword]_dword ]], {matchObjectOverride, 4}, [[ #1

		; Define that I want to additionally check the area's backlist ;
		!mov_[dword]_dword ]], {matchObjectDoBacklist, 4}, [[ #1

		; Call the heavily-hooked function ;
		!call >CGameArea::GetNearest

		; Define that I am no longer doing an EEex_MatchObject call ;
		!mov_[dword]_dword ]], {matchObjectOverride, 4}, [[ #0

		!test_eax_eax
		!jnz_dword >set_object
		!mov_eax #FFFFFFFF ; -1 ;

		@set_object
		; Set the EEex_MatchObject scripting object to the result ;
		!mov_[dword]_eax ]], {EEex_MatchObjectAddress, 4}, [[

		!pop_registers

	]]}

	-----------------------------
	-- Action Definitions Hook --
	-----------------------------

	local hookAddress = EEex_WriteAssemblyAuto(EEex_ConcatTables({[[

		!cmp_eax_dword #1D8
		!jne_dword >473
		]], EEex_Lua, [[
		!jmp_dword >success

		@473
		!cmp_eax_dword #1D9
		!jne_dword >not_defined
		]], EEex_MatchObject, [[

		@success
		!mov_bx FF FF
		!jmp_dword >CGameAIBase::ExecuteAction()_success_label

		@not_defined
		!jmp_dword >CGameAIBase::ExecuteAction()_fail_label

	]]}))
	EEex_WriteAssembly(EEex_Label("CGameAIBase::ExecuteAction()_default_jump"), {{hookAddress, 4, 4}})

	EEex_EnableCodeProtection()

end
EEex_InstallNewActions()
