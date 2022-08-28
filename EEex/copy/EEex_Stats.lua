
-------------
-- Globals --
-------------

EEex_DerivedStats_DisabledButtonType = {
	["BUTTON_STEALTH"]      = 0,
	["BUTTON_THIEVING"]     = 1,
	["BUTTON_CASTSPELL"]    = 2,
	["BUTTON_QUICKSPELL0"]  = 3,
	["BUTTON_QUICKSPELL1"]  = 4,
	["BUTTON_QUICKSPELL2"]  = 5,
	["BUTTON_TURNUNDEAD"]   = 6,
	["BUTTON_DIALOG"]       = 7,
	["BUTTON_USEITEM"]      = 8,
	["BUTTON_QUICKITEM1"]   = 9,
	["BUTTON_BATTLESONG"]   = 10,
	["BUTTON_QUICKITEM2"]   = 11,
	["BUTTON_QUICKITEM3"]   = 12,
	["BUTTON_INNATEBUTTON"] = 13,
	["SCREEN_INVENTORY"]    = 14,
}

-----------------------
-- General Functions --
-----------------------

EEex_Stats_Registered = {}

-- Needs to be updated if Beamdog ever adds a new stat
EEex_Stats_FirstExtendedStatID = 203
EEex_Stats_ExtendedInfo = {}

function EEex_Stats_Register(name, args)
	EEex_Stats_Registered[name] = args
end

function EEex_Stats_Private_SetExtended(exStats, id, v)
	local exStatInfo = EEex_Stats_ExtendedInfo[id]
	local min = exStatInfo.min
	if min ~= "*" then v = math.max(v, tonumber(min)) end
	local max = exStatInfo.max
	if max ~= "*" then v = math.min(tonumber(max), v) end
	exStats[id] = v
end

-----------
-- Hooks --
-----------

function EEex_Stats_Hook_OnConstruct(stats)
	local aux = EEex_GetUDAux(stats)
	for _, registered in pairs(EEex_Stats_Registered) do
		EEex_Utility_CallIfExists(registered.onConstruct, registered, stats, aux)
	end
end

function EEex_Stats_Hook_OnDestruct(stats)
	local aux = EEex_GetUDAux(stats)
	for _, registered in pairs(EEex_Stats_Registered) do
		EEex_Utility_CallIfExists(registered.onDestruct, registered, stats, aux)
	end
	EEex_DeleteUDAux(stats)
end

-- Assuming m_derivedStats is being reloaded (true as of v2.6)
function EEex_Stats_Hook_OnReload(sprite)
	local stats = sprite.m_derivedStats
	local aux = EEex_GetUDAux(stats)
	for _, registered in pairs(EEex_Stats_Registered) do
		EEex_Utility_CallIfExists(registered.onReload, registered, stats, aux, sprite)
	end
end

function EEex_Stats_Hook_OnEqu(stats, otherStats)
	local aux = EEex_GetUDAux(stats)
	local otherAux = EEex_GetUDAux(otherStats)
	for _, registered in pairs(EEex_Stats_Registered) do
		EEex_Utility_CallIfExists(registered.onEqu, registered, stats, aux, otherStats, otherAux)
	end
end

function EEex_Stats_Hook_OnPlusEqu(stats, otherStats)
	local aux = EEex_GetUDAux(stats)
	local otherAux = EEex_GetUDAux(otherStats)
	for _, registered in pairs(EEex_Stats_Registered) do
		EEex_Utility_CallIfExists(registered.onPlusEqu, registered, stats, aux, otherStats, otherAux)
	end
end

function EEex_Stats_Hook_OnGettingUnknown(stats, id)
	return EEex_Stats_ExtendedInfo[id]
		and EEex_GetUDAux(stats)["EEex_ExtendedStats"][id]
		or 0
end
