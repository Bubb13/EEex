
-- This is the early startup file for EEex. InfinityLoader calls this file before the game is
-- resumed when [General].LuaPatchMode = REPLACE_INTERNAL_WITH_EXTERNAL. This file replaces
-- in-engine Lua functions before they are used.

(function()
	-- Contains most of the code editing functions. This file is the core of EEex.
	EEex_DoFile("EEex_Assembly")
	EEex_DoFile("EEex_Assembly_Patch")
	-- Replaces the statically compiled, in-exe Lua version with LuaLibrary.
	EEex_DoFile("EEex_ReplaceLua")
end)()
