
(function()

	EEex_DisableCodeProtection()

	-----------------------------
	-- EEex_Script_Hook_OnRead --
	-----------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CAIScript::Read()-OnRead"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Script_Hook_OnRead", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "CAIScript" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r14 #ENDL", {rspOffset}} end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	-----------------------------
	-- EEex_Script_Hook_OnCopy --
	-----------------------------

	for _, entry in ipairs({
		{"Hook-CAIScript::Construct()-OnCopy1", "rdi"},
		{"Hook-CAIScript::Construct()-OnCopy2", "rsi"}, })
	do
		EEex_HookBeforeCall(EEex_Label(entry[1]), EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(64)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			]]},
			EEex_GenLuaCall("EEex_Script_Hook_OnCopy", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CAIScript" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], #$(2) #ENDL", {rspOffset, entry[2]}}, "CAIScript" end,
				},
			}),
			{[[
				call_error:
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		}))
	end

	---------------------------------
	-- EEex_Script_Hook_OnDestruct --
	---------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CAIScript::Destruct()-OnDestruct"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Script_Hook_OnDestruct", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "CAIScript" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
