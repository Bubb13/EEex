
B3Scale_Percentage = nil

EEex_GameState_AddInitializedListener(function()
	B3Scale_Percentage = Infinity_GetINIValue("B3Scale", "Percentage", -1)
end)

-- p = [0-1], where 0 is minimum scaling and 1 is maximum scaling
function B3Scale_SetPercentage(p)
	B3Scale_Percentage = math.min(math.max(0, p), 1)
	Infinity_SetINIValue("B3Scale", "Percentage", B3Scale_Percentage)
	B3Scale_PokeEngine()
end

function B3Scale_GetVideoSize()
	local pVidMode = EEex_EngineGlobal_CBaldurChitin.cVideo.pCurrentMode
	return pVidMode.nWidth, pVidMode.nHeight
end

function B3Scale_PokeEngine()
	local w, h = B3Scale_GetVideoSize()
	EEex_EngineGlobal_CBaldurChitin:OnResizeWindow(w, h)
end

function B3Scale_Hook_DoSizeChange()

	if B3Scale_Percentage == -1 then
		return
	end

	local w, h = B3Scale_GetVideoSize()
	local scaledH = 768 + (1 - B3Scale_Percentage) * (h - 768)
	local scaledW = math.floor(scaledH * (w / h))

	CVidMode.SCREENWIDTH = scaledW
	CVidMode.SCREENHEIGHT = scaledH
end

(function()

	EEex_DisableCodeProtection()

	EEex_HookAfterCall(EEex_Label("Hook-CChitin::OnResizeWindow()-B3Scale"), EEex_FlattenTable({[[
		#MAKE_SHADOW_SPACE(32)
		]], EEex_GenLuaCall("B3Scale_Hook_DoSizeChange"), [[
		call_error:
		#DESTROY_SHADOW_SPACE
	]]}))

	EEex_EnableCodeProtection()

end)()
