
-------------------------------------------------------------------------------------------------------------------
-- This file contains patches that hook the same executable location, but call out to different EEex_*.lua files --
-------------------------------------------------------------------------------------------------------------------

(function()

	EEex_DisableCodeProtection()

	-------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_CheckBlockWeaponHit()      --
	-- [Lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp248() --
	-------------------------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-Melee"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(72)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax

				mov rcx, rbx                                    ; attackingSprite
				mov rdx, r15                                    ; targetSprite
				mov r8, r12                                     ; weapon
				mov r9, qword ptr ds:[rsp+#LAST_FRAME_TOP(68h)] ; weaponAbility
				call #L(EEex::Sprite_Hook_OnCheckBlockWeaponHit)

				test al, al
				jz do_not_block_base_weapon_damage_and_onhit_effects

				#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
				jmp #L(return)

				do_not_block_base_weapon_damage_and_onhit_effects:
				#RESUME_SHADOW_ENTRY
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			]]},
			EEex_GenLuaCall("EEex_Opcode_Hook_OnAfterSwingCheckedOp248", {
				["labelSuffix"] = "_2",
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rax #ENDL", {rspOffset}}, "boolean" end,
				},
			}),
			{[[
				call_error_2:
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	-------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_CheckBlockWeaponHit()      --
	-- [Lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp249() --
	-------------------------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-Ranged"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(72)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax

				mov rcx, rbx                                    ; attackingSprite
				mov rdx, r15                                    ; targetSprite
				mov r8, rdi                                     ; weapon
				mov r9, qword ptr ds:[rsp+#LAST_FRAME_TOP(68h)] ; weaponAbility
				call #L(EEex::Sprite_Hook_OnCheckBlockWeaponHit)

				test al, al
				jz do_not_block_base_weapon_damage_and_onhit_effects

				#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
				jmp #L(return)

				do_not_block_base_weapon_damage_and_onhit_effects:
				#RESUME_SHADOW_ENTRY
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			]]},
			EEex_GenLuaCall("EEex_Opcode_Hook_OnAfterSwingCheckedOp249", {
				["labelSuffix"] = "_2",
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rax #ENDL", {rspOffset}}, "boolean" end,
				},
			}),
			{[[
				call_error_2:
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE

				test rax, rax
				jz #L(return)

				#MANUAL_HOOK_EXIT(0)
				; The consequence of not running the else block is that this boilerplate is not executed
				mov rsi, qword ptr ss:[rsp+0x70]
				lea r13, qword ptr ds:[r15+0xC]
				jmp #L(Hook-CGameSprite::Swing()-NoCImmunitiesWeaponElseContinue)
			]]},
		})
	)

	EEex_EnableCodeProtection()

end)()
