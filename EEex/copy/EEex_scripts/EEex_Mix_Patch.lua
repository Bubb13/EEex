
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

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-Ranged"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(72)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
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

	---------------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_ApplyMissMeleeEffects() --
	---------------------------------------------------------

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameSprite::Swing()-MeleeMissResultJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE
			mov rdx, r15                              ; target
			mov rcx, rbx                              ; attacker
			call #L(EEex::Opcode_Hook_ApplyMissMeleeEffects)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	----------------------------------------------------------
	-- [EEex.dll] EEex::Opcode_Hook_ApplyMissRangedEffects() --
	----------------------------------------------------------

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CGameSprite::Swing()-RangedMissResultJmp"), 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE
			mov rdx, r15                              ; target
			mov rcx, rbx                              ; attacker
			call #L(EEex::Opcode_Hook_ApplyMissRangedEffects)
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_EnableCodeProtection()

end)()
