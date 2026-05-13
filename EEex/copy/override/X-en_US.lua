
----------------------------
-- Miscellaneous Keybinds --
----------------------------

uiStrings["EEex_Options_TRANSLATION_Keybinds_TabTitle"] = "Miscellaneous Keybinds"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions"] = "Open Options"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions_Description"] = [[
Keybind that provides quick access to this menu.
]]

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput"] = "Toggle Keycode Output"

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput_Description"] = [[
This keybind toggles keycode printouts.

When enabled, any time a key is pressed EEex will output the pressed key's keycode to the combat log.
]]

-------------
-- Modules --
-------------

uiStrings["EEex_Options_TRANSLATION_Modules_TabTitle"] = "Modules"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu"] = "Enable Effect Menu Module"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu_Description"] = [[
Enables the effect menu.

A menu displaying all the spells currently affecting a creature can be invoked by holding a keybind, (by default 'Left Shift'), and hovering over said creature.

Note that this menu is dynamically generated - it does the best it can, though there are holes in what it can detect, and it may show internal spells at times.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer"] = "Enable Empty Container Module"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer_Description"] = [[
Changes the highlight color of empty containers to gray (replacing the normal cyan).
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule"] = "Enable Scale Module"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule_Description"] = [[
Enables the ability to set the UI scaling factor to a custom value.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep"] = "Enable Time Step Module"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep_Description"] = [[
Enables a keybind, (by default 'D'), that when the game is paused, advances time by the minimum amount.

The keybind essentially causes the game to unpause and then pause again extremely quickly.

Holding the keybind for half a second makes time flow until it is released.
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule"] = "Enable Timer Module"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule_Description"] = [[
Enables visual indicators next to party member portraits that display various timer information.
]]

-------------------------
-- Module: Effect Menu --
-------------------------

uiStrings["EEex_Options_TRANSLATION_EffectMenu_TabTitle"] = "Module: Effect Menu"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind"] = "Launch Keybind"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind_Description"] = [[
The effect menu is launched when this keybind is held down and the mouse is hovered over a creature.
]]

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount"] = "Row Count"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount_Description"] = [[
The number of rows displayed by the effect menu popup.
]]

-------------------
-- Module: Scale --
-------------------

uiStrings["EEex_Options_TRANSLATION_Scale_TabTitle"] = "Module: Scale"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage"] = "Scale Percentage [0-1]"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage_Description"] = [[
Forces the engine to use the provided UI scaling factor.

This field is a decimal between 0 and 1.

For example, a value of '0.5' would force the game to use a 50% scaling factor.
]]

-----------------------
-- Module: Time Step --
-----------------------

uiStrings["EEex_Options_TRANSLATION_TimeStep_TabTitle"] = "Module: Time Step"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind"] = "Advance Time Keybind"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind_Description"] = [[
When the game is paused, this keybind advances time by the minimum amount.

The keybind essentially causes the game to unpause and then pause again extremely quickly.

Holding the keybind for half a second makes time flow until it is released.
]]

-------------------
-- Module: Timer --
-------------------

uiStrings["EEex_Options_TRANSLATION_Timer_TabTitle"] = "Module: Timer"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits"] = "Hug Portraits"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits_Description"] = [[
Removes the gap between timer bars and their respective portrait.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer"] = "Show Cast Timer"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer_Description"] = [[
Enables a cyan bar next to party member portraits.

This indicator displays the cooldown for using spells / items.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer"] = "Show Contingency Timer"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer_Description"] = [[
Enables a green bar next to party member portraits.

This indicator displays the interval at which contingency conditions are checked.

Note that some mods add contingency effects behind-the-scenes to implement certain behaviors - this may cause the contingency indicator to appear unexpectedly.
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer"] = "Show Modal Timer"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer_Description"] = [[
Enables a red bar next to party member portraits.

This indicator displays the interval of modal actions: find traps, turn undead, etc.
]]

---------------
-- Uncap FPS --
---------------

uiStrings["EEex_Options_TRANSLATION_UncapFPS_TabTitle"] = "Uncap FPS"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed"] = "AI Speed"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed_Description"] = [[
The number of times per second the "logic" of the game is ticked.

This determines the speed of gameplay.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_BusyWaitThreshold"] = "Busy Wait Threshold"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_BusyWaitThreshold_Description"] = [[
If the next frame is scheduled within this number of milliseconds, the engine busy-waits
instead of yielding the CPU.

Only active when the "Enable FPS Uncap" option is in effect.

Higher values improve frame pacing at the cost of increased CPU usage.

A value of '0' disables yielding. Don't use this unless you are playing on an extremely low-power device.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable"] = "Enable FPS Uncap"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable_Description"] = [[
Removes the engine's usual 30fps cap, allowing the game to render at your monitor's refresh rate.

This improves the smoothness of viewport movement on high refresh rate monitors.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit"] = "FPS Limit"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit_Description"] = [[
Limits the uncapped FPS to the given value.

This cannot lower the FPS below the "AI Speed" option.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier"] = "Remove Middle Mouse Scroll Multiplier"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier_Description"] = [[
Removes the hardcoded multiplier applied to viewport movement performed by holding down the middle-mouse button.
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled"] = "VSync Enabled"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled_Description"] = [[
Controls whether the engine automatically synchronizes the game's render rate with the monitor.

This eliminates screen tearing at the cost of increased input latency.
]]

-------------------
-- Miscellaneous --
-------------------

uiStrings["B3EffectMenu_TRANSLATION_No_Name"]              = "(No Name)"
uiStrings["EEex_Options_TRANSLATION_Accept"]               = "Accept"
uiStrings["EEex_Options_TRANSLATION_EEex_Options"]         = "EEex Options"
uiStrings["EEex_Options_TRANSLATION_Exit"]                 = "Exit"
uiStrings["EEex_Options_TRANSLATION_Locked"]               = "(Locked)"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Pressed"]  = "On Sequence Pressed"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Released"] = "On Sequence Released"
uiStrings["EEex_Options_TRANSLATION_Requires_Restart"]     = "Requires Restart"
uiStrings["EEex_Options_TRANSLATION_Reset_to_Default"]     = "Reset to Default"

uiStrings["EEex_Options_TRANSLATION_Description_Hint"] = [[
Click an option label to view its description.
]]
