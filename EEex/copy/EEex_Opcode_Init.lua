
-- TODO: Defunct

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

end)()
