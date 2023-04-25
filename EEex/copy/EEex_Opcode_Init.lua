
EEex_Opcode_Temp_TrivialOnConstruct = function(self, stats, aux)
	aux[self.name] = {}
end

EEex_Opcode_Temp_TrivialOnReload = function(self, stats, aux, sprite)
	aux[self.name] = {}
end

EEex_Opcode_Temp_TrivialOnEqu = function(self, stats, aux, otherStats, otherAux)
	aux[self.name] = EEex.DeepCopy(otherAux[self.name])
end

EEex_Opcode_Temp_TrivialOnPlusEqu = function(self, stats, aux, otherStats, otherAux)
	local insertI = #aux
	for _, otherVal in ipairs(otherAux[self.name]) do
		insertI = insertI + 1
		aux[insertI] = EEex.DeepCopy(otherVal)
	end
end

(function()

	local trivialStat = {
		["onConstruct"] = EEex_Opcode_Temp_TrivialOnConstruct,
		["onReload"] = EEex_Opcode_Temp_TrivialOnReload,
		["onEqu"] = EEex_Opcode_Temp_TrivialOnEqu,
		["onPlusEqu"] = EEex_Opcode_Temp_TrivialOnPlusEqu,
	}

	trivialStat["__index"] = function(_, key)
		return trivialStat[key]
	end

	local registerStat = function(name, args)
		args = args or {}
		args.name = name
		setmetatable(args, trivialStat)
		EEex_Stats_Register(name, args)
	end

	---------------------------------------
	-- New Opcode #401 (SetExtendedStat) --
	---------------------------------------

	local statsIDS = EEex_Resource_LoadIDS("STATS")
	local exStats2DA = EEex_Resource_Load2DA("X-STATS")

	local getExtendedStatField = function(name, id, field)
		local val = exStats2DA:getAtLabels(field, name)
		if val ~= "*" and not tonumber(val) then
			print(string.format("[X-STATS.2DA] Invalid %s(#%d) %s value: \"%s\"", name, id, field, val))
			return "*"
		end
		return val
	end

	for id = EEex_Stats_FirstExtendedStatID, statsIDS:getCount() - 1 do
		if statsIDS:hasID(id) then
			local name = statsIDS:getLine(id)
			EEex_Stats_ExtendedInfo[id] = {
				["min"] = getExtendedStatField(name, id, "MIN"),
				["max"] = getExtendedStatField(name, id, "MAX"),
				["default"] = getExtendedStatField(name, id, "DEFAULT"),
			}
		end
	end

	statsIDS:free()
	exStats2DA:free()

	EEex_Opcode_Temp_ExtendedStats_OnConstruct = function(self, stats, aux)
		local t = {}
		for id, _ in pairs(EEex_Stats_ExtendedInfo) do
			t[id] = 0
		end
		aux["EEex_ExtendedStats"] = t
	end

	EEex_Opcode_Temp_ExtendedStats_OnReload = function(self, stats, aux, sprite)
		local t = aux["EEex_ExtendedStats"]
		for id, exStat in pairs(EEex_Stats_ExtendedInfo) do
			EEex_Stats_Private_SetExtended(t, id, exStat.default ~= "*" and tonumber(exStat.default) or 0)
		end
	end

	EEex_Opcode_Temp_ExtendedStats_OnPlusEqu = function(self, stats, aux, otherStats, otherAux)
		local exStats = aux["EEex_ExtendedStats"]
		local otherExStats = otherAux["EEex_ExtendedStats"]
		for id, _ in pairs(EEex_Stats_ExtendedInfo) do
			EEex_Stats_Private_SetExtended(exStats, id, exStats[id] + otherExStats[id])
		end
	end

	registerStat("EEex_ExtendedStats", {
		["onConstruct"] = EEex_Opcode_Temp_ExtendedStats_OnConstruct,
		["onReload"] = EEex_Opcode_Temp_ExtendedStats_OnReload,
		["onPlusEqu"] = EEex_Opcode_Temp_ExtendedStats_OnPlusEqu,
	})

	-------------------------------------
	-- New Opcode #403 (ScreenEffects) --
	-------------------------------------

	registerStat("EEex_ScreenEffects")

	-----------------------------------------
	-- New Opcode #408 (ProjectileMutator) --
	-----------------------------------------

	registerStat("EEex_ProjectileMutatorEffects")

	--------------------------------------------
	-- New Opcode #409 (EnableActionListener) --
	--------------------------------------------

	EEex_Opcode_Temp_EnabledActionListeners_OnPlusEqu = function(self, stats, aux, otherStats, otherAux)
		for k, v in pairs(otherAux[self.name]) do
			aux[k] = EEex.DeepCopy(v)
		end
	end

	registerStat("EEex_EnabledActionListeners", {
		["onPlusEqu"] = EEex_Opcode_Temp_EnabledActionListeners_OnPlusEqu,
	})

end)()
