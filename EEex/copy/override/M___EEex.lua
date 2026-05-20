
if not EEex_Active then
	error("[!] ERROR: EEex not active.\n\nDid you forget to start the game with InfinityLoader.exe?")
end

-- Mandatory module validity tests.
--
-- PURPOSE: Verify that the Lua standard library modules EEex depends on have not been
-- tampered with since they were snapshotted by EEex_LuaModule.lua during bootstrap.
-- Each test retrieves the module through the read-only verified proxy (which runs identity
-- and dual-oracle C-function checks on every access) and then asserts that specific
-- function members are present and genuine.
--
-- TIMING: This file runs after EEex_Main.lua has completed (i.e. after all hooks and
-- patch scripts have been installed), so any tampering introduced during the startup
-- sequence will be caught here before user-facing game code executes.
--
-- FAILURE BEHAVIOUR: Any failed test raises a hard error that halts execution. This is
-- intentional: a missing or corrupted standard library function would cause unpredictable
-- behaviour later, so it is safer to abort early with a clear message.
(function()
	-- Idempotency guard: the engine may load override scripts more than once per session.
	-- We only need to run these tests once; subsequent calls are no-ops.
	if rawget(_G, "__EEex_LuaModule_MandatoryRan") then
		return
	end
	rawset(_G, "__EEex_LuaModule_MandatoryRan", true)

	local function fail(msg)
		error("[!] ERROR: LuaModule mandatory tests: " .. msg, 0)
	end

	-- Locate the getter installed by EEex_LuaModule.lua.
	-- We try the standalone global first, then fall back to EEex.GetLuaModule.
	-- If neither is available, startup was incomplete — fail immediately.
	local getter = rawget(_G, "EEex_GetLuaModule")
	if type(getter) ~= "function" then
		if type(EEex) == "table" and type(EEex.GetLuaModule) == "function" then
			getter = EEex.GetLuaModule
		else
			fail("getter not installed; expected EEex_LuaModule.lua to run during startup")
		end
	end

	-- requireMember: assert that a specific key on the proxy is a function.
	-- Because the proxy's __index runs identity + C-oracle checks on every access,
	-- this also implicitly validates that the member is still a genuine C function.
	local function requireMember(moduleProxy, moduleName, memberName)
		local member = moduleProxy[memberName]
		if type(member) ~= "function" then
			fail("module '" .. moduleName .. "' missing function '" .. memberName .. "'")
		end
	end

	-- Runtime detection: check whether we are running under LuaJIT by probing the "jit"
	-- global, which LuaJIT always exposes with a "version" string field.
	-- This determines which bit-manipulation module to test:
	--   LuaJIT provides "bit"   (Mike Pall's bitop library, compatible with Lua 5.1 semantics)
	--   Lua 5.2 provides "bit32" (standard library introduced in 5.2)
	local isLuaJIT = type(rawget(_G, "jit")) == "table"
		and type(rawget(rawget(_G, "jit"), "version")) == "string"

	-- Module expectation table.
	-- Each entry: { name = <module name>, required = { <function names...> } }
	-- The listed functions are the minimum set that EEex relies on being genuine C functions.
	local moduleExpectations = {
		-- debug: used for stack introspection and the dual-oracle trust chain itself.
		{ name = "debug",  required = { "getinfo", "traceback", "getupvalue" } },
		-- math: used pervasively for numeric operations.
		{ name = "math",   required = { "abs", "floor", "ceil", "max", "min", "random", "randomseed", "sqrt", "acos" } },
		-- string: used for text processing; string.dump is Oracle 1 in the trust chain.
		{ name = "string", required = { "byte", "char", "dump", "find", "format", "gsub", "sub", "match", "len", "lower", "upper" } },
		-- table: used for list and map operations throughout EEex.
		{ name = "table",  required = { "concat", "insert", "remove", "sort" } },
		-- io: used for file stream operations (open/read/write/close) in scripts that interact with disk.
		-- Optional (disabled by default): only the bit32, debug, math, string, and table modules are normally available.
		-- Uncomment if you want startup to fail when core io APIs are unavailable or tampered.
		-- { name = "io",    required = { "open", "close", "read", "write" } },
		-- os: used for runtime clock/time/date utilities and environment-level operations.
		-- Optional (disabled by default): only the bit32, debug, math, string, and table modules are normally available.
		-- Uncomment if you require strict validation of core os APIs at startup.
		-- { name = "os",    required = { "clock", "date", "difftime", "time" } },
	}

	if isLuaJIT then
		-- bit: LuaJIT's bitwise operations library (replaces bit32 from Lua 5.2).
		moduleExpectations[#moduleExpectations + 1] = { name = "bit",  required = { "band", "bor", "bxor", "lshift", "rshift" } }
		-- jit: LuaJIT control API; "status" confirms the JIT compiler is operational.
		moduleExpectations[#moduleExpectations + 1] = { name = "jit",  required = { "status" } }
	else
		-- bit32: Lua 5.2 standard bitwise operations library.
		moduleExpectations[#moduleExpectations + 1] = { name = "bit32", required = { "band", "bor", "bxor", "lshift", "rshift" } }
	end

	-- Run all tests. getLuaModule performs snapshot + identity + C-oracle checks internally;
	-- requireMember then confirms that each listed function is accessible and function-typed.
	for _, expectation in ipairs(moduleExpectations) do
		local moduleProxy = getter(expectation.name)
		if type(moduleProxy) ~= "table" then
			fail("module '" .. expectation.name .. "' did not return a proxy table")
		end
		for _, memberName in ipairs(expectation.required) do
			requireMember(moduleProxy, expectation.name, memberName)
		end
	end
end)()
