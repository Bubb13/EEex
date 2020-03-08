--[[

The following function is an example of how a modder could use this file's
hook to dynamically transform an actor-targeted spell into a point-targeted
one instead. (Put the following function either in UI.MENU or a M_*.lua)

function B3SpellToPoint(actorID)
	EEex_AddActionHook(function(actionData)
		local spellActions = {
			[31]  = 95 , -- Spell => SpellPoint
			[113] = 114, -- ForceSpell => ForceSpellPoint
			[181] = 337, -- ReallyForceSpell => ReallyForceSpellPoint
			[191] = 192, -- SpellNoDec => SpellPointNoDec
		}
		local newActionID = spellActions[EEex_GetActionID(actionData)]
		if newActionID then
			EEex_SetActionID(actionData, newActionID)
			local targetID = EEex_GetActionTarget(actionData)
			local targetX, targetY = EEex_GetActorLocation(targetID)
			EEex_SetActionPointX(actionData, targetX)
			EEex_SetActionPointY(actionData, targetY)
		end
	end)
end

Used from a script like so:

EEex_Lua("B3SpellToPoint")
SpellNoDecRES("SPWI304",Player1)

--]]

-- Here's another way you can use action hooks. If you give a creature an opcode 401 effect,
--  set parameter1 to 1, special to 999, and the resource field to "EXCOWARD" (right-click the
--  "unused" resource field in NearInfinity and select "Edit as string"), whenever the creature
--  would attack someone, they instead run away.

EEex_AddActionOpcodeHook("EXCOWARD", function(originatingEffectData, actionData, creatureData)
	local actionID = EEex_GetActionID(actionData)
	if actionID == 3 or actionID == 105 or actionID == 134 then
		EEex_SetActionID(actionData, 355)
		EEex_WriteDword(actionData + 0x40, 600)
	end
end)

EEex_HookActionFunctions = {}
EEex_HookActionOpcodeFunctions = {}

function EEex_AddActionHook(func)
	table.insert(EEex_HookActionFunctions, func)
end

function EEex_AddActionHookOpcode(func_name, func)
	EEex_HookActionOpcodeFunctions[func_name] = func
end

function EEex_GetActionID(actionData)
	return EEex_ReadWord(actionData, 0)
end

function EEex_SetActionID(actionData, newID)
	return EEex_WriteWord(actionData, newID)
end

function EEex_GetActionTarget(actionData)
	return EEex_ReadDword(actionData + 0x20)
end

function EEex_SetActionTarget(actionData, newTarget)
	return EEex_WriteDword(actionData + 0x20, newTarget)
end

function EEex_GetActionParameter2(actionData)
	return EEex_ReadDword(actionData + 0x40)
end

function EEex_SetActionParameter2(actionData, newParameter2)
	return EEex_WriteDword(actionData + 0x40, newParameter2)
end

function EEex_GetActionString1(actionData)
	return EEex_ReadDword(actionData + 0x4C)
end

function EEex_SetActionString1(actionData, newString1)
	return EEex_WriteDword(actionData + 0x4C, newString1)
end

function EEex_GetActionPointX(actionData)
	return EEex_ReadDword(actionData + 0x54)
end

function EEex_SetActionPointX(actionData, newX)
	return EEex_WriteDword(actionData + 0x54, newX)
end

function EEex_GetActionPointY(actionData)
	return EEex_ReadDword(actionData + 0x58)
end

function EEex_SetActionPointY(actionData, newY)
	return EEex_WriteDword(actionData + 0x58, newY)
end

function EEex_HookAction(actionData)
	local hooksCopy = EEex_HookActionFunctions
	EEex_HookActionFunctions = {}
	for _, hook in ipairs(hooksCopy) do
		hook(actionData)
	end
	
	local actorID = EEex_ReadDword(actionData - 0x2C4)
	if actorID > 0 and EEex_GetActorStat(actorID, 999) > 0 then
		EEex_IterateActorEffects(actorID, function(eData)
			local opcode = EEex_ReadDword(eData + 0x10)
			local parameter1 = EEex_ReadDword(eData + 0x1C)
			local stat = EEex_ReadDword(eData + 0x48)
			if opcode == 401 and parameter1 > 0 and stat == 999 then
				local func_name = EEex_ReadLString(eData + 0x30, 8)
				if EEex_HookActionOpcodeFunctions[func_name] ~= nil then
					EEex_HookActionOpcodeFunctions[func_name](eData - 0x4, actionData, actionData - 0x2F8)
				end
			end
		end)
	end
end

function EEex_InstallActionHook()
	local hookName = "EEex_HookAction"
	local hookNameAddress = EEex_Malloc(#hookName + 1)
	EEex_WriteString(hookNameAddress, hookName)

	local hookAddress = EEex_WriteAssemblyAuto({[[
		!push_[esp]
		!mov_[esp+byte]_ecx 04
		!call >CAIAction::Decode

		!push_dword ]], {hookNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!jmp_dword >CGameSprite::SetCurrAction()_after_decode
	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(EEex_Label("CGameSprite::SetCurrAction()_decode"), {"!jmp_dword", {hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallActionHook()
