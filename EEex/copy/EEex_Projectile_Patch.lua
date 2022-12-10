
(function()

	EEex_DisableCodeProtection()

	-----------------------------------------
	-- EEex_Projectile_Hook_OnBeforeDecode --
	-----------------------------------------

	EEex_HookBeforeRestore(EEex_Label("CProjectile::DecodeProjectile"), 0, 5, 5, EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(72)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
		]]},
		EEex_GenLuaCall("EEex_Projectile_Hook_OnBeforeDecode", {
			["args"] = {
				function(rspOffset) return {[[
					and rcx, 0xFFFF
					mov qword ptr ss:[rsp+#$(1)], rcx
				]], {rspOffset}} end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx #ENDL", {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(0)]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}} end,
			},
			["returnType"] = EEex_LuaCallReturnType.Number,
		}),
		{[[
			cmp rax, -1
			je call_error

			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, rax
			#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
			jmp return

			call_error:
			#RESUME_SHADOW_ENTRY
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	----------------------------------------
	-- EEex_Projectile_Hook_OnAfterDecode --
	----------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CProjectile::DecodeProjectile()-LastCall"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(56)
		]]},
		EEex_GenLuaCall("EEex_Projectile_Hook_OnAfterDecode", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CProjectile", "EEex_Projectile_CastUT" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(408)]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}} end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	------------------------------------------
	-- EEex_Projectile_Hook_BeforeAddEffect --
	------------------------------------------

	-- This is very ugly, but since CProjectile::AddEffect() isn't passed the
	-- source aiBase, I have to go and manually define where the aiBase
	-- is currently saved for the given CProjectile::AddEffect() call.
	local getAddEffectAIBase = EEex_JITNear({[[

		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::ForceSpell()-CProjectile::AddEffect()-RetPtr")}, [[       ; 0x14016CE36
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::ForceSpell()-CProjectile::AddEffect()-RetPtr-2")}, [[     ; 0x14016CE53
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::ForceSpellPoint()-CProjectile::AddEffect()-RetPtr")}, [[  ; 0x14016DEA4
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Spell()-CProjectile::AddEffect()-RetPtr")}, [[            ; 0x1403B5238
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Spell()-CProjectile::AddEffect()-RetPtr-2")}, [[          ; 0x1403B5259
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::SpellPoint()-CProjectile::AddEffect()-RetPtr")}, [[       ; 0x1403B6DE2
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Swing()-CProjectile::AddEffect()-RetPtr")}, [[            ; 0x1403B88B3
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::Swing()-CProjectile::AddEffect()-RetPtr-2")}, [[          ; 0x1403B9291
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::UseItem()-CProjectile::AddEffect()-RetPtr")}, [[          ; 0x1403BB59A
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::UseItem()-CProjectile::AddEffect()-RetPtr-2")}, [[        ; 0x1403BB5BF
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameSprite::UseItemPoint()-CProjectile::AddEffect()-RetPtr")}, [[     ; 0x1403BC0DA
		cmp rcx, rax
		je in_rbx
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpell()-CProjectile::AddEffect()-RetPtr")}, [[        ; 0x14016AE6F
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpell()-CProjectile::AddEffect()-RetPtr-2")}, [[      ; 0x14016AFE2
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpellPoint()-CProjectile::AddEffect()-RetPtr")}, [[   ; 0x14016BC3B
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireSpellPoint()-CProjectile::AddEffect()-RetPtr-2")}, [[ ; 0x14016BCAD
		cmp rcx, rax
		je in_r14
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireItem()-CProjectile::AddEffect()-RetPtr")}, [[         ; 0x14016A465
		cmp rcx, rax
		je in_rbp
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireItem()-CProjectile::AddEffect()-RetPtr-2")}, [[       ; 0x14016A487
		cmp rcx, rax
		je in_rbp
		mov rax, #$(1) ]], {EEex_Label("Data-CBounceList::Add()-CProjectile::AddEffect()-RetPtr")}, [[              ; 0x14014C7DB
		cmp rcx, rax
		je in_r15
		mov rax, #$(1) ]], {EEex_Label("Data-CBounceList::Add()-CProjectile::AddEffect()-RetPtr-2")}, [[            ; 0x14014C82E
		cmp rcx, rax
		je in_r15
		mov rax, #$(1) ]], {EEex_Label("Data-CGameEffect::FireSpell()-CProjectile::AddEffect()-RetPtr")}, [[        ; 0x1401E4715
		cmp rcx, rax
		je source_id_on_stack
		mov rax, #$(1) ]], {EEex_Label("Data-CGameEffect::FireSpell()-CProjectile::AddEffect()-RetPtr-2")}, [[      ; 0x1401E4793
		cmp rcx, rax
		je source_id_on_stack
		mov rax, #$(1) ]], {EEex_Label("Data-CGameAIBase::FireItemPoint()-CProjectile::AddEffect()-RetPtr")}, [[    ; 0x14016A7F3
		cmp rcx, rax
		je in_rsi

		xor rax, rax
		ret

		in_rbx:
		mov rax, rbx
		ret

		in_r14:
		mov rax, r14
		ret

		in_rbp:
		mov rax, rbp
		ret

		in_r15:
		mov rax, r15
		ret

		source_id_on_stack:
		#STACK_MOD(8) ; This was called, the ret ptr broke alignment
		#MAKE_SHADOW_SPACE(16)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx

		mov ecx, dword ptr ss:[rbp+0x7F]
		lea rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
		mov qword ptr ss:[rdx], 0
		call #L(CGameObjectArray::GetShare)
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]

		mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
		ret

		in_rsi:
		mov rax, rsi
		ret
	]]})

	EEex_HookBeforeRestore(EEex_Label("CProjectile::AddEffect"), 0, 8, 8, EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(80)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
		]]},
		EEex_GenLuaCall("EEex_Projectile_Hook_BeforeAddEffect", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CProjectile", "EEex_Projectile_CastUT" end,
				function(rspOffset) return {[[
					mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(0)]
					call #$(1) ]], {getAddEffectAIBase}, [[ #ENDL
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx #ENDL", {rspOffset}}, "CGameEffect" end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(0)]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}} end,
			},
		}),
		{[[
			call_error:
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
