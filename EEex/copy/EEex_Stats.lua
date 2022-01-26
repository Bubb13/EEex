
EEex_Stats_Registered = {}

function EEex_Stats_Register(name, args)
	EEex_Stats_Registered[name] = args
end

-----------
-- Hooks --
-----------

function EEex_Stats_Hook_OnConstruct(stats)
	local aux = EEex_GetUDAux(stats)
	for _, registered in pairs(EEex_Stats_Registered) do
		local onConstruct = registered.onConstruct
		if onConstruct then
			onConstruct(stats, aux)
		end
	end
end

function EEex_Stats_Hook_OnDestruct(stats)
	local aux = EEex_GetUDAux(stats)
	for _, registered in pairs(EEex_Stats_Registered) do
		local onDestruct = registered.onDestruct
		if onDestruct then
			onDestruct(stats, aux)
		end
	end
	EEex_DeleteUDAux(stats)
end

-- Assuming m_derivedStats is being reloaded (true as of v2.6)
function EEex_Stats_Hook_OnReload(sprite)
	local stats = sprite.m_derivedStats
	local aux = EEex_GetUDAux(stats)
	for _, registered in pairs(EEex_Stats_Registered) do
		local onReload = registered.onReload
		if onReload then
			onReload(stats, aux, sprite)
		end
	end
end

function EEex_Stats_Hook_OnEqu(stats, otherStats)
	local aux = EEex_GetUDAux(stats)
	local otherAux = EEex_GetUDAux(otherStats)
	for _, registered in pairs(EEex_Stats_Registered) do
		local onEqu = registered.onEqu
		if onEqu then
			onEqu(stats, aux, otherStats, otherAux)
		end
	end
end

function EEex_Stats_Hook_OnPlusEqu(stats, otherStats)
	local aux = EEex_GetUDAux(stats)
	local otherAux = EEex_GetUDAux(otherStats)
	for _, registered in pairs(EEex_Stats_Registered) do
		local onPlusEqu = registered.onPlusEqu
		if onPlusEqu then
			onPlusEqu(stats, aux, otherStats, otherAux)
		end
	end
end
