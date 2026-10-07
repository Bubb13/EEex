
----------
-- Menu --
----------

uiStrings["EEex_Options_TRANSLATION_Menu_TabTitle"] = "菜单"

uiStrings["EEex_Options_TRANSLATION_Menu_UniversalScrollbarPadCollapsing"] = "通用滚动条填充折叠"

uiStrings["EEex_Options_TRANSLATION_Menu_UniversalScrollbarPadCollapsing_Description"] = [[
当滚动条图形被隐藏时，自动折叠文本右侧硬编码的16像素填充。

某些界面模组期望无论滚动条状态如何都应用此填充。禁用此选项将修复相关的文本错位情况。
]]

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

启用后，每当按下按键时，EEex会将所按键的按键码输出到战斗日志中。
]]

-------------
-- Modules --
-------------

uiStrings["EEex_Options_TRANSLATION_Modules_TabTitle"] = "模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableAttackInfo"] = "启用攻击信息模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableAttackInfo_Description"] = [[
启用攻击信息弹出窗口。

将攻击光标悬停在生物上时，攻击信息弹出窗口会打开并显示各种攻击信息。

这些信息包括：

- 每个选中的队员对目标的命中几率。

- 以及可选地，目标是否免疫每个选中队员的武器。

按住某个键位（默认为“左Alt键”）可以反转攻击方向。

反转攻击方向会使弹出窗口显示光标下生物的攻击信息，如同它正在攻击每个选中的队员一样。
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu"] = "启用效果菜单模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableEffectMenu_Description"] = [[
启用效果菜单。

按住快捷键（默认为“左Shift”）并将鼠标悬停在某个生物上时，会弹出一个菜单，显示当前影响该生物的所有法术。

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
启用一个快捷键（默认为“D”），在游戏暂停时，按下该键会使时间前进最小单位。

该快捷键本质上是让游戏取消暂停，然后极其快速地再次暂停。

按住快捷键半秒钟会使时间持续流动，直到松开为止。
]]

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule"] = "启用计时器模块"

uiStrings["EEex_Options_TRANSLATION_Modules_EnableTimerModule_Description"] = [[
在队员头像旁显示可视化指示器，展示多种计时信息。
]]

-------------------------
-- Module: Attack Info --
-------------------------

uiStrings["EEex_Options_TRANSLATION_AttackInfo_TabTitle"] = "模块：攻击信息"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_Enable"] = "启用"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_Enable_Description"] = uiStrings["EEex_Options_TRANSLATION_Modules_EnableAttackInfo_Description"]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_FontPoint"] = "字体磅值"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_FontPoint_Description"] = [[
用于显示攻击信息的字体磅值（大小）。
]]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType"] = "免疫显示类型"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_Description"] = [[
用于在弹出窗口中显示目标免疫状态的方法。

“彩色”——对于目标免疫攻击者的条目，改变用于显示命中几率的颜色。

“无”——不显示免疫数据。

“文本”——对于目标免疫攻击者的条目，替换其命中几率。
]]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_Color"] = "彩色"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_None"] = "无"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_Text"] = "文本"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_ShowColorKey"] = "显示颜色图例"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_ShowColorKey_Description"] = [[
决定当“免疫显示类型”选项设为“彩色”时，是否在弹出窗口右上角显示颜色图例。
]]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_OpenKeybind"] = "打开键位"
uiStrings["EEex_Options_TRANSLATION_AttackInfo_OpenKeybind_Description"] = [[
此键位用于打开攻击信息弹出窗口。
]]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_OpenWithAttackCursor"] = "使用攻击光标打开"
uiStrings["EEex_Options_TRANSLATION_AttackInfo_OpenWithAttackCursor_Description"] = [[
决定当攻击光标悬停在生物上时，攻击信息弹出窗口是否自动打开。
]]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ReverseKeybind"] = "反转键位"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ReverseKeybind_Description"] = [[
按下此键位时，会使攻击信息弹出窗口反转攻击方向——
即显示目标对选中队员的命中几率。

此键位可以在攻击信息弹出窗口当前处于关闭状态时将其打开。
]]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ShowColumnHeaders"] = "显示列标题"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_ShowColumnHeaders_Description"] = [[
决定是否将弹出窗口信息列表的第一行用于显示列标题。
]]

