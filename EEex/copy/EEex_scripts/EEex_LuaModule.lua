-- Lua-only module provider.
-- Exposes: EEex.GetLuaModule(moduleName) and EEex_GetLuaModule(moduleName).
--
-- MUST be loaded AFTER the active Lua runtime is in place:
--   - In the EarlyMain path (LuaJIT): after EEex_ReplaceLua, so that string.dump and debug.getinfo
--     are those of the external LuaJIT runtime, not the in-engine Lua that is being replaced.
--   - In the Main path (internal Lua 5.2): after EEex_OpenLuaBindings("EEex"), so that the EEex
--     global table already exists when we try to bind EEex.GetLuaModule.
--
-- LIMITATION: Everything here executes inside the same Lua state as untrusted code.
--   It cannot create true privilege separation — an attacker with access to the Lua state
--   and native APIs could still bypass these checks. The goal is detection, not prevention.

(function()
	-- ── 0. Bedrock capture ──────────────────────────────────────────────────────────────────────
	-- Capture all primitives we depend on as upvalues right now, before anything else runs.
	-- Using direct upvalue references (not _G lookups) means later code cannot shadow these by
	-- replacing the global "rawget", "pcall", etc. after this closure is created.
	local _G_local = _G
	local _type = type
	local _pairs = pairs
	local _ipairs = ipairs
	local _next = next
	local _rawget = rawget
	local _rawset = rawset
	local _setmetatable = setmetatable
	local _error = error
	local _pcall = pcall
	local _tostring = tostring

	local function fail(msg)
		_error("[EEex] LuaModule: " .. msg, 0)
	end

	-- ── 1. Re-installation guard ─────────────────────────────────────────────────────────────────
	-- This file may be executed twice: once in EarlyMain (before EEex table exists) and once in
	-- Main (after EEex table exists, so we can bind EEex.GetLuaModule).
	-- On the second run the trust chain is already built; we only need to re-export the getter
	-- into any globals that may now be available (e.g. EEex table).
	local existingGetter = _rawget(_G_local, "__EEex_LuaModule_Getter")
	if _type(existingGetter) == "function" then
		-- Re-export the already-built getter to the well-known global name.
		_rawset(_G_local, "EEex_GetLuaModule", existingGetter)
		-- If the EEex table is now available, bind EEex.GetLuaModule as well.
		local eeexTable = _rawget(_G_local, "EEex")
		if _type(eeexTable) == "table" then
			eeexTable.GetLuaModule = existingGetter
		end
		return
	end

	-- ── 2. Module lookup helpers ─────────────────────────────────────────────────────────────────
	-- We never read module tables via plain _G["string"] etc., because the global table is the
	-- first thing an attacker would override. package.loaded is the canonical runtime registry
	-- where the VM stores genuinely loaded modules, and we bypass its __index with rawget.
	local packageModule = _rawget(_G_local, "package")
	local loadedTable = _type(packageModule) == "table" and _rawget(packageModule, "loaded") or nil

	local function fromLoaded(moduleName)
		-- rawget on loadedTable bypasses any hostile __index metamethod on the table itself.
		return _type(loadedTable) == "table" and _rawget(loadedTable, moduleName) or nil
	end

	local function rawModuleByName(moduleName)
		-- Prefer package.loaded; fall back to a rawget on _G only if not found there.
		-- The _G fallback handles built-ins (e.g. math, string) that some runtimes register
		-- both in package.loaded and as globals.
		local fromPkg = fromLoaded(moduleName)
		if fromPkg ~= nil then
			return fromPkg
		end
		return _rawget(_G_local, moduleName)
	end

	-- Runtime mode: keep strict snapshot enforcement on stock Lua 5.2, but relax it on LuaJIT.
	-- LuaJIT may expose legitimate standard-library helpers implemented in Lua (e.g. math.deg),
	-- so requiring every function member to be C would produce false positives there.
	local jitModule = _rawget(_G_local, "jit")
	local isLuaJIT = _type(jitModule) == "table" and _type(_rawget(jitModule, "version")) == "string"
	local strictAllFunctionsMustBeC = not isLuaJIT

	-- ── 3. Oracle 1: string.dump ─────────────────────────────────────────────────────────────────
	-- string.dump is our first verification oracle. It exploits a fundamental Lua VM property:
	-- genuine C functions cannot be serialized to bytecode, so string.dump will always ERROR on them.
	-- A Lua function masquerading as a C function will instead SUCCEED and return its bytecode.
	--
	-- Self-verification: apply string.dump to itself.
	--   If it errors  → string.dump is a genuine C function. Good.
	--   If it succeeds → string.dump is a Lua impostor. Fail immediately.
	local stringModule = rawModuleByName("string")
	local stringDump = _type(stringModule) == "table" and _rawget(stringModule, "dump") or nil
	if _type(stringDump) ~= "function" then
		fail("trust chain failed: string.dump unavailable")
	end
	if _pcall(stringDump, stringDump) then
		-- pcall returned true → string.dump succeeded on itself → it is a Lua function, not C.
		fail("trust chain failed: string.dump is a Lua impostor")
	end

	-- ── 4. Oracle 2: debug.getinfo ───────────────────────────────────────────────────────────────
	-- debug.getinfo is our second verification oracle. Its "S" query returns a table with a
	-- "what" field: "C" for native functions, "Lua" for scripted functions.
	-- We first verify debug.getinfo itself with Oracle 1 before trusting any result it returns.
	local debugModule = rawModuleByName("debug")
	local debugGetInfo = _type(debugModule) == "table" and _rawget(debugModule, "getinfo") or nil
	if _type(debugGetInfo) ~= "function" then
		fail("trust chain failed: debug.getinfo unavailable")
	end
	if _pcall(stringDump, debugGetInfo) then
		-- string.dump succeeded on debug.getinfo → it is a Lua function, not C.
		fail("trust chain failed: debug.getinfo is a Lua impostor")
	end

	-- ── 5. Cross-verification: Oracle 2 confirms Oracle 1 ───────────────────────────────────────
	-- Ask debug.getinfo whether string.dump reports itself as a C function.
	-- This closes the trust loop: each oracle independently vouches for the other.
	-- An attacker would have to compromise BOTH oracles simultaneously and consistently,
	-- which is not achievable from pure Lua code.
	local dumpInfo = debugGetInfo(stringDump, "S")
	if _type(dumpInfo) ~= "table" or _rawget(dumpInfo, "what") ~= "C" then
		fail("trust chain failed: string.dump fails debug.getinfo cross-check")
	end

	-- ── 6. Dual-oracle predicate ─────────────────────────────────────────────────────────────────
	-- The core verification primitive used throughout the rest of this module.
	-- Both oracles must independently agree that a function is a genuine C function.
	-- A fake that defeats one oracle will be caught by the other.
	--
	-- LIMITATION: this checks C-vs-Lua classification and per-call identity, but cannot attest
	-- the actual machine-code address (i.e. which native symbol a C function points to).
	local function isCFunction(value)
		if _type(value) ~= "function" then
			return false, "not a function"
		end
		-- Oracle 1: string.dump must fail (C functions are not serializable).
		if _pcall(stringDump, value) then
			return false, "string.dump succeeded"
		end
		-- Oracle 2: debug.getinfo must report what == "C".
		local info = debugGetInfo(value, "S")
		if _type(info) ~= "table" then
			return false, "debug.getinfo returned nil"
		end
		if _rawget(info, "what") ~= "C" then
			return false, "debug.getinfo what=" .. _tostring(_rawget(info, "what"))
		end
		return true
	end

	local function assertCFunction(value, name)
		local ok, reason = isCFunction(value)
		if not ok then
			fail("trust chain failed: " .. name .. ": " .. reason)
		end
	end

	-- ── 7. Retroactive verification of bootstrap primitives ─────────────────────────────────────
	-- The oracles are now trusted. Use them to verify the primitives captured in step 0,
	-- which we had to accept blindly until now.
	-- If any of them are Lua impostors, every check we ran above was potentially tainted,
	-- so we fail hard rather than silently continuing with a corrupted trust base.
	-- Note: _G_local is intentionally not checked here because it is a table, not a function.
	assertCFunction(_type, "type")
	assertCFunction(_pairs, "pairs")
	assertCFunction(_ipairs, "ipairs")
	assertCFunction(_next, "next")
	assertCFunction(_rawget, "rawget")
	assertCFunction(_rawset, "rawset")
	assertCFunction(_setmetatable, "setmetatable")
	assertCFunction(_error, "error")
	assertCFunction(_pcall, "pcall")
	assertCFunction(_tostring, "tostring")

	-- ── 8. Persistent state ──────────────────────────────────────────────────────────────────────
	-- Store snapshots and proxy objects in a global table so that the re-installation path
	-- (step 1 above) can reuse them without rebuilding everything from scratch.
	local STATE_KEY = "__EEex_LuaModule_State"
	local state = _rawget(_G_local, STATE_KEY)
	if _type(state) ~= "table" then
		state = {
			moduleSnapshots = {}, -- keyed by module name; holds expected member values and C flags
			proxyCache = {},      -- keyed by module name; holds the read-only proxy objects
		}
		_rawset(_G_local, STATE_KEY, state)
	end

	-- ── 9. Module snapshot ───────────────────────────────────────────────────────────────────────
	-- Capture a point-in-time snapshot of a module's members.
	-- For each function member, we record whether it was a genuine C function at snapshot time.
	-- In strict mode (non-LuaJIT), any Lua function member is rejected immediately.
	-- In LuaJIT mode, Lua function members are tolerated to avoid false positives.
	-- Required-member enforcement remains strict in validateRequiredMembers() in both modes.
	-- Non-function members (e.g. math.pi) are captured as-is without C verification.
	-- Snapshots are cached; the first call for a given module name wins.
	local function snapshotModule(moduleName)
		local cached = state.moduleSnapshots[moduleName]
		if cached ~= nil then
			return cached
		end

		local module = rawModuleByName(moduleName)
		if _type(module) ~= "table" then
			fail("module '" .. moduleName .. "' is missing or is not a table")
		end

		local expected = {}            -- maps memberName -> value at snapshot time
		local expectedFunctionIsC = {} -- set of memberNames that were verified as C at snapshot time
		for memberName, memberValue in _pairs(module) do
			expected[memberName] = memberValue
			if _type(memberValue) == "function" then
				-- Record C-ness for each function member and optionally enforce strict mode.
				local ok, reason = isCFunction(memberValue)
				if ok then
					expectedFunctionIsC[memberName] = true
				elseif strictAllFunctionsMustBeC then
					fail("module '" .. moduleName .. "' member '" .. _tostring(memberName) .. "' not trusted: " .. reason)
				end
			end
		end

		local snapshot = {
			name = moduleName,
			module = module,          -- reference to the live module table (used for drift detection)
			expected = expected,
			expectedFunctionIsC = expectedFunctionIsC,
		}
		state.moduleSnapshots[moduleName] = snapshot
		return snapshot
	end

	-- ── 10. Required-member validation ──────────────────────────────────────────────────────────
	-- Called when the caller passes a requiredMembers list to getLuaModule.
	-- Each listed member must exist in the snapshot AND be a verified C function.
	local function validateRequiredMembers(snapshot, requiredMembers)
		if requiredMembers == nil then
			return
		end
		if _type(requiredMembers) ~= "table" then
			fail("arg 2 (requiredMembers) must be a table or nil")
		end
		for _, memberName in _ipairs(requiredMembers) do
			if _type(memberName) ~= "string" then
				fail("arg 2 (requiredMembers) must only contain strings")
			end
			local expectedValue = snapshot.expected[memberName]
			-- The member must be present and must be a function; non-function members cannot be
			-- meaningfully "required" in the C-function sense.
			if _type(expectedValue) ~= "function" then
				fail("module '" .. snapshot.name .. "' missing required function '" .. memberName .. "'")
			end
			-- Double-check C-ness even if snapshot already recorded it; belt-and-suspenders.
			local ok, reason = isCFunction(expectedValue)
			if not ok then
				fail("module '" .. snapshot.name .. "' required function '" .. memberName .. "' is not trusted: " .. reason)
			end
		end
	end

	-- ── 11. Read-only proxy ──────────────────────────────────────────────────────────────────────
	-- The proxy is what callers receive. It is a plain empty table with a locked metatable.
	-- All reads go through __index which enforces two invariants on every access:
	--   (a) Identity:  the live value in the module table must be the same object as in the snapshot.
	--   (b) C-ness:    if the member was a C function at snapshot time, it must still pass isCFunction.
	-- Writes are always rejected via __newindex.
	-- __metatable = false prevents getmetatable() from exposing the metatable to untrusted code.
	--
	-- LIMITATION: the proxy cannot stop code that bypasses it entirely (e.g. rawset on the original
	-- module table). Drift is only detected at access time, not at write time.
	local function makeReadOnlyProxy(snapshot)
		local cached = state.proxyCache[snapshot.name]
		if cached ~= nil then
			return cached
		end

		local proxy = {}
		local mt = {
			__index = function(_, key)
				local expectedValue = snapshot.expected[key]
				if expectedValue == nil then
					-- Key was not present at snapshot time; return nil rather than forwarding
					-- to the live table, which may have had members injected since.
					return nil
				end

				-- Identity check: verify the live module still holds the exact same value.
				-- Catches simple replacement attacks (e.g. string.format = evil_func).
				local currentValue = _rawget(snapshot.module, key)
				if currentValue ~= expectedValue then
					fail("module '" .. snapshot.name .. "' member '" .. _tostring(key) .. "' was modified")
				end

				-- C-function check: re-run the dual-oracle test on every access for function members.
				-- This catches cases where the value identity is preserved (same object reference)
				-- but the function's implementation was patched at the C level (very unlikely from
				-- pure Lua, but included for completeness).
				if snapshot.expectedFunctionIsC[key] then
					local ok, reason = isCFunction(currentValue)
					if not ok then
						fail("module '" .. snapshot.name .. "' member '" .. _tostring(key) .. "' is compromised: " .. reason)
					end
				end

				return expectedValue
			end,
			__newindex = function(_, key, _)
				-- Any write attempt through the proxy is unconditionally rejected.
				fail("cannot assign member '" .. _tostring(key) .. "' on read-only proxy for module '" .. snapshot.name .. "'")
			end,
			__pairs = function()
				-- Iterate over snapshot keys (not the live table) to avoid exposing injected members.
				local key
				return function()
					key = _next(snapshot.expected, key)
					if key == nil then
						return nil
					end
					-- Read through the proxy's own __index so that all access-time checks run.
					return key, proxy[key]
				end
			end,
			-- Prevent untrusted code from retrieving this metatable via getmetatable().
			__metatable = false,
		}

		_setmetatable(proxy, mt)
		state.proxyCache[snapshot.name] = proxy
		return proxy
	end

	-- ── 12. Public API: getLuaModule ─────────────────────────────────────────────────────────────
	-- Parameters:
	--   moduleName    (string)   – name of the module to retrieve
	--   requiredMembers (table?) – optional list of function names that must exist and be C
	--   functionalTest  (func?)  – optional callback(proxy) called via pcall; failure aborts
	local function getLuaModule(moduleName, requiredMembers, functionalTest)
		if _type(moduleName) ~= "string" then
			fail("arg 1 (moduleName) must be a string")
		end

		-- Take (or retrieve) the snapshot for this module, verifying all function members.
		local snapshot = snapshotModule(moduleName)

		-- If the caller specified required members, check them before returning the proxy.
		validateRequiredMembers(snapshot, requiredMembers)

		-- Build (or retrieve from cache) the read-only proxy.
		local proxy = makeReadOnlyProxy(snapshot)

		-- If the caller provided a functional test, run it now via pcall so that any error is
		-- wrapped with context rather than propagating as a raw Lua error.
		if functionalTest ~= nil then
			if _type(functionalTest) ~= "function" then
				fail("arg 3 (functionalTest) must be a function or nil")
			end
			local ok, err = _pcall(functionalTest, proxy)
			if not ok then
				fail("functional test failed for module '" .. moduleName .. "': " .. _tostring(err))
			end
		end

		return proxy
	end

	-- ── 13. Export ───────────────────────────────────────────────────────────────────────────────
	-- Store the getter under a private key so the re-installation guard (step 1) can recover it.
	_rawset(_G_local, "__EEex_LuaModule_Getter", getLuaModule)
	-- Expose as a standalone global for scripts that do not use the EEex table.
	_rawset(_G_local, "EEex_GetLuaModule", getLuaModule)
	-- Bind onto the EEex table if it already exists (it will if we are running in the Main path).
	-- In the EarlyMain path the EEex table does not exist yet; the re-installation guard in step 1
	-- will bind it when EEex_LuaModule.lua is loaded a second time from EEex_Main.lua.
	local eeexTable = _rawget(_G_local, "EEex")
	if _type(eeexTable) == "table" then
		eeexTable.GetLuaModule = getLuaModule
	end
end)()
