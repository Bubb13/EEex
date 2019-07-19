-- New thieving skills should be put in this list.
extendedskilllist = {
--[[
	-- Here's an example of a new skill entry. This code will let you increase your lore at level up if you 
	-- are a single- or multi-classed thief or a stalker, but not if you are a swashbuckler or a shadowdancer,
	-- and not if your Intelligence < 16 or your Wisdom < 14.
	{
		["stat"] = 25, --ID of the stat (either from STATS.IDS, or some big number if you're using an extended stat).
		["name"] = 9459, --Strref of the skill's name.
		["description"] = 4981, --Strref of the skill's description.
		["opcode"] = 21, --The opcode that will be used to modify the skill.
		["visibility"] = 4, --Whether the skill will appear alongside other skills in the character record screen.
						-- 0: Always show
						-- 1: Show if character can put points in skill
						-- 2: Show if skill != 0
						-- 3: Show if skill != 0 and character can put points in skill
						-- 4: Don't show
		["class_include"] = {4, 9, 10, 13, 15}, --A character with one of these classes (from CLASS.IDS) can put points in the skill.
		["kit_include"] = {0x4008}, --A character with one of these kits can put points in the skill, even if their class is not in the "class_include" list.
		["kit_exclude"] = {0x400C, 0x4021}, --A character with one of these kits cannot put points in the skill, even if their class is in the "class_include" list.
		["stat_exclude"] = {{38, 16, 2}, {39, 14, 2}} --A character cannot put points in the skill if its stats meet any of these conditions.
		                                               --The syntax is similar to a SPLPROT.2DA condition, and it accepts all the relations (0 - 11) that SPLPROT.2DA does.
		                                               
	}
--]]
}