uiStrings["EEex_Options_TRANSLATION_AttackInfo_HideUnusedOffhandHeader"] = "隐藏未使用的副手标题"

uiStrings["EEex_Options_TRANSLATION_AttackInfo_HideUnusedOffhandHeader_Description"] = [[
决定当前视图中该列没有条目可显示时，是否隐藏副手列标题。
]]

uiStrings["EEex_TRANSLATION_AttackInfo_PartyAttacksTarget"] = "队伍攻击目标"

uiStrings["EEex_TRANSLATION_AttackInfo_TargetAttacksParty"] = "目标攻击队伍"

uiStrings["EEex_TRANSLATION_AttackInfo_ImmuneColorKey"] = "免疫="

uiStrings["EEex_TRANSLATION_AttackInfo_Mainhand"] = "主手"

uiStrings["EEex_TRANSLATION_AttackInfo_Offhand"] = "副手"

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

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage"] = "缩放百分比[0-1]"

uiStrings["EEex_Options_TRANSLATION_Scale_Percentage_Description"] = [[
强制引擎使用指定的UI缩放系数。

此字段为0到1之间的小数。

例如，值为“0.5”将强制游戏使用50%的缩放系数。
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

请注意，某些模组会在后台添加意外术效果来实现特定行为——这可能导致意外术指示器意外出现。
]]

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer"] = "显示行动计时器"

uiStrings["EEex_Options_TRANSLATION_Timer_ShowModalTimer_Description"] = [[
在队员头像旁显示一条红色条。

此指示器显示行动的间隔：寻找陷阱、超度亡灵等。
]]

---------------
-- Uncap FPS --
---------------

uiStrings["EEex_Options_TRANSLATION_UncapFPS_TabTitle"] = "解除帧率上限"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed"] = "AI速度"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_AISpeed_Description"] = [[
游戏“逻辑”每秒触发的次数。

这决定了游戏进行的速度。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable"] = "启用解除帧率上限"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_Enable_Description"] = [[
移除引擎通常的30帧率上限，让游戏能以显示器的刷新率进行渲染。

这能在高刷新率显示器上改善视角移动的流畅度。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_EnableFPSLimit"] = "启用帧率限制"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_EnableFPSLimit_Description"] = [[
启用“帧率限制”选项。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit"] = "帧率限制"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimit_Description"] = [[
将解除上限后的帧率限制在给定数值。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimitBusyWaitThreshold"] = "帧率限制忙等待阈值"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FPSLimitBusyWaitThreshold_Description"] = [[
如果下一帧计划在此毫秒数之内，引擎会忙等待，而不是让出CPU。

仅在启用“解除帧率上限”选项时生效。

数值越高，帧率节奏越好，但CPU占用也越高。

数值为“0”会禁用让出CPU。除非你在极低功耗设备上游戏，否则不要使用此设置。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FullscreenVRR"] = "全屏可变刷新率提示"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_FullscreenVRR_Description"] = [[
向解除帧率上限系统提示，当游戏处于全屏模式时，显卡驱动程序将启用可变刷新率。

这会自动改变游戏主循环，以更好地处理可变刷新率。

在你的系统未启用可变刷新率时启用此选项，将产生不利影响。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_LuaGCSteps"] = "Lua垃圾回收步数"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_LuaGCSteps_Description"] = [[
决定Lua在每一帧之后花多少时间清理未使用的内存。

数值越低，帧率越高，但可能因为随时间积累大量“垃圾”而导致卡顿。

数值越高，可以防止卡顿，但代价是降低帧率。

极高的数值可能会耗时过长，影响帧率节奏。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier"] = "移除鼠标中键滚轮倍率"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier_Description"] = [[
移除按住鼠标中键时施加于视口移动的硬编码倍率。
]]

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled"] = "垂直同步已启用"

uiStrings["EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled_Description"] = [[
控制引擎是否自动将游戏的渲染速率与显示器同步。

这会消除画面撕裂，但代价是增加输入延迟。
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
