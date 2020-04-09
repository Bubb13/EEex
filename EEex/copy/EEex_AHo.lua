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
EEex_HookActionOpcodeFunctions = {}
EEex_HookActionGlobalFunctions = {}

function EEex_AddActionHook(func)
	table.insert(EEex_HookActionFunctions, func)
end

function EEex_AddActionHookOpcode(func_name, func)
	EEex_HookActionOpcodeFunctions[func_name] = func
end

function EEex_AddActionHookGlobal(func_name, func)
	EEex_HookActionGlobalFunctions[func_name] = func
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

	for _, hook in pairs(EEex_HookActionGlobalFunctions) do
		hook(actionData, actionData - 0x2F8)
	end

end

-- Here's another way you can use action hooks. If you give a creature an opcode 401 effect,
--  set parameter1 to 1, special to 999, and the resource field to "EXCOWARD" (right-click the
--  "unused" resource field in NearInfinity and select "Edit as string"), whenever the creature
--  would attack someone, they instead run away.

EEex_AddActionHookOpcode("EXCOWARD", function(originatingEffectData, actionData, creatureData)
	local actionID = EEex_GetActionID(actionData)
	if actionID == 3 or actionID == 105 or actionID == 134 then
		EEex_SetActionID(actionData, 355)
		EEex_WriteDword(actionData + 0x40, 600)
	end
end)

-- This function will make it so a character will not attack allies while berserk.

EEex_AddActionHookOpcode("EXBERSER", function(originatingEffectData, actionData, creatureData)
	local actionID = EEex_GetActionID(actionData)
	local sourceID = EEex_ReadDword(creatureData + 0x34)
	local targetID = EEex_ReadDword(actionData + 0x20)
	if actionID == 3 and EEex_CompareActorAllegiances(sourceID, targetID) == 0 and (bit32.band(EEex_ReadDword(creatureData + 0x434), 0x2) > 0 or bit32.band(EEex_ReadDword(creatureData + 0xB30), 0x2) > 0) then
		local enemyID = EEex_EvalObjectStringAsActor("NearestEnemyOf(Myself)", sourceID)
		if enemyID > 0 then
			targetID = enemyID
			EEex_WriteDword(actionData + 0x20, targetID)
		else
			EEex_SetActionID(actionData, 0)
		end
	end
end)

-- This function will make it so a creature with a fear effect will run away from enemies
--  rather than just run around randomly.

EEex_AddActionHookOpcode("EXFEAR", function(originatingEffectData, actionData, creatureData)
	local actionID = EEex_GetActionID(actionData)
	local sourceID = EEex_ReadDword(creatureData + 0x34)
	local targetID = EEex_ReadDword(actionData + 0x20)
	if actionID == 200 and (bit32.band(EEex_ReadDword(creatureData + 0x434), 0x4) > 0 or bit32.band(EEex_ReadDword(creatureData + 0xB30), 0x4) > 0) then
		local enemyID = EEex_EvalObjectStringAsActor("NearestEnemyOf(Myself)", sourceID)
		if enemyID > 0 then
			targetID = enemyID
			EEex_SetActionID(actionData, 355)
			EEex_WriteDword(actionData + 0x20, targetID)
			EEex_WriteDword(actionData + 0x40, 100)
		end
	end
end)

-- If you'd like the above two functions to simply apply to all creatures who are berserk or fearful
--  without having to give creatures opcode 401 effects, uncomment the two functions below.

--[[
EEex_AddActionHookGlobal("EXBERSER", function(actionData, creatureData)
	local actionID = EEex_GetActionID(actionData)
	local sourceID = EEex_ReadDword(creatureData + 0x34)
	local targetID = EEex_ReadDword(actionData + 0x20)
	if actionID == 3 and EEex_CompareActorAllegiances(sourceID, targetID) == 0 and (bit32.band(EEex_ReadDword(creatureData + 0x434), 0x2) > 0 or bit32.band(EEex_ReadDword(creatureData + 0xB30), 0x2) > 0) then
		local enemyID = EEex_EvalObjectStringAsActor("NearestEnemyOf(Myself)", sourceID)
		if enemyID > 0 then
			targetID = enemyID
			EEex_WriteDword(actionData + 0x20, targetID)
		else
			EEex_SetActionID(actionData, 0)
		end
	end
end)

EEex_AddActionHookGlobal("EXFEAR", function(actionData, creatureData)
	local actionID = EEex_GetActionID(actionData)
	local sourceID = EEex_ReadDword(creatureData + 0x34)
	local targetID = EEex_ReadDword(actionData + 0x20)
	if actionID == 200 and (bit32.band(EEex_ReadDword(creatureData + 0x434), 0x4) > 0 or bit32.band(EEex_ReadDword(creatureData + 0xB30), 0x4) > 0) then
		local enemyID = EEex_EvalObjectStringAsActor("NearestEnemyOf(Myself)", sourceID)
		if enemyID > 0 then
			targetID = enemyID
			EEex_SetActionID(actionData, 355)
			EEex_WriteDword(actionData + 0x20, targetID)
			EEex_WriteDword(actionData + 0x40, 100)
		end
	end
end)
--]]

