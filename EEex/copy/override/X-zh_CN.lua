
----------------------------
-- Miscellaneous Keybinds --
----------------------------

uiStrings["EEex_Options_TRANSLATION_Keybinds_TabTitle"] = "杂项快捷键"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions"] = "打开选项"

uiStrings["EEex_Options_TRANSLATION_Keybinds_OpenOptions_Description"] = [[
用于快速打开此菜单的快捷键。
]]

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput"] = "切换按键码输出"

uiStrings["EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput_Description"] = [[
此快捷键用于切换按键码输出。

启用后，每当按下按键时，EEex 会将所按键的按键码输出到战斗日志中。
]]

-------------
-- Modules --
-------------

uiStrings["EEex_Options_TRANSLATION_Modules_TabTitle"] = "模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu"] = "启用效果菜单模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu_Description"] = [[
启用效果菜单。

按住快捷键（默认为『左 Shift』）并将鼠标悬停在某个生物上时，会弹出一个菜单，显示当前影响该生物的所有法术。

注意，此菜单是动态生成的——它已尽力而为，但仍存在无法检测到的漏洞，有时可能会显示内部法术。
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer"] = "启用空容器模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEmptyContainer_Description"] = [[
将空容器的高亮颜色改为灰色（替换原来的青色）。
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule"] = "启用缩放模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableScaleModule_Description"] = [[
允许将 UI 缩放系数设置为自定义值。
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep"] = "启用时间步进模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimeStep_Description"] = [[
启用一个快捷键（默认为『D』），在游戏暂停时，按下该键会使时间前进最小单位。

该快捷键本质上是让游戏取消暂停，然后极其快速地再次暂停。

按住快捷键半秒钟会使时间持续流动，直到松开为止。
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule"] = "启用计时器模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule_Description"] = [[
在队员头像旁显示可视化指示器，展示多种计时信息。
]]

-------------------------
-- Module: Effect Menu --
-------------------------

uiStrings["EEex_Options_TRANSLATION_EffectMenu_TabTitle"] = "模块：效果菜单"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind"] = "启动快捷键"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_LaunchKeybind_Description"] = [[
按住此快捷键并将鼠标悬停在生物上时，会弹出效果菜单。
]]

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount"] = "行数"

uiStrings["EEex_Options_TRANSLATION_EffectMenu_RowCount_Description"] = [[
效果菜单弹出窗口显示的行数。
]]

-------------------
-- Module: Scale --
-------------------

uiStrings["EEex_Options_TRANSLATION_Scale_TabTitle"] = "模块：缩放"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage"] = "缩放百分比 [0-1]"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage_Description"] = [[
强制引擎使用指定的 UI 缩放系数。

此字段为 0 到 1 之间的小数。

例如，值为『0.5』将强制游戏使用 50% 的缩放系数。
]]

-----------------------
-- Module: Time Step --
-----------------------

uiStrings["EEex_Options_TRANSLATION_TimeStep_TabTitle"] = "模块：时间步进"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind"] = "时间前进快捷键"

uiStrings["EEex_Options_TRANSLATION_TimeStep_Keybind_Description"] = [[
游戏暂停时，此快捷键使时间前进最小单位。

该快捷键本质上是让游戏取消暂停，然后极其快速地再次暂停。

按住快捷键半秒钟会使时间持续流动，直到松开为止。
]]

-------------------
-- Module: Timer --
-------------------

uiStrings["EEex_Options_TRANSLATION_Timer_TabTitle"] = "模块：计时器"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits"] = "紧贴头像"

uiStrings["EEex_Options_TRANSLATION_Timer_HugPortraits_Description"] = [[
移除计时条与其对应头像之间的间隙。
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer"] = "显示施法计时器"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowCastTimer_Description"] = [[
在队员头像旁显示一条青色条。

此指示器显示使用法术/物品的冷却时间。
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer"] = "显示触发术计时器"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowContingencyTimer_Description"] = [[
在队员头像旁显示一条绿色条。

此指示器显示触发术条件的检查间隔。

请注意，某些模组会在后台添加触发术效果来实现特定行为——这可能导致触发术指示器意外出现。
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer"] = "显示行动计时器"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer_Description"] = [[
在队员头像旁显示一条红色条。

此指示器显示行动的间隔：寻找陷阱、超度亡灵等。
]]

---------------
-- Uncap FPS --
---------------

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed"] = "AI 速度"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed_Description"] = [[
游戏“逻辑”每秒触发的次数。

这决定了游戏进行的速度。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_BusyWaitThreshold"] = "忙等待阈值"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_BusyWaitThreshold_Description"] = [[
如果下一帧将在小于此数值（毫秒）内调度，则引擎采用忙等待而非让出 CPU。

仅在“启用帧率限制解除”选项生效时激活。

较高的值会改善帧步调，但会增加 CPU 使用率。

值为『0』将禁用让出。除非你在极低功耗设备上游戏，否则不要使用此值。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable"] = "启用帧率限制解除"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable_Description"] = [[
移除引擎通常的30fps限制，允许游戏以显示器的刷新率渲染。

这可以改善高刷新率显示器上视口移动的平滑度。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit"] = "帧率限制"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit_Description"] = [[
将解除限制后的FPS限制为给定值。

此值不能将 FPS 降低到低于“AI速度”选项的值。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier"] = "移除鼠标中键滚动倍数"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier_Description"] = [[
移除按住鼠标中键进行视口移动时所应用的硬编码倍数。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled"] = "启用垂直同步"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled_Description"] = [[
控制引擎是否自动将游戏渲染率与显示器同步。

这会消除画面撕裂，但会增加输入延迟。
]]

-------------------
-- Miscellaneous --
-------------------

uiStrings["B3EffectMenu_TRANSLATION_No_Name"]              = "（无名称）"
uiStrings["EEex_Options_TRANSLATION_Accept"]               = "接受"
uiStrings["EEex_Options_TRANSLATION_EEex_Options"]         = "EEex 选项"
uiStrings["EEex_Options_TRANSLATION_Exit"]                 = "退出"
uiStrings["EEex_Options_TRANSLATION_Locked"]               = "（已锁定）"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Pressed"]  = "序列按下时"
uiStrings["EEex_Options_TRANSLATION_On_Sequence_Released"] = "序列释放时"
uiStrings["EEex_Options_TRANSLATION_Requires_Restart"]     = "需要重启"
uiStrings["EEex_Options_TRANSLATION_Reset_to_Default"]     = "重置为默认"

uiStrings["EEex_Options_TRANSLATION_Description_Hint"] = [[
点击选项标签可查看其说明。
]]
