
(function()

	EEex_DisableCodeProtection()

	-------------------------------------------
	-- EEex_Sprite_Hook_CheckSuppressTooltip --
	-------------------------------------------

	EEex_HookRelativeBranch(EEex_Label("Hook-CGameSprite::SetCursor()-SetCharacterToolTip()"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
		]]},
		EEex_GenLuaCall("EEex_Sprite_Hook_CheckSuppressTooltip", {
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor rax, rax

			no_error:
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
			test rax, rax
			jnz #L(return)
			call #L(original)
			jmp #L(return)
		]]},
	}))

	----------------------------------
	-- EEex_Sprite_Hook_OnConstruct --
	----------------------------------

	for _, labelName in ipairs({
		"Hook-CGameSprite::Construct1()-FirstCall",
		"Hook-CGameSprite::Construct2()-FirstCall"
	}) do
		EEex_HookAfterCall(EEex_Label(labelName), EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnConstruct", {
				["args"] = {
					function(rspOffset) return {[[
						mov qword ptr ss:[rsp+#$1], rsi
					]], {rspOffset}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		}))
	end

	---------------------------------
	-- EEex_Sprite_Hook_OnDestruct --
	---------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Destruct()-FirstCall"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Sprite_Hook_OnDestruct", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], rbx
				]], {rspOffset}}, "CGameSprite" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
