
-------------
-- Options --
-------------

EEex_Options_Register("EEex_UncapFPS_AISpeed", EEex_Options_Option.new({
	["default"]  = 30,
	["type"]     = EEex_Options_EditType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 1, ["max"] = 90 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "Program Options", ["key"] = "Maximum Frame Rate" }),
	["onChange"] = function(self, oldValue) EEex_CChitin.TIMER_UPDATES_PER_SECOND = self:get() end,
}))

EEex_Options_Register("EEex_UncapFPS_Enable", EEex_Options_Option.new({
	["default"]  = 1,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Uncap FPS" }),
	["onChange"] = function(self, oldValue) EEex.SetUncapFPSEnabled(self:get()) end,
}))

EEex_Options_Register("EEex_UncapFPS_EnableFPSLimit", EEex_Options_Option.new({
	["default"]  = 0,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Uncap FPS Limit Enabled" }),
	["onChange"] = function(self, oldValue) EEex.UncapFPS_FPSLimitEnabled = self:get() end,
}))

EEex_Options_Register("EEex_UncapFPS_FPSLimit", EEex_Options_Option.new({
	["default"]  = EEex.GetHighestRefreshRate(),
	["type"]     = EEex_Options_EditType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 1, ["max"] = 5000 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Uncap FPS Limit" }),
	["onChange"] = function(self, oldValue) EEex.UncapFPS_FPSLimit = self:get() end,
}))

EEex_Options_Register("EEex_UncapFPS_FPSLimitBusyWaitThreshold", EEex_Options_Option.new({
	["default"]  = 1,
	["type"]     = EEex_Options_EditType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1000 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Uncap FPS Busy Wait Threshold" }),
	["onChange"] = function(self, oldValue) EEex.UncapFPS_BusyWaitThreshold = self:get() end,
}))

EEex_Options_Register("EEex_UncapFPS_FullscreenVRR", EEex_Options_Option.new({
	["default"]  = 0,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Uncap FPS Fullscreen VRR" }),
	["onChange"] = function(self, oldValue) EEex.UncapFPS_FullscreenVRR = self:get() end,
}))

EEex_Options_Register("EEex_UncapFPS_LuaGCSteps", EEex_Options_Option.new({
	["default"]  = EEex.UncapFPS_LuaGCSteps,
	["type"]     = EEex_Options_EditType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1000 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Lua GC Steps" }),
	["onChange"] = function(self, oldValue) EEex.UncapFPS_LuaGCSteps = self:get() end,
}))

EEex_Options_Register("EEex_UncapFPS_RemoveMiddleMouseScrollMultiplier", EEex_Options_Option.new({
	["default"]  = 1,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Remove Middle Mouse Scroll Multiplier" }),
	["onChange"] = function(self, oldValue) EEex.UncapFPS_RemoveMiddleMouseScrollMultiplier = self:get() end,
}))

EEex_UncapFPS_Private_VSyncEnabled = EEex_Options_Register("EEex_UncapFPS_VSyncEnabled", EEex_Options_Option.new({
	["default"]  = 1,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "VSync Enabled" }),
	["onChange"] = function(self, oldValue)
		if oldValue == nil then return end -- Ignore initial read
		EEex_UncapFPS_SetVSyncEnabled(self:get() ~= 0)
	end,
}))

EEex_Options_AddTab("EEex_Options_TRANSLATION_UncapFPS_TabTitle", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_AISpeed",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_AISpeed",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_AISpeed_Description",
			["widget"]      = EEex_Options_EditWidget.new({
				["maxCharacters"] = 2,
				["number"] = true,
			}),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_Enable",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_Enable",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_Enable_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_EnableFPSLimit",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_EnableFPSLimit",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_EnableFPSLimit_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_FPSLimit",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_FPSLimit",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_FPSLimit_Description",
			["widget"]      = EEex_Options_EditWidget.new({
				["maxCharacters"] = 4,
				["number"] = true,
			}),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_FPSLimitBusyWaitThreshold",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_FPSLimitBusyWaitThreshold",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_FPSLimitBusyWaitThreshold_Description",
			["widget"]      = EEex_Options_EditWidget.new({
				["maxCharacters"] = 4,
				["number"] = true,
			}),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_FullscreenVRR",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_FullscreenVRR",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_FullscreenVRR_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_LuaGCSteps",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_LuaGCSteps",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_LuaGCSteps_Description",
			["widget"]      = EEex_Options_EditWidget.new({
				["maxCharacters"] = 4,
				["number"] = true,
			}),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_RemoveMiddleMouseScrollMultiplier",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_RemoveMiddleMouseScrollMultiplier_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_UncapFPS_VSyncEnabled",
			["label"]       = "EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled",
			["description"] = "EEex_Options_TRANSLATION_UncapFPS_VSyncEnabled_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
	},
} end)

