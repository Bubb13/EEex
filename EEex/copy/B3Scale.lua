
--===========
-- Options ==
--===========

B3Scale_Private_Percentage = EEex_Options_Register(EEex_Options_Option.new({
	["id"]       = "B3Scale_Percentage",
	["default"]  = 1,
	["type"]     = EEex_Options_EditType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({
		["min"]      = 0,
		["max"]      = 1,
		["floating"] = true,
	}),
	["storage"]  = EEex_Options_NumberINIStorage.new({ ["section"] = "EEex", ["key"] = "Scale Percentage" }),
	["onChange"] = function() B3Scale_Private_PokeEngine() end
}))

EEex_Options_AddTab("Scale Module", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["name"]     = "Scale Percentage [0-1]",
			["optionID"] = "B3Scale_Percentage",
			["widget"]   = EEex_Options_EditWidget.new({
				["maxCharacters"] = 5,
				["number"]        = true,
			}),
		}),
	},
} end)

--===========
-- General ==
--===========

------------
-- Public --
------------

-- p = [0-1], where 0 is minimum scaling and 1 is maximum scaling
function B3Scale_SetPercentage(p)
	B3Scale_Private_Percentage:set(p)
end

-------------
-- Private --
-------------

-- Tweak the UI scale whenever the window is resized (called directly by EEex)
function B3Scale_Private_DoSizeChange()

	local w, h = B3Scale_Private_GetVideoSize(EngineGlobals.g_pBaldurChitin)
	local ratio = math.max(1.25, math.min(w / h, 2.6))

	if ratio <= 4/3 then
		-- UI wasn't designed for this ratio, no scaling.
		return
	end

	local scaledH = w >= 1024 and h >= 768
		and 768 + (1 - B3Scale_Private_Percentage:get()) * (h - 768)
		or 768

	CVidMode.SCREENWIDTH = math.floor(scaledH * ratio)
	CVidMode.SCREENHEIGHT = math.floor(scaledH)
end

function B3Scale_Private_GetVideoSize(chitin)
	local pVidMode = chitin.cVideo.pCurrentMode
	return pVidMode.nWidth, pVidMode.nHeight
end

function B3Scale_Private_PokeEngine()
	local chitin = EngineGlobals.g_pBaldurChitin
	if chitin.pActiveEngine == nil then return end
	local w, h = B3Scale_Private_GetVideoSize(chitin)
	chitin:OnResizeWindow(w, h)
end
