
(function()

	EEex_DisableCodeProtection()

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

	EEex_EnableCodeProtection()

end)()
