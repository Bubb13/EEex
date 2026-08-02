
-------------------------------------------------------------------------------------------------------------------
-- This file contains patches that hook the same executable location, but call out to different EEex_*.lua files --
-------------------------------------------------------------------------------------------------------------------

(function()

	EEex_DisableCodeProtection()

	-------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_CheckBlockWeaponHit()      --
	-- [Lua] EEex_Opcode_Hook_OnAfterSwingCheckedOp248() --
	-------------------------------------------------------

	-- r15 holds the resolved melee target at this point. Let op418 replace it before
	-- base weapon damage, weapon on-hit effects, and the existing Lua hooks observe it.
	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-Melee"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R15}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(112)
				; Preserve volatile registers across the C++ resolver; this hook runs
				; immediately before the existing Lua calls that still need swing state.
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r9
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r10
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11

				; The resolver returns either the original target or the captive that
				; should receive this weapon hit.
				mov rcx, r15
				mov rdx, r15
				call #L(EEex::Opcode_Hook_Constrict_ResolveRedirectTarget)
				mov r15, rax

				mov r11, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)]
				mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)]
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_CheckBlockWeaponHit", {
				["labelSuffix"] = "_1",
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end, -- attackingSprite
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "CGameSprite" end, -- targetSprite
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r12 #ENDL", {rspOffset}}, "CItem" end, -- weapon
					-- weaponAbility
					function(rspOffset) return {[[
						mov rax, qword ptr ds:[rsp+#LAST_FRAME_TOP(68h)]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]}, "Item_ability_st" end,
				},
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error_1

				call_error_1:
				xor rax, rax

				no_error_1:
				test rax, rax
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

	-- r15 is also the live target for the ranged path; redirect it before any later
	-- damage/on-hit consumers read the target register.
	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-Ranged"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R15}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(112)
				; Preserve volatile registers across the C++ resolver; this hook runs
				; immediately before the existing Lua calls that still need swing state.
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r9
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r10
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11

				; The resolver returns either the original target or the captive that
				; should receive this weapon hit.
				mov rcx, r15
				mov rdx, r15
				call #L(EEex::Opcode_Hook_Constrict_ResolveRedirectTarget)
				mov r15, rax

				mov r11, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-56)]
				mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-48)]
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_CheckBlockWeaponHit", {
				["labelSuffix"] = "_1",
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end, -- attackingSprite
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "CGameSprite" end, -- targetSprite
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdi #ENDL", {rspOffset}}, "CItem" end, -- weapon
					-- weaponAbility
					function(rspOffset) return {[[
						mov rax, qword ptr ds:[rsp+#LAST_FRAME_TOP(68h)]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]}, "Item_ability_st" end,
				},
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error_1

				call_error_1:
				xor rax, rax

				no_error_1:
				test rax, rax
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