----------------------
-- Public Functions --
----------------------

-- @bubb_doc { EEex_UncapFPS_SetVSyncEnabled }
--
-- @summary: Enables / disables VSync.
--
-- @warning: Calling this function during engine startup will crash the game.
--
-- @param { enabled / type=boolean }: Enables VSync if ``true``; disables VSync if ``false``.

function EEex_UncapFPS_SetVSyncEnabled(enabled)
	EEex.SetVSyncEnabled(enabled, true)
end

-----------------------
-- Private Functions --
-----------------------

EEex_UncapFPS_Private_ScrollDirection = {
	["UP"]           = 0,
	["TOP_RIGHT"]    = 1,
	["RIGHT"]        = 2,
	["BOTTOM_RIGHT"] = 3,
	["DOWN"]         = 4,
	["BOTTOM_LEFT"]  = 5,
	["LEFT"]         = 6,
	["TOP_LEFT"]     = 7,
}

EEex_UncapFPS_Private_HardcodedScrollKeys = {
	[0x4000004F] = EEex_UncapFPS_Private_ScrollDirection.RIGHT,        -- SDLK_RIGHT
	[0x40000050] = EEex_UncapFPS_Private_ScrollDirection.LEFT,         -- SDLK_LEFT
	[0x40000051] = EEex_UncapFPS_Private_ScrollDirection.DOWN,         -- SDLK_DOWN
	[0x40000052] = EEex_UncapFPS_Private_ScrollDirection.UP,           -- SDLK_UP
	[0x40000059] = EEex_UncapFPS_Private_ScrollDirection.BOTTOM_LEFT,  -- SDLK_KP_1
	[0x4000005A] = EEex_UncapFPS_Private_ScrollDirection.DOWN,         -- SDLK_KP_2
	[0x4000005B] = EEex_UncapFPS_Private_ScrollDirection.BOTTOM_RIGHT, -- SDLK_KP_3
	[0x4000005C] = EEex_UncapFPS_Private_ScrollDirection.LEFT,         -- SDLK_KP_4
	[0x4000005E] = EEex_UncapFPS_Private_ScrollDirection.RIGHT,        -- SDLK_KP_6
	[0x4000005F] = EEex_UncapFPS_Private_ScrollDirection.TOP_LEFT,     -- SDLK_KP_7
	[0x40000060] = EEex_UncapFPS_Private_ScrollDirection.UP,           -- SDLK_KP_8
	[0x40000061] = EEex_UncapFPS_Private_ScrollDirection.TOP_RIGHT,    -- SDLK_KP_9
}

function EEex_UncapFPS_Private_GetKeyScrollDirection(mappedKeys, key)

	local hardcodedDirection = EEex_UncapFPS_Private_HardcodedScrollKeys[key]
	if hardcodedDirection then
		return hardcodedDirection
	end

	if not mappedKeys then
		return
	end

	if key == mappedKeys[1] then return EEex_UncapFPS_Private_ScrollDirection.UP    end
	if key == mappedKeys[2] then return EEex_UncapFPS_Private_ScrollDirection.RIGHT end
	if key == mappedKeys[3] then return EEex_UncapFPS_Private_ScrollDirection.DOWN  end
	if key == mappedKeys[4] then return EEex_UncapFPS_Private_ScrollDirection.LEFT  end
end

function EEex_UncapFPS_Private_IsScrollAccepted(game)

	if Infinity_TextEditHasFocus() ~= 0 then
		-- Don't scroll if a text edit is focused, (e.g. the debug console)
		return false
	end

	local activeEngine = e:GetActiveEngine()
	if activeEngine ~= worldScreen and activeEngine ~= mapScreen then
		-- Current engine doesn't accept keyboard scrolling
		return false
	end

	-- Ensure not in cutscene or dialog mode
	local inputMode = game.m_gameSave.m_inputMode
	return EEex_BAnd(inputMode - 0x1016E, 0xFFFDFFFF) ~= 0 and EEex_BAnd(inputMode, 0x801) ~= 0
