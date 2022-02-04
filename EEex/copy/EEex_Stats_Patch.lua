
(function()

	EEex_DisableCodeProtection()

	---------------------------------
	-- EEex_Stats_Hook_OnConstruct --
	---------------------------------
	
	EEex_HookAfterCall(EEex_Label("Hook-CDerivedStats::Construct()-FirstCall"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Stats_Hook_OnConstruct", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], rsi
				]], {rspOffset}}, "CDerivedStats" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	--------------------------------
	-- EEex_Stats_Hook_OnDestruct --
	--------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CDerivedStats::Destruct()-FirstCall"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Stats_Hook_OnDestruct", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], rdi
				]], {rspOffset}}, "CDerivedStats" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	------------------------------
	-- EEex_Stats_Hook_OnReload --
	------------------------------

	local statsReloadTemplate = function(spriteRegStr)
		return EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Stats_Hook_OnReload", {
				["args"] = {
					function(rspOffset) return {[[
						mov qword ptr ss:[rsp+#$1], #$2
					]], {rspOffset, spriteRegStr}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	end

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::QuickLoad()-CDerivedStats::Reload()"), statsReloadTemplate("rdi"))
	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Unmarshal()-CDerivedStats::Reload()-1"), statsReloadTemplate("rbx"))
	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Unmarshal()-CDerivedStats::Reload()-2"), statsReloadTemplate("rbx"))
	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::ProcessEffectList()-CDerivedStats::Reload()"), statsReloadTemplate("rsi"))

	---------------------------
	-- EEex_Stats_Hook_OnEqu --
	---------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CDerivedStats::operator_equ()-FirstCall"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Stats_Hook_OnEqu", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], r14
				]], {rspOffset}}, "CDerivedStats" end,
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], rsi
				]], {rspOffset}}, "CDerivedStats" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	-------------------------------
	-- EEex_Stats_Hook_OnPlusEqu --
	-------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CDerivedStats::operator_plus_equ()-FirstCall"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Stats_Hook_OnPlusEqu", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], rbx
				]], {rspOffset}}, "CDerivedStats" end,
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], rdi
				]], {rspOffset}}, "CDerivedStats" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	--------------------------------------
	-- EEex_Stats_Hook_OnGettingUnknown --
	--------------------------------------

	EEex_HookJumpOnSuccess(EEex_Label("Hook-CDerivedStats::GetAtOffset()-OutOfBoundsJmp"), 0, EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)
			inc eax
		]]},
		EEex_GenLuaCall("EEex_Stats_Hook_OnGettingUnknown", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rcx #ENDL", {rspOffset}}, "CDerivedStats" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rax #ENDL", {rspOffset}} end,
			},
			["returnType"] = EEex_LuaCallReturnType.Number,
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

	EEex_EnableCodeProtection()

end)()
