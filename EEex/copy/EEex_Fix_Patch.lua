
(function()

	EEex_DisableCodeProtection()

	EEex_HookJumpOnFail(EEex_Label("Hook-CGameEffect::CheckAdd()-FixSpellImmunityShouldSkipItemIndexing"), 4, EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Fix_Hook_SpellImmunityShouldSkipItemIndexing", {
			["args"] = {
				function(rspOffset) return {[[
					mov rax, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(50h)]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}, "#ENDL"}, "CGameObject" end,
			},
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
	}))

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::AddSpecialAbility()-LastCall"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Fix_Hook_OnAddSpecialAbility", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "CGameSprite" end,
				function(rspOffset) return {[[
					lea rax, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(48h)]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}}, "CSpell" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	----------------------------------------------------------------------------------
	-- Fix Spell() and SpellPoint() not being disruptable if the creature is facing --
	-- SSW(1), SWW(3), NWW(5), NNW(7), NNE(9), NEE(11), SEE(13), or SSE(15)         --
	----------------------------------------------------------------------------------

	--------------------------------------------------
	-- EEex_Fix_Hook_ShouldForceMainSpellActionCode --
	--------------------------------------------------

	local callShouldForceMainSpellActionCode = EEex_JITNear(EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Fix_Hook_ShouldForceMainSpellActionCode", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CGameSprite" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx #ENDL", {rspOffset}}, "CPoint" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor rax, rax

			no_error:
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}))

	EEex_HookJumpOnFail(EEex_Label("Hook-CGameSprite::Spell()-CheckDirectionJmp"), 3, {[[
		mov rdx, r14
		mov rcx, rbx
		call short #$(1) ]], {callShouldForceMainSpellActionCode}, [[ #ENDL
		test rax, rax
		jnz #L(jmp_success)
	]]})

	EEex_HookJumpOnFail(EEex_Label("Hook-CGameSprite::SpellPoint()-CheckDirectionJmp"), 5, {[[
		lea rdx, qword ptr ss:[rsp+0x60]
		mov rcx, rbx
		call short #$(1) ]], {callShouldForceMainSpellActionCode}, [[ #ENDL
		test rax, rax
		jnz #L(jmp_success)
	]]})

	---------------------------------------------------------
	-- EEex_Fix_Hook_OnSpellOrSpellPointStartedCastingGlow --
	---------------------------------------------------------

	local callOnSpellOrSpellPointStartedCastingGlow = EEex_JITNear(EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Fix_Hook_OnSpellOrSpellPointStartedCastingGlow", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CGameSprite" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}))

	for _, address in ipairs({
		EEex_Label("Hook-CGameSprite::Spell()-ApplyCastingEffect()"),
		EEex_Label("Hook-CGameSprite::SpellPoint()-ApplyCastingEffect()")
	}) do
		EEex_HookAfterCall(address, {[[
			mov rcx, rbx
			call short #$(1) ]], {callOnSpellOrSpellPointStartedCastingGlow}, [[ #ENDL
		]]})
	end

	-----------------------------------------------------------------------------------------------------------------------------------
	-- Opcode #182 (make sure the engine considers "-1" (instead of 0) the fail return value from "CGameSprite::FindItemPersonal()") --
	-----------------------------------------------------------------------------------------------------------------------------------

	EEex_HookJump(0x1401A6D7E, 0, {[[
		cmp ax, -1
	]]})

	EEex_EnableCodeProtection()

end)()