-- This function doesn't modify any actions by default, but adds another option for spells.
--  If you set bit 28 of a spell's flags (offset 0x18 in a SPL file), the spell will be instantly
--  applied to the target when cast, as with the ApplySpell() action, except it will still consume
--  a spell slot.

EEex_AddActionHookGlobal("EXAPPLSP", function(actionData, creatureData)
	local actionID = EEex_GetActionID(actionData)
	local sourceID = EEex_ReadDword(creatureData + 0x34)
	if actionID == 31 then
		local spellRES = EEex_GetActorSpellRES(sourceID)
		local spellData = EEex_GetSpellData(spellRES)
		if bit32.band(EEex_ReadDword(spellData + 0x18), 0x10000000) > 0 then
			local targetID = EEex_ReadDword(actionData + 0x20)
			local targetX = EEex_ReadDword(EEex_GetActorShare(targetID) + 0x8)
			local targetY = EEex_ReadDword(EEex_GetActorShare(targetID) + 0xC)
			local casterLevel = EEex_GetActorCasterLevel(sourceID, EEex_ReadWord(spellData + 0x1C, 0x0))
			EEex_SetActionID(actionData, 147)
			EEex_WriteDword(actionData + 0x20, EEex_ReadWord(actionData + 0x40, 0x0))
			EEex_ApplyEffectToActor(targetID, {
				["opcode"] = 146,
				["target"] = 2,
				["timing"] = 1,
				["parameter1"] = casterLevel,
				["parameter2"] = 1,
				["casterlvl"] = casterLevel,
				["resource"] = spellRES,
				["source_x"] = EEex_ReadDword(creatureData + 0x8),
				["source_y"] = EEex_ReadDword(creatureData + 0xC),
				["target_x"] = targetX,
				["target_y"] = targetY,
				["source_target"] = targetID,
				["source_id"] = sourceID
			})
		end
	elseif actionID == 95 then
		local spellRES = EEex_GetActorSpellRES(sourceID)
		local spellData = EEex_GetSpellData(spellRES)
		if bit32.band(EEex_ReadDword(spellData + 0x18), 0x10000000) > 0 then
			local targetID = EEex_ReadDword(actionData + 0x20)
			local targetX = EEex_GetActionPointX(actionData)
			local targetY = EEex_GetActionPointY(actionData)
			local casterLevel = EEex_GetActorCasterLevel(sourceID, EEex_ReadWord(spellData + 0x1C, 0x0))
			EEex_SetActionID(actionData, 147)
			EEex_WriteDword(actionData + 0x20, EEex_ReadWord(actionData + 0x40, 0x0))
			EEex_ApplyEffectToActor(sourceID, {
				["opcode"] = 148,
				["target"] = 2,
				["timing"] = 1,
				["parameter1"] = casterLevel,
				["parameter2"] = 1,
				["casterlvl"] = casterLevel,
				["resource"] = spellRES,
				["source_x"] = EEex_ReadDword(creatureData + 0x8),
				["source_y"] = EEex_ReadDword(creatureData + 0xC),
				["target_x"] = targetX,
				["target_y"] = targetY,
				["source_target"] = sourceID,
				["source_id"] = sourceID
			})
		end
	end
end)

function EEex_InstallActionHook()
	
	local hookName = "EEex_HookAction"
	local hookNameAddress = EEex_Malloc(#hookName + 1)
	EEex_WriteString(hookNameAddress, hookName)

	local hookAddress = EEex_WriteAssemblyAuto({[[

		!push_all_registers

		!mov_edi_ecx
		!push_esi
		!call >CAIAction::Decode

		!push_dword ]], {hookNameAddress, 4}, [[
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

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_all_registers
		!add_esp_byte 04
		!jmp_dword >CGameSprite::SetCurrAction()_after_decode
	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(EEex_Label("CGameSprite::SetCurrAction()_decode"), {"!jmp_dword", {hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallActionHook()
