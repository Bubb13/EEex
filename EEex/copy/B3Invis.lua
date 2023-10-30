
B3Invis_RenderAsInvisible = true

function B3Invis_CanSelectedSeeInvis()
	local toReturn = false
	EEex_Sprite_IterateSelected(function(sprite)
		if sprite:getActiveStats().m_bSeeInvisible ~= 0 then
			toReturn = true
			return true
		end
	end)
	return toReturn
end

function B3Invis_Hook_CanSeeInvisible()
	return B3Invis_CanSelectedSeeInvis()
end

function B3Invis_Hook_ForceCircle(target)
	return target.m_bInvisible ~= 0 and B3Invis_CanSelectedSeeInvis()
end

(function()

	EEex_DisableCodeProtection()

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::IsOver()-B3Invis"), 7, {
		{"integrity_ignore_registers", {
			EEex_IntegrityRegister.RAX, EEex_IntegrityRegister.RCX, EEex_IntegrityRegister.RDX, EEex_IntegrityRegister.R8,
			EEex_IntegrityRegister.R9, EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(32)
			]]},
			EEex_GenLuaCall("B3Invis_Hook_CanSeeInvisible", {
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error

				call_error:
				xor rax, rax

				no_error:
				test rax, rax

				#DESTROY_SHADOW_SPACE
				jnz #L(jmp_success)
			]]},
		})
	)

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::RenderMarkers()-B3Invis1"), 7, {
		{"integrity_ignore_registers", {
			EEex_IntegrityRegister.RAX, EEex_IntegrityRegister.RCX, EEex_IntegrityRegister.RDX,
			EEex_IntegrityRegister.R8, EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], r9
			]]},
			EEex_GenLuaCall("B3Invis_Hook_CanSeeInvisible", {
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error

				call_error:
				xor rax, rax

				no_error:
				test rax, rax

				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
				jnz #L(jmp_success)
			]]},
		})
	)

	if B3Invis_RenderAsInvisible then

		EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameSprite::Render()-B3Invis"), 6, {
			{"integrity_ignore_registers", {
				EEex_IntegrityRegister.RAX, EEex_IntegrityRegister.R8, EEex_IntegrityRegister.R9,
				EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
			}}},
			EEex_FlattenTable({
				{[[
					#MAKE_SHADOW_SPACE(48)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
				]]},
				EEex_GenLuaCall("B3Invis_Hook_CanSeeInvisible", {
					["returnType"] = EEex_LuaCallReturnType.Boolean,
				}),
				{[[
					jmp no_error

					call_error:
					xor rax, rax

					no_error:
					test rax, rax

					mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
					jnz #L(jmp_fail)
				]]},
			})
		)
	else
		-- Force circle
		EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CGameSprite::RenderMarkers()-B3Invis2"), 0, 6, 6, {
			{"integrity_ignore_registers", {
				EEex_IntegrityRegister.R8, EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
			}}},
			EEex_FlattenTable({
				{[[
					jnz #L(return)

					#MAKE_SHADOW_SPACE(72)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rcx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rdx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
				]]},
				EEex_GenLuaCall("B3Invis_Hook_ForceCircle", {
					["args"] = {
						function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "CGameSprite" end,
					},
					["returnType"] = EEex_LuaCallReturnType.Boolean,
				}),
				{[[
					jmp no_error

					call_error:
					xor rax, rax

					no_error:
					test rax, rax

					mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
					mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
					mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
				]]},
			})
		)
	end

	EEex_EnableCodeProtection()

end)()
