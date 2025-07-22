
B3Invis_Private_RenderAsInvisible = true

function B3Invis_Private_CanSelectedSeeInvis()
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
	return B3Invis_Private_CanSelectedSeeInvis()
end

function B3Invis_Hook_ForceCircle(target)
	return target.m_bInvisible ~= 0 and B3Invis_Private_CanSelectedSeeInvis()
end

(function()

	EEex_DisableCodeProtection()

	--[[
	+------------------------------------------------------------------------------------------------------+
	| Allow cursor to interact with invisible creatures if a selected creature has op193                   |
	+------------------------------------------------------------------------------------------------------+
	|   [Lua] B3Invis_Hook_CanSeeInvisible() -> boolean                                                    |
	|       return:                                                                                        |
	|           -> false - Don't alter engine behavior                                                     |
	|           -> true  - Allow the cursor to interact with the creature regardless of it being invisible |
	+------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::IsOver()-B3Invis"), 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
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

	--[[
	+---------------------------------------------------------------------------------------+
	| Allow invisible creature markers to render if a selected creature has op193           |
	+---------------------------------------------------------------------------------------+
	|   [Lua] B3Invis_Hook_CanSeeInvisible() -> boolean                                     |
	|       return:                                                                         |
	|           -> false - Don't alter engine behavior                                      |
	|           -> true  - Force the creature's marker to not be hidden due to invisibility |
	+---------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::RenderMarkers()-B3Invis1"), 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
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

	if B3Invis_Private_RenderAsInvisible then

		--[[
		+---------------------------------------------------------------------------------------------------------------------+
		| (Option #1) Render invisible creatures as transparent (like improved invisibility) if a selected creature has op193 |
		+---------------------------------------------------------------------------------------------------------------------+
		|   [Lua] B3Invis_Hook_CanSeeInvisible() -> boolean                                                                   |
		|       return:                                                                                                       |
		|           -> false - Don't alter engine behavior                                                                    |
		|           -> true  - Force the creature to be rendered as transparent                                               |
		+---------------------------------------------------------------------------------------------------------------------+
		--]]

		EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameSprite::Render()-B3Invis"), 6, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
				EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
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

		--[[
		+-------------------------------------------------------------------------------------------------------+
		| (Option #2) Render invisible creatures with an always-visible marker if a selected creature has op193 |
		+-------------------------------------------------------------------------------------------------------+
		|   [Lua] B3Invis_Hook_ForceCircle(sprite: CGameSprite) -> boolean                                      |
		|       return:                                                                                         |
		|           -> false - Don't alter engine behavior                                                      |
		|           -> true  - Force the creature's marker to render                                            |
		+-------------------------------------------------------------------------------------------------------+
		--]]

		EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CGameSprite::RenderMarkers()-B3Invis2"), 0, 6, 6, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
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
