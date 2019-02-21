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

EEex_HookActionFunctions = {}

function EEex_AddActionHook(func)
	table.insert(EEex_HookActionFunctions, func)
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
