
EEex_GameState_InitializedListeners = {}

function EEex_GameState_AddInitializedListener(listener)
	table.insert(EEex_GameState_InitializedListeners, listener)
end

-----------
-- Hooks --
-----------

function EEex_GameState_Hook_OnInitialized()
	for _, listener in ipairs(EEex_GameState_InitializedListeners) do
		listener()
	end
end