end

EEex_UncapFPS_Private_ResolveScrollStateSwitch = {
	[EEex_UncapFPS_Private_ScrollDirection.UP] = function(state)
		if state == 3 or state == 4 then     -- RIGHT / BOTTOM-RIGHT
			return 2                         -- => TOP-RIGHT
		elseif state == 6 or state == 7 then -- BOTTOM-LEFT / LEFT
			return 8                         -- => TOP-LEFT
		else
			return 1                         -- => UP
		end
	end,
	[EEex_UncapFPS_Private_ScrollDirection.TOP_RIGHT] = function(state)
		return 2                             -- => TOP-RIGHT
	end,
	[EEex_UncapFPS_Private_ScrollDirection.RIGHT] = function(state)
		if state == 1 or state == 8 then     -- UP / TOP-LEFT
			return 2                         -- => TOP-RIGHT
		elseif state == 5 or state == 6 then -- DOWN / BOTTOM-LEFT
			return 4                         -- => BOTTOM-RIGHT
		else
			return 3                         -- => RIGHT
		end
	end,
	[EEex_UncapFPS_Private_ScrollDirection.BOTTOM_RIGHT] = function(state)
		return 4                             -- => BOTTOM-RIGHT
	end,
	[EEex_UncapFPS_Private_ScrollDirection.DOWN] = function(state)
		if state == 2 or state == 3 then     -- TOP-RIGHT / RIGHT
			return 4                         -- => BOTTOM-RIGHT
		elseif state == 7 or state == 8 then -- LEFT / TOP-LEFT
			return 6                         -- => BOTTOM-LEFT
		else
			return 5                         -- => DOWN
		end
	end,
	[EEex_UncapFPS_Private_ScrollDirection.BOTTOM_LEFT] = function(state)
		return 6                             -- => BOTTOM-LEFT
	end,
	[EEex_UncapFPS_Private_ScrollDirection.LEFT] = function(state)
		if state == 1 or state == 2 then     -- UP / TOP-RIGHT
			return 8                         -- => TOP-LEFT
		elseif state == 4 or state == 5 then -- BOTTOM-RIGHT / DOWN
			return 6                         -- => BOTTOM-LEFT
		else
			return 7                         -- => LEFT
		end
	end,
	[EEex_UncapFPS_Private_ScrollDirection.TOP_LEFT] = function(state)
		return 8                             -- => TOP-LEFT
	end,
}

function EEex_UncapFPS_Private_ResolveScrollState(mappedKeys)
	local state = 0
	for _, key in ipairs(EEex_Key_GetPressedStack()) do
		local scrollDirection = EEex_UncapFPS_Private_GetKeyScrollDirection(mappedKeys, key)
		if scrollDirection then
			state = EEex_UncapFPS_Private_ResolveScrollStateSwitch[scrollDirection](state)
		end
	end
	return state
end

---------------
-- Listeners --
---------------

-- Block vanilla handling of scroll keys by consuming the key down/repeat/up events
function EEex_UncapFPS_Private_HandleScrollKeyEvent(key)

	local chitin = EngineGlobals.g_pBaldurChitin
	local game = chitin.m_pObjectGame

	if not EEex_UncapFPS_Private_IsScrollAccepted(game) then
		return
	end

	local mappedKeys = nil

	if chitin.m_pEngineWorld.m_bCtrlKeyDown == 0 then
		local keymap = game.m_pKeymap
		mappedKeys = {
			[1] = keymap:get(33), -- Up
			[2] = keymap:get(34), -- Right
			[3] = keymap:get(35), -- Down
			[4] = keymap:get(36), -- Left
		}
	elseif game.m_options.m_bDebugMode ~= 0 then
		-- Handling cheat keys
		return
	end

	if EEex_UncapFPS_Private_GetKeyScrollDirection(mappedKeys, key) then
		return true -- consume event
	end
end

