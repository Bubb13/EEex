
EEex_LuaObject = -1

function EEex_InstallNewObjects()

	EEex_DisableCodeProtection()

	--------------------
	-- EEex_LuaObject --
	--------------------

	local luaObjectName = "EEex_LuaObject"
	local luaObjectAddress = EEex_Malloc(#luaObjectName + 1)
	EEex_WriteString(luaObjectAddress, luaObjectName)

	local EEex_LuaObject = {[[

		!push_dword *CAIObjectType::ANYONE
		!lea_ecx_[ebp+byte] E8
		!call >CAIObjectType::operator_equ

		!push_dword ]], {luaObjectAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse

		!mov_[ebp+byte]_eax F0 ; curType.m_Instance ;
		!push_eax

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!pop_eax

	]]}

	----------------------
	-- EEex_MatchObject --
	----------------------

	local matchObjectOffset = EEex_GetVolatileFieldOffset("EEex_MatchObject")

	local matchObjectName = "EEex_MatchObject"
	local matchObjectAddress = EEex_Malloc(#matchObjectName + 1)
	EEex_WriteString(matchObjectAddress, matchObjectName)

	local EEex_MatchObject = {[[

		!push_dword *CAIObjectType::ANYONE
		!lea_ecx_[ebp+byte] E8
		!call >CAIObjectType::operator_equ

		!mov_ecx_edi
		!call >EEex_AccessVolatileFields
		!mov_eax_[eax+dword] ]], {matchObjectOffset, 4}, [[
		!mov_[ebp+byte]_eax F0 ; curType.m_Instance ;

	]]}

	-----------------
	-- EEex_Target --
	-----------------

	-- General Lua function for setting a target on an actor
	EEex_SetTarget = function(actorID, targetName, targetID)
		local targetMap = EEex_AccessVolatileField(actorID, "EEex_Target")
		EEex_SetVariable(targetMap, targetName, targetID)
	end

	-- General Lua function for getting a target set on an actor
	EEex_GetTarget = function(actorID, targetName)
		local targetMap = EEex_AccessVolatileField(actorID, "EEex_Target")
		return EEex_FetchVariable(targetMap, targetName)
	end

	local targetObjectOffset = EEex_RegisterVolatileField("EEex_Target", {
		["construct"] = function(address)
			EEex_Call(EEex_Label("CVariableHash::CVariableHash"), {7}, address, 0x0)
		end,
		["destruct"] = function(address)
			EEex_Free(EEex_ReadDword(address))
		end,
		["get"] = function()
			EEex_Error("[EEex_Target]:get() not implemented!")
		end,
		["set"] = function()
			EEex_Error("[EEex_Target]:set() not implemented!")
		end,
		["size"] = 0x8,
	})

	local overrideTargetNameJump = EEex_Label("CAIObjectType::Decode()_NameHook")
	local overrideTargetNameJumpDest = overrideTargetNameJump + EEex_ReadDword(overrideTargetNameJump + 0x2) + 0x6
	local overrideTargetName = EEex_WriteAssemblyAuto({[[
		!je_dword ]], {overrideTargetNameJumpDest, 4, 4}, [[
		!cmp_[ebx+byte]_byte 0C 75
		!je_dword ]], {overrideTargetNameJumpDest, 4, 4}, [[
		!jmp_dword ]], {overrideTargetNameJump + 0x6, 4, 4},
	})
	EEex_WriteAssembly(overrideTargetNameJump, {"!jmp_dword", {overrideTargetName, 4, 4}, "!nop"})

	EEex_Target = function(caller, CAIObjectType)

		local targetMap = EEex_AccessVolatileField(EEex_GetActorIDShare(caller), "EEex_Target")
		local targetName = EEex_ReadString(EEex_ReadDword(CAIObjectType))

		local foundTarget = EEex_FetchVariable(targetMap, targetName)
		return foundTarget ~= 0x0 and foundTarget or -1

	end

	local EEex_TargetObj = {[[

		!push_dword ]], {EEex_WriteStringAuto("EEex_Target"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_edi
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_ebx
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_byte 02
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_byte 00
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C

		!call >__ftol2_sse
		!push_eax

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!push_dword *CAIObjectType::ANYONE
		!lea_ecx_[ebp+byte] E8
		!call >CAIObjectType::operator_equ

		!pop_eax
		!mov_[ebp+byte]_eax F0 ; curType.m_Instance ;

	]]}

	------------------------
	-- New Objects Switch --
	------------------------

	local newObjectsAddress = EEex_WriteAssemblyAuto(EEex_ConcatTables({[[

		!cmp_eax_byte 72
		!jne_dword >73
		]], EEex_LuaObject, [[
		!jmp_dword >result

		@73
		!cmp_eax_byte 73
		!jne_dword >74
		]], EEex_MatchObject, [[
		!jmp_dword >result

		@74
		!cmp_eax_byte 74
		!jne_dword >CAIObjectType::Decode()_default_label
		]], EEex_TargetObj, [[

		@result
		!cmp_eax_byte FF
		!je_dword >CAIObjectType::Decode()_fail_label
		!jmp_dword >CAIObjectType::Decode()_success_label

	]]}))
	EEex_WriteAssembly(EEex_Label("CAIObjectType::Decode()_default_jump"), {{newObjectsAddress, 4, 4}})

	EEex_EnableCodeProtection()

end
EEex_InstallNewObjects()
