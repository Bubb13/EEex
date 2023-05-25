
(function()

	local trivialStat = {
		["onConstruct"] = function(self, stats, aux)
			aux[self.name] = {}
		end,
		["onReload"] = function(self, stats, aux, sprite)
			aux[self.name] = {}
		end,
		["onEqu"] = function(self, stats, aux, otherStats, otherAux)
			aux[self.name] = EEex_Utility_DeepCopy(otherAux[self.name])
		end,
		["onPlusEqu"] = function(self, stats, aux, otherStats, otherAux)
			local insertI = #aux
			for _, otherVal in ipairs(otherAux[self.name]) do
				insertI = insertI + 1
				aux[insertI] = EEex_Utility_DeepCopy(otherVal)
			end
		end,
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

	-----------------------------------------------------------------------
	-- Opcode #280                                                       --
	--   param1  != 0 => Force wild surge number                         --
	--   special != 0 => Suppress wild surge feedback string and visuals --
	-----------------------------------------------------------------------

	registerStat("EEex_Op280", {
		["onConstruct"] = function(self, stats, aux)
			aux["EEex_Op280"] = nil
		end,
		["onReload"] = function(self, stats, aux, sprite)
			aux["EEex_Op280"] = nil
		end,
		["onPlusEqu"] = function(self, stats, aux, otherStats, otherAux) end,
	})

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

	registerStat("EEex_ExtendedStats", {
		["onConstruct"] = function(self, stats, aux)
			local t = {}
			for id, _ in pairs(EEex_Stats_ExtendedInfo) do
				t[id] = 0
			end
			aux["EEex_ExtendedStats"] = t
		end,
		["onReload"] = function(self, stats, aux, sprite)
			local t = aux["EEex_ExtendedStats"]
			for id, exStat in pairs(EEex_Stats_ExtendedInfo) do
				EEex_Stats_Private_SetExtended(t, id, exStat.default ~= "*" and tonumber(exStat.default) or 0)
			end
		end,
		["onPlusEqu"] = function(self, stats, aux, otherStats, otherAux)
			local exStats = aux["EEex_ExtendedStats"]
			local otherExStats = otherAux["EEex_ExtendedStats"]
			for id, _ in pairs(EEex_Stats_ExtendedInfo) do
				EEex_Stats_Private_SetExtended(exStats, id, exStats[id] + otherExStats[id])
			end
		end,
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

	registerStat("EEex_EnabledActionListeners", {
		["onPlusEqu"] = function(self, stats, aux, otherStats, otherAux)
			for k, v in pairs(otherAux[self.name]) do
				aux[k] = EEex_Utility_DeepCopy(v)
			end
		end,
	})

end)()