EEex_Key_AddPressedListener(EEex_UncapFPS_Private_HandleScrollKeyEvent, true)
EEex_Key_AddReleasedListener(EEex_UncapFPS_Private_HandleScrollKeyEvent)

-- Fix the memorization sparkle speed with uncapped fps
EEex_Menu_AddMainFileLoadedListener(function()

	----------------------
	-- Patch Validation --
	----------------------

	if     type(createMageMemorizationSparkle)   ~= "function"
		or type(createPriestMemorizationSparkle) ~= "function"
		or type(memorizationFlashes)             ~= "table"
		or type(updateMemorizationSparkles)      ~= "function"
	then
		return
	end

	local getTemplate = function(templateName)
		local templateHolder = EEex_Menu_GetItem(templateName)
		return templateHolder ~= nil and templateHolder.uiTemplate.item or nil
	end

	local mageTemplate = getTemplate("TEMPLATE_mageMemorizationSparkle")
	if mageTemplate == nil then return end

	local priestTemplate = getTemplate("TEMPLATE_priestMemorizationSparkle")
	if priestTemplate == nil then return end

	----------------------------------------------------------
	-- Wrap creation functions to flag first sparkle render --
	----------------------------------------------------------

	local wrapCreate = function(existingFuncName)
		local existingFunc = _G[existingFuncName]
		_G[existingFuncName] = function(...)
			memorizationFlashes[currentAnimationID].firstRender = true
			return existingFunc(...)
		end
	end

	wrapCreate("createMageMemorizationSparkle")
	wrapCreate("createPriestMemorizationSparkle")

	-------------------------------------------------------------------------------------------------------------------------------------
	-- Modify templates to use `alpha` function for animation update                                                                   --
	-------------------------------------------------------------------------------------------------------------------------------------
	-- Vanilla uses `enabled` for this purpose, which is a bad idea, since `enabled` is called in non-render instances                 --
	-------------------------------------------------------------------------------------------------------------------------------------
	-- This also changes the update method to operate on a single sparkle instance at a time, instead of the weird vanilla bulk update --
	-------------------------------------------------------------------------------------------------------------------------------------

	-- Disable vanilla sparkle update routine
	updateMemorizationSparkles = function() end

	local numFrames = 7
	local frameDuration = 33333
	local totalDuration = numFrames * frameDuration

	local wrapTemplate = function(existingTemplate)

		local existingAlpha = EEex_Menu_GetItemVariant(existingTemplate.alpha)

		EEex_Menu_SetItemVariant(existingTemplate.reference_alpha, function()

			local memorizationFlashInstance = memorizationFlashes[instanceId]

			if memorizationFlashInstance[1] == true then

				local curTime = EEex_Utility_GetMicroseconds()

				if memorizationFlashInstance.firstRender then
					memorizationFlashInstance.firstRender = false
					memorizationFlashInstance.startTime = curTime
				end

				local curDuration = curTime - memorizationFlashInstance.startTime
				local percentage = math.min(curDuration / totalDuration, 1)

				if percentage < 1 then
					memorizationFlashInstance[2] = math.floor(numFrames * percentage)
				else
					memorizationFlashInstance[1] = false
					memorizationFlashInstance[2] = 0
					memorizationFlashInstance[3] = true
				end
			end

			if type(existingAlpha) == "function" then
				return existingAlpha()
			elseif existingAlpha ~= nil then
				return existingAlpha
			else
				return 255
			end
		end)
	end

	wrapTemplate(mageTemplate)
	wrapTemplate(priestTemplate)
end)

-----------
-- Hooks --
-----------

function EEex_UncapFPS_LuaHook_CheckKeyboardScroll()

	local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	local visibleArea = EEex_Area_GetVisible()

	if not EEex_UncapFPS_Private_IsScrollAccepted(game) then
		visibleArea.m_nKeyScrollState = 0
		return
	end

	local keymap = game.m_pKeymap
	mappedKeys = {
		[1] = keymap:get(33), -- Up
		[2] = keymap:get(34), -- Right
		[3] = keymap:get(35), -- Down
		[4] = keymap:get(36), -- Left
	}

	local oldScrollState = visibleArea.m_nKeyScrollState
	local newScrollState = EEex_UncapFPS_Private_ResolveScrollState(mappedKeys)
	visibleArea.m_nKeyScrollState = newScrollState

	if oldScrollState == 0 and newScrollState ~= 0 then
		EEex.UpdateLastScrollTime()
	end
