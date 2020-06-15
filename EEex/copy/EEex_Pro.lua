
EEex_ProjectileHookSource = {
	["SPELL"] = 0,
	["SPELL_POINT"] = 1,
	["FORCE_SPELL"] = 2,
	["FORCE_SPELL_POINT"] = 3,
}

EEex_DecodeProjectileSources = {
	[EEex_Label("CGameSprite::Spell()_DecodeProjectile")           + 0x5] = EEex_ProjectileHookSource.SPELL,
	[EEex_Label("CGameSprite::SpellPoint()_DecodeProjectile")      + 0x5] = EEex_ProjectileHookSource.SPELL_POINT,
	[EEex_Label("CGameAIBase::ForceSpell()_DecodeProjectile")      + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL,
	[EEex_Label("CGameAIBase::ForceSpellPoint()_DecodeProjectile") + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL_POINT,
}

EEex_AddEffectToProjectileSources = {
	[EEex_Label("CGameSprite::Spell()_CProjectile::AddEffect()")           + 0x5] = EEex_ProjectileHookSource.SPELL,
	[EEex_Label("CGameSprite::Spell()_CProjectile::AddEffect()_2")         + 0x5] = EEex_ProjectileHookSource.SPELL,
	[EEex_Label("CGameSprite::SpellPoint()_CProjectile::AddEffect()")      + 0x5] = EEex_ProjectileHookSource.SPELL_POINT,
	[EEex_Label("CGameAIBase::ForceSpell()_CProjectile::AddEffect()")      + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL,
	[EEex_Label("CGameAIBase::ForceSpell()_CProjectile::AddEffect()_2")    + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL,
	[EEex_Label("CGameAIBase::ForceSpellPoint()_CProjectile::AddEffect()") + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL_POINT,
}

function EEex_OnDecodeProjectile(ebp)

	local source = EEex_DecodeProjectileSources[EEex_ReadDword(ebp + 0x4)]
	if not source then return end

	local CGameAIBase = EEex_ReadDword(ebp + 0xC, 0)
	if CGameAIBase == 0x0 then return end

	local actorID = EEex_GetActorIDShare(CGameAIBase)
	if not EEex_IsSprite(actorID, true) then return end

	local projectileType = EEex_ReadWord(ebp + 0x8, 0)
	local mutatorList = EEex_AccessComplexStat(actorID, "EEex_ProjectileMutatorList")

	EEex_IterateCPtrList(mutatorList, function(mutatorElement)

		local originatingEffectData = EEex_ReadDword(mutatorElement + 0x0)
		local functionName = EEex_ReadString(EEex_ReadDword(mutatorElement + 0x4))
		local func = _G[functionName].typeMutator

		if func then

			local newType = func(originatingEffectData, CGameAIBase, projectileType)
			if newType then
				EEex_WriteWord(ebp + 0x8, newType)
				return true
			end
		end
	end)

end

function EEex_OnPostProjectileCreation(CProjectile, ebp)

	local source = EEex_DecodeProjectileSources[EEex_ReadDword(ebp + 0x4)]
	if not source then return end

	local CGameAIBase = EEex_ReadDword(ebp + 0xC, 0)
	if CGameAIBase == 0x0 then return end

	local actorID = EEex_GetActorIDShare(CGameAIBase)
	if not EEex_IsSprite(actorID, true) then return end

	local mutatorList = EEex_AccessComplexStat(actorID, "EEex_ProjectileMutatorList")

	EEex_IterateCPtrList(mutatorList, function(mutatorElement)

		local originatingEffectData = EEex_ReadDword(mutatorElement + 0x0)
		local functionName = EEex_ReadString(EEex_ReadDword(mutatorElement + 0x4))
		local func = _G[functionName].projectileMutator

		if func then
			local blockFurtherMutations = func(originatingEffectData, CGameAIBase, CProjectile)
			if blockFurtherMutations then return true end
		end
	end)

end

function EEex_OnAddEffectToProjectile(CProjectile, CGameAIBase, ebp)

	local source = EEex_AddEffectToProjectileSources[EEex_ReadDword(ebp + 0x4)]
	if not source then return false end
	if CGameAIBase == 0x0 then return false end

	local actorID = EEex_GetActorIDShare(CGameAIBase)
	if not EEex_IsSprite(actorID, true) then return false end

	local CGameEffect = EEex_ReadDword(ebp + 0x8)
	local mutatorList = EEex_AccessComplexStat(actorID, "EEex_ProjectileMutatorList")
	local blockEffect = false

	EEex_IterateCPtrList(mutatorList, function(mutatorElement)

		local originatingEffectData = EEex_ReadDword(mutatorElement + 0x0)
		local functionName = EEex_ReadString(EEex_ReadDword(mutatorElement + 0x4))
		local func = _G[functionName].effectMutator

		if func then
			blockEffect = func(originatingEffectData, CGameAIBase, CProjectile, CGameEffect)
			if blockEffect then return true end
		end
	end)

	return blockEffect
end

(function()

	EEex_DisableCodeProtection()

	EEex_HookAfterRestore(EEex_Label("CProjectile::DecodeProjectile"), 0, 9, {[[

		!push_all_registers

		!push_dword ]], {EEex_WriteStringAuto("EEex_OnDecodeProjectile"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_ebp
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_all_registers

	]]})

	EEex_HookAfterRestore(EEex_Label("CProjectile::DecodeProjectile()_PostConstruction"), 0, 5, {[[

		!push_all_registers
		; CProjectile ;
		!push_eax

		!push_dword ]], {EEex_WriteStringAuto("EEex_OnPostProjectileCreation"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		; CProjectile ;
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_ebp
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 02
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_all_registers

	]]})

	EEex_HookAfterRestore(EEex_Label("CProjectile::AddEffect"), 0, 6, {[[

		!push_all_registers
		; CProjectile ;
		!push_ecx

		!push_dword ]], {EEex_WriteStringAuto("EEex_OnAddEffectToProjectile"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		; CProjectile ;
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		; CGameAIBase ;
		!push_esi
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_ebp
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_byte 03
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_toboolean
		!add_esp_byte 08
		!push_eax
		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08
		!pop_eax

		!test_eax_eax
		!pop_all_registers

		!jz_dword >return

		!pop_ebp
		!ret

	]]})

	EEex_EnableCodeProtection()

end)()
