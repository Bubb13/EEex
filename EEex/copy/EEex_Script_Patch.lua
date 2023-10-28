
(function()

	EEex_DisableCodeProtection()

	-------------------------------------------
	-- [EEex.dll] EEex::Script_Hook_OnRead() --
	-------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CAIScript::Read()-OnRead"), {[[
		mov rdx, r14 ; bPlayerScript
		mov rcx, rsi ; pScript
		call #L(EEex::Script_Hook_OnRead)
	]]})

	-------------------------------------------
	-- [EEex.dll] EEex::Script_Hook_OnCopy() --
	-------------------------------------------

	for _, entry in ipairs({
		{"Hook-CAIScript::Construct()-OnCopy1", "rdi"},
		{"Hook-CAIScript::Construct()-OnCopy2", "rsi"}, })
	do
		EEex_HookBeforeCall(EEex_Label(entry[1]), {[[

			#MAKE_SHADOW_SPACE(16)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx

			mov rdx, #$(2) ]], entry, [[ ; pDstScript
										 ; rcx already pSrcScript
			call #L(EEex::Script_Hook_OnCopy)

			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]})
	end

	-----------------------------------------------
	-- [EEex.dll] EEex::Script_Hook_OnDestruct() --
	-----------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CAIScript::Destruct()-OnDestruct"), {[[
		mov rcx, rsi ; pScript
		call #L(EEex::Script_Hook_OnDestruct)
	]]})

	EEex_EnableCodeProtection()

end)()
