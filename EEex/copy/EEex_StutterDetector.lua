
-------------
-- Options --
-------------

EEex_StutterDetector_Load = false
EEex_StutterDetector_OutputEnabled = true

---------------
-- Listeners --
---------------

function EEex_StutterDetector_Private_LoadMenuListener()
	EEex_Menu_LoadFile("X-STUTDE")
end

function EEex_StutterDetector_Private_PushMenuListener()
	Infinity_PushMenu("EEex_StutterDetector_Menu")
end

function EEex_StutterDetector_Private_InstallFunctionWrappers()
	local topLevel = true
	for k, v in pairs(_G) do
		if type(k) == "string" and type(v) == "function"
			and
			(    #k >= 5 and string.sub(k, 1, 5) == "EEex_"
			  or #k >= 2 and string.sub(k, 1, 2) == "B3"
			)
			and v ~= EEex_GetMicroseconds
		then
			_G[k] = function(...)

				local oldTopLevel = topLevel
				topLevel = false

				local start = EEex_GetMicroseconds()
				local retT = {v(...)}
				local timeTaken = EEex_GetMicroseconds() - start

				topLevel = oldTopLevel
				EEex_StutterDetector_Private_Times[k] = (EEex_StutterDetector_Private_Times[k] or 0) + timeTaken

				if topLevel then
					EEex_StutterDetector_Private_TopLevelTime = EEex_StutterDetector_Private_TopLevelTime + timeTaken
				end

				return table.unpack(retT)
			end
		end
	end
end

function EEex_StutterDetector_Private_GameInitializedListener()
	EEex_StutterDetector_Private_InstallFunctionWrappers()
	EEex_StutterDetector_Private_PushMenuListener()
end

----------
-- Code --
----------

EEex_StutterDetector_Private_TopLevelTime = 0
EEex_StutterDetector_Private_Times = {}
EEex_StutterDetector_Private_LastMicroseconds = nil

function EEex_StutterDetector_Private_Tick()

	local microseconds = EEex_GetMicroseconds()

	if EEex_StutterDetector_OutputEnabled and EEex_StutterDetector_Private_LastMicroseconds then
		local target = 1000000 / EEex_CChitin.TIMER_UPDATES_PER_SECOND
		local targetFudge = target + target * 0.05
		local diff = microseconds - EEex_StutterDetector_Private_LastMicroseconds
		if diff > targetFudge and EEex_StutterDetector_Private_TopLevelTime > 1000 then

			print("    +--------------------+--------------------------+")
			print(string.format("[!] | Stutter: %7.3fms | EEex Lua time: %7.3fms |",
				diff / 1000, EEex_StutterDetector_Private_TopLevelTime / 1000))
			print("    +--------------------+--------------------------+")

			EEex_Utility_IterateMapAsSorted(EEex_StutterDetector_Private_Times,
				function(o1, o2) return o1[2] > o2[2] end,
				function(i, k, v)
					if v >= 1000 then
						print(string.format("    | %7.3fms - %s", v / 1000, k))
					end
				end
			)
		end
	end

	EEex_StutterDetector_Private_TopLevelTime = 0
	EEex_StutterDetector_Private_Times = {}
	EEex_StutterDetector_Private_LastMicroseconds = microseconds
end

(function()

	if not EEex_StutterDetector_Load then
		return
	end

	EEex_Menu_AddMainFileLoadedListener(EEex_StutterDetector_Private_LoadMenuListener)
	EEex_GameState_AddInitializedListener(EEex_StutterDetector_Private_GameInitializedListener)
	EEex_Menu_AddAfterMainFileReloadedListener(EEex_StutterDetector_Private_PushMenuListener)
end)()
