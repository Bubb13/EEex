-- Damage Absorption
-- This module allows creatures to effectively gain over 127 or under -128 in their resistances.
-- It also makes it so creatures' spells aren't interrupted by damage if they're immune to the damage.

ex_resistance_opcode = {
[14] = {30, 0x46D},
[15] = {28, 0x46E},
[16] = {29, 0x46F},
[17] = {27, 0x470},
[19] = {84, 0x472},
[20] = {85, 0x473},
[21] = {86, 0x474},
[22] = {87, 0x475},
[23] = {88, 0x476},
[24] = {89, 0x477},
[73] = {31, 0},
[74] = {173, 0}
}

ex_damage_resistance_base = {
[0] = 0x475,
[1] = 0x470,
[2] = 0x46E,
[4] = 0x46F,
[8] = 0x46D,
[16] = 0x476,
[128] = 0x477,
[256] = 0x474,
[512] = 0x472,
[1024] = 0x473,
[2048] = 0x475
}

function EEex_GetActorFullResistance(actorID, resistanceStat)
	if not EEex_IsSprite(actorID) or ex_resistance_opcode[resistanceStat] == nil then return 0 end
	local base_resistance = 0
	local timing_level = 0
	if ex_resistance_opcode[resistanceStat][2] ~= 0 then
		base_resistance = EEex_ReadByte(EEex_GetActorShare(actorID) + ex_resistance_opcode[resistanceStat][2], 0x0)
	end
	local extra_resistance = 0
	EEex_IterateActorEffects(actorID, function(eData)
		local the_opcode = EEex_ReadDword(eData + 0x10)
		if the_opcode == ex_resistance_opcode[resistanceStat][1] then
			local the_parameter1 = EEex_ReadDword(eData + 0x1C)
			local the_parameter2 = EEex_ReadDword(eData + 0x20)
			local the_timing = EEex_ReadDword(eData + 0x24)
			if the_parameter2 == 0 then
				extra_resistance = extra_resistance + the_parameter1
			elseif the_timing >= timing_level then
				timing_level = the_timing
				if the_parameter2 == 1 then
					base_resistance = the_parameter1
				elseif the_parameter2 == 2 then
					base_resistance = math.floor(base_resistance * the_parameter1 / 100)
				end
			end
		end
	end)
	return (base_resistance + extra_resistance)

end

function EEex_DamageAbsorption(effectData, creatureData)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local sourceID = EEex_ReadDword(effectData + 0x10C)
	local sourceData = EEex_GetActorShare(sourceID)
	local damage = EEex_ReadDword(effectData + 0x18)
	local damage_method = EEex_ReadWord(effectData + 0x1C, 0x0)
	if damage_method ~= 0 then return false end
	local damage_type = EEex_ReadWord(effectData + 0x1E, 0x0)
	local dicenumber = EEex_ReadDword(effectData + 0x34)
	local dicesize = EEex_ReadDword(effectData + 0x38)
	local normal_resistance = EEex_GetActorStat(targetID, ex_damage_types[damage_type][1])
	if (normal_resistance >= 100 and normal_resistance <= 127) or normal_resistance == -128 then
		local base_resistance = 0
		local timing_level = 0
		if ex_damage_resistance_base[damage_type] ~= nil then
			base_resistance = EEex_ReadSignedByte(creatureData + ex_damage_resistance_base[damage_type], 0x0)
		end
		local extra_resistance = 0
		EEex_IterateActorEffects(targetID, function(eData)
			local the_opcode = EEex_ReadDword(eData + 0x10)
			if the_opcode == ex_damage_types[damage_type][2] then
				local the_parameter1 = EEex_ReadDword(eData + 0x1C)
				local the_parameter2 = EEex_ReadDword(eData + 0x20)
				local the_timing = EEex_ReadDword(eData + 0x24)
				if the_parameter2 == 0 then
					extra_resistance = extra_resistance + the_parameter1
				elseif the_timing >= timing_level then
					timing_level = the_timing
					if the_parameter2 == 1 then
						base_resistance = the_parameter1
					elseif the_parameter2 == 2 then
						base_resistance = math.floor(base_resistance * the_parameter1 / 100)
					end
				end
			end
		end)
--		Infinity_DisplayString("Total Resistance: " .. base_resistance + extra_resistance)
		for i = 1, dicenumber, 1 do
			damage = damage + math.random(dicesize)
		end
--		Infinity_DisplayString("Total Damage: " .. damage)
		if (normal_resistance >= 100 and normal_resistance <= 127) then
			local healing = math.floor(damage * (base_resistance + extra_resistance - 100) / 100)
			local source_name = ""
			if EEex_IsSprite(sourceID) and targetID ~= sourceID then
				source_name = ex_damage_absorption_feedback_string_3 .. EEex_GetActorName(sourceID)
			end
	--		Infinity_DisplayString("Healing: " .. healing)
			if healing > 0 then
				Infinity_SetToken("EX_DAMABS", ex_damage_absorption_feedback_string_1 .. Infinity_FetchString(ex_damage_types[damage_type][3]) .. ex_damage_absorption_feedback_string_2 .. source_name .. ex_damage_absorption_feedback_string_4 .. healing .. ex_damage_absorption_feedback_string_5)
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 17,
["target"] = 2,
["parameter1"] = healing,
["timing"] = 1,
["source_target"] = targetID,
["source_id"] = sourceID
})
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 139,
["target"] = 2,
["parameter1"] = ex_damage_absorption_feedback_strref,
["timing"] = 1,
["source_target"] = targetID,
["source_id"] = sourceID
})
				local spellRes = EEex_ReadLString(effectData + 0x90, 8)
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 318,
["target"] = 2,
["timing"] = 0,
["resource"] = spellRes,
["source_target"] = targetID,
["source_id"] = sourceID
})
			end
			return true
		else
			damage = math.floor(damage * (((base_resistance + extra_resistance - 100) * -1) / 100) / 2.28)
			EEex_WriteDword(effectData + 0x18, damage)
			EEex_WriteDword(effectData + 0x34, 0)
			EEex_WriteDword(effectData + 0x38, 0)
			return false
		end
	end
end