end

function EEex_UncapFPS_LuaHook_OnAfterDrawInit()
	if EEex_UncapFPS_Private_VSyncEnabled:get() ~= 0 then return end
	EEex.SetVSyncEnabled(false, false)
end

--------------------
-- Initialization --
--------------------

-- EEex_Utility_NewScope(function()

-- 	local vmLookingForCall = EEex_Label("CString::Format")

-- 	--=-=-=-=-=-=-=-=-==
-- 	-- START Register ==
-- 	--=-=-=-=-=-=-=-=-==

-- 	Register = {}
-- 	Register.__index = Register

-- 	--////////////
-- 	--// Static //
-- 	--////////////

-- 	Register.new = function(initialValue)
-- 		local o = {}
-- 		setmetatable(o, Register)
-- 		o:_init(initialValue)
-- 		return o
-- 	end

-- 	--//////////////
-- 	--// Instance //
-- 	--//////////////

-- 	-------------
-- 	-- Private --
-- 	-------------

-- 	function Register:_init(initialValue)
-- 		EEex_Utility_CallSuper(Register, "_init", self)
-- 		self._value = initialValue or 0
-- 	end

-- 	------------
-- 	-- Public --
-- 	------------

-- 	function Register:add(toAdd)
-- 		local newValue = self._value + toAdd
-- 		self._value = newValue
-- 		return newValue
-- 	end

-- 	function Register:get()
-- 		return self._value
-- 	end

-- 	function Register:getDword()
-- 		return EEex_BAnd(self._value, 0xFFFFFFFF)
-- 	end

-- 	function Register:set(newValue)
-- 		self._value = newValue
-- 		return newValue
-- 	end

-- 	function Register:setDword(value)
-- 		local newValue = EEex_BOr(EEex_BAnd(self._value, 0xFFFFFFFF00000000), value)
-- 		self._value = newValue
-- 		return newValue
-- 	end

-- 	--=-=-=-=-=-=-=-==
-- 	-- END Register ==
-- 	--=-=-=-=-=-=-=-==

-- 	local vmRegisterRax = Register.new()
-- 	local vmRegisterRbx = Register.new()
-- 	local vmRegisterRcx = Register.new()
-- 	local vmRegisterRdx = Register.new()
-- 	local vmRegisterRsp = Register.new()
-- 	local vmRegisterR8  = Register.new()
-- 	local vmRegisterR9  = Register.new()
-- 	local vmRegisterRip = Register.new(EEex_Label("CChitin::GetVersionString"))
-- 	local vmStack = {}

-- 	local vmReadImmediateByte = function()
-- 		local vmRegisterRipValue = vmRegisterRip:get()
-- 		vmRegisterRip:set(vmRegisterRipValue + 1)
-- 		return EEex_ReadU8(vmRegisterRipValue)
-- 	end

-- 	local vmReadSignedImmediateDword = function()
-- 		local vmRegisterRipValue = vmRegisterRip:get()
-- 		vmRegisterRip:set(vmRegisterRipValue + 4)
-- 		return EEex_Read32(vmRegisterRipValue)
-- 	end

-- 	local vmResolveImmediateRelativeDword = function()
-- 		local vmReadOffset = vmReadSignedImmediateDword()
-- 		return vmRegisterRip:get() + vmReadOffset
-- 	end

-- 	local vmReadImmediateRelativeDword = function()
-- 		return EEex_ReadU32(vmResolveImmediateRelativeDword())
-- 	end

-- 	local vmReadImmediateRelativeQword = function()
-- 		return EEex_ReadU64(vmResolveImmediateRelativeDword())
-- 	end

-- 	local vmOpcodeSwitch = {
-- 		[0x40] = {
-- 			-- push rbx
-- 			[0x53] = function()
-- 				vmStack[vmRegisterRsp:add(-4)] = vmRegisterRbx:get()
-- 			end,
-- 		},
-- 		[0x44] = {
-- 			[0x8B] = {
-- 				-- mov r8d, dword ptr ds:[<relative dword>]
-- 				[0x05] = function()
-- 					vmRegisterR8:setDword(vmReadImmediateRelativeDword())
-- 				end,
-- 				-- mov r9d, dword ptr ds:[<relative dword>]
-- 				[0x0D] = function()
-- 					vmRegisterR9:setDword(vmReadImmediateRelativeDword())
-- 				end,
-- 			},
-- 		},
-- 		[0x48] = {
-- 			[0x83] = {
-- 				-- sub rsp, <byte>
-- 				[0xEC] = function()
-- 					vmRegisterRsp:add(-vmReadImmediateByte())
-- 				end,
-- 			},
-- 			[0x89] = {
-- 				-- mov qword ptr ds:[rcx], rax
-- 				[0x01] = function()
-- 					-- Ignored
-- 				end,
-- 			},
-- 			[0x8B] = {
-- 				-- mov rax, qword ptr ds:[<relative dword>]
-- 				[0x05] = function()
-- 					vmRegisterRax:set(vmReadImmediateRelativeQword())
-- 				end,
-- 				-- mov rbx, rcx
-- 				[0xD9] = function()
-- 					vmRegisterRbx:set(vmRegisterRcx:get())
-- 				end,
-- 			},
-- 			[0x8D] = {
-- 				-- lea rdx, qword ptr ds:[<relative dword>]
-- 				[0x15] = function()
-- 					vmRegisterRdx:set(vmResolveImmediateRelativeDword())
-- 				end,
-- 			},
-- 		},
-- 		[0x89] = {
-- 			[0x44] = {
-- 				-- mov dword ptr ss:[rsp+<byte>], eax
-- 				[0x24] = function()
-- 					vmStack[vmRegisterRsp:get() + vmReadImmediateByte()] = vmRegisterRax:getDword()
-- 				end,
-- 			},
-- 		},
-- 		[0x8B] = {
-- 			-- mov eax, dword ptr ds:[<relative dword>]
-- 			[0x05] = function()
-- 				vmRegisterRax:setDword(vmReadImmediateRelativeDword())
-- 			end,
-- 		},
-- 		-- call <relative dword>
-- 		[0xE8] = function()

-- 			local vmCallTarget = vmResolveImmediateRelativeDword()

-- 			if vmCallTarget == vmLookingForCall then

-- 				local vmRegisterRspValue = vmRegisterRsp:get()

-- 				local nVersionMajor  = vmRegisterR8:get()
-- 				local nVersionMinor  = vmRegisterR9:get()
-- 				local nVersionPatch  = vmStack[vmRegisterRspValue + 0x20]
-- 				local nVersionHotfix = vmStack[vmRegisterRspValue + 0x28]

-- 				print(string.format("nVersionMajor: 0x%X, nVersionMinor: 0x%X, nVersionPatch: 0x%X, nVersionHotfix: 0x%X",
-- 					nVersionMajor, nVersionMinor, nVersionPatch, nVersionHotfix))

-- 				return true
-- 			end
-- 		end,
-- 	}

-- 	local vmCurOpcodeSwitch = vmOpcodeSwitch
-- 	local vmCurInstructionOpcodeLength = 0

-- 	while true do

-- 		vmCurInstructionOpcodeLength = vmCurInstructionOpcodeLength + 1

-- 		local vmRegisterRipValue = vmRegisterRip:get()
-- 		local vmOpcode = EEex_ReadU8(vmRegisterRipValue)
-- 		local vmCurResolvedOpcode = vmCurOpcodeSwitch[vmOpcode]
-- 		local vmCurResolvedOpcodeType = type(vmCurResolvedOpcode)

-- 		if vmCurResolvedOpcodeType == "table" then
-- 			vmRegisterRip:set(vmRegisterRipValue + 1)
-- 			vmCurOpcodeSwitch = vmCurResolvedOpcode
-- 		elseif vmCurResolvedOpcodeType == "function" then
-- 			vmRegisterRip:set(vmRegisterRipValue + 1)
-- 			if vmCurResolvedOpcode() then
-- 				break
-- 			end
-- 			vmCurOpcodeSwitch = vmOpcodeSwitch
-- 			vmCurInstructionOpcodeLength = 0
-- 		else
-- 			EEex_Error(string.format("Unhandled vmCurResolvedOpcode at [0x%X]: 0x%X", vmRegisterRipValue, vmOpcode))
-- 		end
-- 	end
-- end)
