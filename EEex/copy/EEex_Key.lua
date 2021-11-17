
-----------------------
-- General Functions --
-----------------------

function EEex_Key_GetFromName(name)
	return EngineGlobals.SDL_GetKeyFromName(name)
end

EEex_Key_IsDownMap = EEex_Key_IsDownMap or {}

function EEex_Key_IsDown(key)
	return EEex_Key_IsDownMap[key]
end

---------------
-- Listeners --
---------------

EEex_Key_PressedListeners = {}

function EEex_Key_AddPressedListener(func)
	table.insert(EEex_Key_PressedListeners, func)
end

EEex_Key_ReleasedListeners = {}

function EEex_Key_AddReleasedListener(func)
	table.insert(EEex_Key_ReleasedListeners, func)
end

-----------
-- Hooks --
-----------

function EEex_Key_OnPressed(key)
	EEex_Key_IsDownMap[key] = true
	for i, func in ipairs(EEex_Key_PressedListeners) do
		func(key)
	end
end

function EEex_Key_OnReleased(key)
	EEex_Key_IsDownMap[key] = false
	for i, func in ipairs(EEex_Key_ReleasedListeners) do
		func(key)
	end
end

function EEex_Key_Hook_AfterEventsPoll(eventPtr)
	local event = EEex_PtrToUD(eventPtr, "SDL_Event")
	if event.type == SDL_EventType.SDL_KEYDOWN then
		EEex_Key_OnPressed(event.key.keysym.sym)
	elseif event.type == SDL_EventType.SDL_KEYUP then
		EEex_Key_OnReleased(event.key.keysym.sym)
	end
end
