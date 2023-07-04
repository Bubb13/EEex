
-- This file runs when LuaPatchMode=REPLACE_INTERNAL_WITH_EXTERNAL.
-- It is used to replace in-engine Lua functions before they can
-- be used.

(function()
	-- Contains most of the code editing functions. This file is the core of EEex.
	EEex_DoFile("EEex_Assembly")
	-- Replaces the statically compiled, in-exe Lua version with LuaLibrary.
	EEex_DoFile("EEex_ReplaceLua")
end)()
