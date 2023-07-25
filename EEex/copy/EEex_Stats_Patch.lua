
(function()

	EEex_DisableCodeProtection()

	-----------------------------------------------
	-- [EEex.dll] EEex::Stats_Hook_OnConstruct() --
	-----------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CDerivedStats::Construct()-FirstCall"), {[[
		mov rcx, rsi ; pStats
		call #L(EEex::Stats_Hook_OnConstruct)
	]]})

	----------------------------------------------
	-- [EEex.dll] EEex::Stats_Hook_OnDestruct() --
	----------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CDerivedStats::Destruct()-FirstCall"), {[[
		mov rcx, rdi ; pStats
		call #L(EEex::Stats_Hook_OnDestruct)
	]]})

	--------------------------------------------
	-- [EEex.dll] EEex::Stats_Hook_OnReload() --
	--------------------------------------------

	local statsReloadTemplate = function(spriteRegStr)
		return {[[
			mov rcx, #$(1) ]], {spriteRegStr}, [[ ; pSprite
			call #L(EEex::Stats_Hook_OnReload)
		]]}
	end

	local callStatsReloadRbx = {"call #$(1) #ENDL",
		{
			EEex_JITNear(EEex_FlattenTable({
				{[[
					#STACK_MOD(8) ; This was called, the ret ptr broke alignment
					#MAKE_SHADOW_SPACE
				]]},
				statsReloadTemplate("rbx"),
				{[[
					#DESTROY_SHADOW_SPACE
					ret
				]]},
			})),
		},
	}

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::QuickLoad()-CDerivedStats::Reload()"), statsReloadTemplate("rdi"))
	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Unmarshal()-CDerivedStats::Reload()-1"), callStatsReloadRbx)
	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Unmarshal()-CDerivedStats::Reload()-2"), callStatsReloadRbx)
	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::ProcessEffectList()-CDerivedStats::Reload()"), statsReloadTemplate("rsi"))

	-----------------------------------------
	-- [EEex.dll] EEex::Stats_Hook_OnEqu() --
	-----------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CDerivedStats::operator_equ()-FirstCall"), {[[
		mov rdx, rsi ; pOtherStats
		mov rcx, r14 ; pStats
		call #L(EEex::Stats_Hook_OnEqu)
	]]})

	---------------------------------------------
	-- [EEex.dll] EEex::Stats_Hook_OnPlusEqu() --
	---------------------------------------------

	EEex_HookBeforeCall(EEex_Label("Hook-CDerivedStats::operator_plus_equ()-FirstCall"), {[[

		#MAKE_SHADOW_SPACE(8)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

		mov rdx, rdi ; pOtherStats
		mov rcx, rbx ; pStats
		call #L(EEex::Stats_Hook_OnPlusEqu)

		mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
	]]})

	----------------------------------------------------
	-- [EEex.dll] EEex::Stats_Hook_OnGettingUnknown() --
	----------------------------------------------------

	EEex_HookJumpOnSuccess(EEex_Label("Hook-CDerivedStats::GetAtOffset()-OutOfBoundsJmp"), 0, EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; TODO This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE

			lea rdx, qword ptr ds:[rax+1] ; nStatId
			                              ; rcx already pStats
			call #L(EEex::Stats_Hook_OnGettingUnknown)

			#DESTROY_SHADOW_SPACE
			ret ; TODO
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
