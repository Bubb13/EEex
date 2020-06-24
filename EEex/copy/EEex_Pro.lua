EEex_TypeMutatorGlobalFunctions = {}

function EEex_AddTypeMutatorGlobal(func_name, func)
	EEex_TypeMutatorGlobalFunctions[func_name] = func
end

EEex_ProjectileMutatorGlobalFunctions = {}

function EEex_AddProjectileMutatorGlobal(func_name, func)
	EEex_ProjectileMutatorGlobalFunctions[func_name] = func
end
--[[
The EXLINEFR function lets you change the delay between hits for a specific projectile that uses the
 "Lined up AoE" feature (e.g. Agannazar's Scorcher). Normally these projectiles hit once every half round;
 now you could make it so one of these projectiles hits every second, or only once for the whole duration.
 To use, set bit 16 of the "Behavior" flags of the projectile, and set the "Color speed" to the new delay
 between hits in ticks. If you set "Color speed" to 15, it will hit once per second (per 15 ticks). If you
 set "Color speed" to 100 or more, it will only hit once.
--]]
EEex_AddProjectileMutatorGlobal("EXLINEFR", function(source, creatureData, projectileData)
	if EEex_IsProjectileOfType(projectileData, EEex_ProjectileType.CProjectileNewScorcher) and bit32.band(EEex_ReadDword(projectileData + 0x120), 0x10000) > 0 then
		local effectRepeatTime = EEex_ReadWord(projectileData + 0x140, 0x0)
		EEex_WriteDword(projectileData + 0x3B0, effectRepeatTime)
	end
end)

EEex_EffectMutatorGlobalFunctions = {}

function EEex_AddEffectMutatorGlobal(func_name, func)
	EEex_EffectMutatorGlobalFunctions[func_name] = func
end

EEex_ProjectileHookSource = {
	["SPELL"] = 0,
	["SPELL_POINT"] = 1,
	["FORCE_SPELL"] = 2,
	["FORCE_SPELL_POINT"] = 3,
	["UPDATE_AOE"] = 4,
	["FORCE_SPELL_OPCODE"] = 5,
	["FORCE_SPELL_POINT_OPCODE"] = 6,
	["MAGIC_MISSILE_PROJECTILE"] = 7,
	["EXPLOSION_PROJECTILE"] = 8,
	["SECONDARY_PROJECTILE"] = 9,
	["SPIRITUAL_WRATH_RAY"] = 10,
	["RANGED_ATTACK_START"] = 11,
	["RANGED_ATTACK"] = 12,
	["USE_ITEM"] = 13,
	["USE_ITEM_POINT"] = 14,
}

EEex_DecodeProjectileSources = {
	[EEex_Label("CGameSprite::Spell()_DecodeProjectile")           + 0x5] = EEex_ProjectileHookSource.SPELL,
	[EEex_Label("CGameSprite::SpellPoint()_DecodeProjectile")      + 0x5] = EEex_ProjectileHookSource.SPELL_POINT,
	[EEex_Label("CGameAIBase::ForceSpell()_DecodeProjectile")      + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL,
	[EEex_Label("CGameAIBase::ForceSpellPoint()_DecodeProjectile") + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL_POINT,
	[EEex_Label("CGameSprite::UpdateAOE()_DecodeProjectile")       + 0x5] = EEex_ProjectileHookSource.UPDATE_AOE,
	[5443518]                                                             = EEex_ProjectileHookSource.FORCE_SPELL_OPCODE,
	[5446459]                                                             = EEex_ProjectileHookSource.FORCE_SPELL_POINT_OPCODE,
	[6093776]                                                             = EEex_ProjectileHookSource.MAGIC_MISSILE_PROJECTILE,
	[6109948]                                                             = EEex_ProjectileHookSource.EXPLOSION_PROJECTILE,
	[6120658]                                                             = EEex_ProjectileHookSource.SECONDARY_PROJECTILE,
	[6135853]                                                             = EEex_ProjectileHookSource.SPIRITUAL_WRATH_RAY,
	[7518846]                                                             = EEex_ProjectileHookSource.RANGED_ATTACK_START,
	[7520734]                                                             = EEex_ProjectileHookSource.RANGED_ATTACK,
	[7529923]                                                             = EEex_ProjectileHookSource.USE_ITEM,
	[7532527]                                                             = EEex_ProjectileHookSource.USE_ITEM_POINT,
}

EEex_AddEffectToProjectileSources = {
	[EEex_Label("CGameSprite::Spell()_CProjectile::AddEffect()")           + 0x5] = EEex_ProjectileHookSource.SPELL,
	[EEex_Label("CGameSprite::Spell()_CProjectile::AddEffect()_2")         + 0x5] = EEex_ProjectileHookSource.SPELL,
	[EEex_Label("CGameSprite::SpellPoint()_CProjectile::AddEffect()")      + 0x5] = EEex_ProjectileHookSource.SPELL_POINT,
	[EEex_Label("CGameAIBase::ForceSpell()_CProjectile::AddEffect()")      + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL,
	[EEex_Label("CGameAIBase::ForceSpell()_CProjectile::AddEffect()_2")    + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL,
	[EEex_Label("CGameAIBase::ForceSpellPoint()_CProjectile::AddEffect()") + 0x5] = EEex_ProjectileHookSource.FORCE_SPELL_POINT,
}

EEex_ProjectileType = {
	["Unknown"]                          = 0x1,
	["CProjectile"]                      = 0x2,
	["CProjectileAmbiant"]               = 0x4,
	["CProjectileArea"]                  = 0x8,
	["CProjectileBAM"]                   = 0x10,
	--["CProjectileCallLightning"]       = (no dedicated VFTable)
	--["CProjectileCastingGlow"]         = (no dedicated VFTable)
	["CProjectileChain"]                 = 0x20, -- (no dedicated VFTable, but used in inheritance below)
	["CProjectileColorSpray"]            = 0x40,
	["CProjectileConeOfCold"]            = 0x80,
	["CProjectileFall"]                  = 0x100,
	["CProjectileFireHands"]             = 0x200,
	["CProjectileInstant"]               = 0x400,
	--["CProjectileInvisibleTravelling"] = (no dedicated VFTable)
	--["CProjectileLightningBolt"]       = (no dedicated VFTable)
	["CProjectileLightningBoltGround"]   = 0x800,
	["CProjectileLightningBounce"]       = 0x1000,
	["CProjectileLightningStorm"]        = 0x2000,
	--["CProjectileMagicMissileMulti"]   = (no dedicated VFTable)
	["CProjectileMulti"]                 = 0x4000,
	["CProjectileMushroom"]              = 0x8000,
	["CProjectileNewScorcher"]           = 0x10000,
	["CProjectileScorcher"]              = 0x20000,
	["CProjectileSegment"]               = 0x40000,
	["CProjectileSkyStrike"]             = 0x80000,
	["CProjectileSkyStrikeBAM"]          = 0x100000,
	["CProjectileSpellHit"]              = 0x200000,
	["CProjectileTravelDoor"]            = 0x400000,
}

EEex_ProjectileInheritance = {
	[EEex_ProjectileType.Unknown]                          = EEex_Flags({ EEex_ProjectileType.Unknown                                                                                                                                      }),
	[EEex_ProjectileType.CProjectile]                      = EEex_Flags({ EEex_ProjectileType.CProjectile                                                                                                                                  }),
	[EEex_ProjectileType.CProjectileAmbiant]               = EEex_Flags({ EEex_ProjectileType.CProjectileAmbiant,             EEex_ProjectileType.CProjectileSpellHit, EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileArea]                  = EEex_Flags({ EEex_ProjectileType.CProjectileArea,                EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileBAM]                   = EEex_Flags({ EEex_ProjectileType.CProjectileBAM,                 EEex_ProjectileType.CProjectile                                                                              }),
	--[EEex_ProjectileType.CProjectileCallLightning]       = (no dedicated VFTable)
	--[EEex_ProjectileType.CProjectileCastingGlow]         = (no dedicated VFTable)
	--[EEex_ProjectileType.CProjectileChain]               = (no dedicated VFTable)
	[EEex_ProjectileType.CProjectileColorSpray]            = EEex_Flags({ EEex_ProjectileType.CProjectileColorSpray,          EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileConeOfCold]            = EEex_Flags({ EEex_ProjectileType.CProjectileConeOfCold,          EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileFall]                  = EEex_Flags({ EEex_ProjectileType.CProjectileFall,                EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileFireHands]             = EEex_Flags({ EEex_ProjectileType.CProjectileFireHands,           EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileInstant]               = EEex_Flags({ EEex_ProjectileType.CProjectileInstant,             EEex_ProjectileType.CProjectile                                                                              }),
	--[EEex_ProjectileType.CProjectileInvisibleTravelling] = (no dedicated VFTable)
	--[EEex_ProjectileType.CProjectileLightningBolt]       = (no dedicated VFTable)
	[EEex_ProjectileType.CProjectileLightningBoltGround]   = EEex_Flags({ EEex_ProjectileType.CProjectileLightningBoltGround, EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileLightningBounce]       = EEex_Flags({ EEex_ProjectileType.CProjectileLightningBounce,     EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileLightningStorm]        = EEex_Flags({ EEex_ProjectileType.CProjectileLightningStorm,      EEex_ProjectileType.CProjectileChain,    EEex_ProjectileType.CProjectileBAM, EEex_ProjectileType.CProjectile }),
	--[EEex_ProjectileType.CProjectileMagicMissileMulti]   = (no dedicated VFTable)
	[EEex_ProjectileType.CProjectileMulti]                 = EEex_Flags({ EEex_ProjectileType.CProjectileMulti,               EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileMushroom]              = EEex_Flags({ EEex_ProjectileType.CProjectileMushroom,            EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileNewScorcher]           = EEex_Flags({ EEex_ProjectileType.CProjectileNewScorcher,         EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileScorcher]              = EEex_Flags({ EEex_ProjectileType.CProjectileScorcher,            EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileSegment]               = EEex_Flags({ EEex_ProjectileType.CProjectileSegment,             EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileSkyStrike]             = EEex_Flags({ EEex_ProjectileType.CProjectileSkyStrike,           EEex_ProjectileType.CProjectile                                                                              }),
	[EEex_ProjectileType.CProjectileSkyStrikeBAM]          = EEex_Flags({ EEex_ProjectileType.CProjectileSkyStrikeBAM,        EEex_ProjectileType.CProjectileBAM,      EEex_ProjectileType.CProjectile                                     }),
	[EEex_ProjectileType.CProjectileSpellHit]              = EEex_Flags({ EEex_ProjectileType.CProjectileSpellHit,            EEex_ProjectileType.CProjectile                                                                              }),
	[EEex_ProjectileType.CProjectileTravelDoor]            = EEex_Flags({ EEex_ProjectileType.CProjectileTravelDoor,          EEex_ProjectileType.CProjectile                                                                              }),
}

EEex_ProjectileVFTableToType = {
	[EEex_Label("CProjectile::CProjectile()_CProjectile_VFTable")                                                          ] = EEex_ProjectileType.CProjectile,
	[EEex_Label("CProjectile::DecodeProjectile()_CProjectileAmbiant_VFTable")                                              ] = EEex_ProjectileType.CProjectileAmbiant,
	[EEex_Label("CProjectileArea::CProjectileArea()_CProjectileArea_VFTable")                                              ] = EEex_ProjectileType.CProjectileArea,
	[EEex_Label("CProjectileBAM::CProjectileBAM()_CProjectileBAM_VFTable")                                                 ] = EEex_ProjectileType.CProjectileBAM,
	[EEex_Label("CProjectileColorSpray::CProjectileColorSpray()_CProjectileColorSpray_VFTable")                            ] = EEex_ProjectileType.CProjectileColorSpray,
	[EEex_Label("CProjectileConeOfCold::CProjectileConeOfCold()_CProjectileConeOfCold_VFTable")                            ] = EEex_ProjectileType.CProjectileConeOfCold,
	[EEex_Label("CProjectileFall::CProjectileFall()_CProjectileFall_VFTable")                                              ] = EEex_ProjectileType.CProjectileFall,
	[EEex_Label("CProjectileFireHands::CProjectileFireHands()_CProjectileFireHands_VFTable")                               ] = EEex_ProjectileType.CProjectileFireHands,
	[EEex_Label("CProjectile::DecodeProjectile()_CProjectileInstant_VFTable")                                              ] = EEex_ProjectileType.CProjectileInstant,
	[EEex_Label("CProjectileLightningBoltGround::CProjectileLightningBoltGround()_CProjectileLightningBoltGround_VFTable") ] = EEex_ProjectileType.CProjectileLightningBoltGround,
	[EEex_Label("CProjectileLightningBounce::CProjectileLightningBounce()_CProjectileLightningBounce_VFTable")             ] = EEex_ProjectileType.CProjectileLightningBounce,
	[EEex_Label("CProjectileLightningStorm::CProjectileLightningStorm()_CProjectileLightningStorm_VFTable")                ] = EEex_ProjectileType.CProjectileLightningStorm,
	[EEex_Label("CProjectileMulti::CProjectileMulti()_CProjectileMulti_VFTable")                                           ] = EEex_ProjectileType.CProjectileMulti,
	[EEex_Label("CProjectileMushroom::CProjectileMushroom()_CProjectileMushroom_VFTable")                                  ] = EEex_ProjectileType.CProjectileMushroom,
	[EEex_Label("CProjectileNewScorcher::CProjectileNewScorcher()_CProjectileNewScorcher_VFTable")                         ] = EEex_ProjectileType.CProjectileNewScorcher,
	[EEex_Label("CProjectileScorcher::CProjectileScorcher()_CProjectileScorcher_VFTable")                                  ] = EEex_ProjectileType.CProjectileScorcher,
	[EEex_Label("CProjectileSegment::CProjectileSegment()_CProjectileSegment_VFTable")                                     ] = EEex_ProjectileType.CProjectileSegment,
	[EEex_Label("CProjectileSkyStrike::CProjectileSkyStrike()_CProjectileSkyStrike_VFTable")                               ] = EEex_ProjectileType.CProjectileSkyStrike,
	[EEex_Label("CProjectileSkyStrikeBAM::CProjectileSkyStrikeBAM()_CProjectileSkyStrikeBAM_VFTable")                      ] = EEex_ProjectileType.CProjectileSkyStrikeBAM,
	[EEex_Label("CProjectileSpellHit::CProjectileSpellHit()_CProjectileSpellHit_VFTable")                                  ] = EEex_ProjectileType.CProjectileSpellHit,
	[EEex_Label("CProjectileTravelDoor::CProjectileTravelDoor()_CProjectileTravelDoor_VFTable")                            ] = EEex_ProjectileType.CProjectileTravelDoor,
}

function EEex_GetProjectileType(CProjectile)
	local type = EEex_ProjectileVFTableToType[EEex_ReadDword(CProjectile)]
	return type or EEex_ProjectileType.Unknown
end

function EEex_IsProjectileOfType(CProjectile, checkType)
	local projType = EEex_GetProjectileType(CProjectile)
	return bit32.band(EEex_ProjectileInheritance[projType], checkType) ~= 0x0
end

function EEex_OnDecodeProjectile(ebp)

	local source = EEex_DecodeProjectileSources[EEex_ReadDword(ebp + 0x4)]
	if not source then return end

	local CGameAIBase = EEex_ReadDword(ebp + 0xC, 0)
	if CGameAIBase == 0x0 then return end

	local actorID = EEex_GetActorIDShare(CGameAIBase)
	if not EEex_IsSprite(actorID, true) then return end

	local projectileType = EEex_ReadWord(ebp + 0x8, 0)
	local mutatorList = EEex_AccessComplexStat(actorID, "EEex_ProjectileMutatorList")

	for func_name, func in pairs(EEex_TypeMutatorGlobalFunctions) do
		local newType = func(source, CGameAIBase, projectileType)
		if newType then
			EEex_WriteWord(ebp + 0x8, newType)
			return true
		end
	end

	EEex_IterateCPtrList(mutatorList, function(mutatorElement)

		local originatingEffectData = EEex_ReadDword(mutatorElement + 0x0)
		local functionName = EEex_ReadString(EEex_ReadDword(mutatorElement + 0x4))
		local func = _G[functionName].typeMutator

		if func then

			local newType = func(source, originatingEffectData, CGameAIBase, projectileType)
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

	for func_name, func in pairs(EEex_ProjectileMutatorGlobalFunctions) do
		local blockFurtherMutations = func(source, CGameAIBase, CProjectile)
		if blockFurtherMutations then return true end
	end

	EEex_IterateCPtrList(mutatorList, function(mutatorElement)

		local originatingEffectData = EEex_ReadDword(mutatorElement + 0x0)
		local functionName = EEex_ReadString(EEex_ReadDword(mutatorElement + 0x4))
		local func = _G[functionName].projectileMutator

		if func then
			local blockFurtherMutations = func(source, originatingEffectData, CGameAIBase, CProjectile)
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

	for func_name, func in pairs(EEex_EffectMutatorGlobalFunctions) do
		blockEffect = func(source, CGameAIBase, CProjectile, CGameEffect)
		if blockEffect then return true end
	end

	EEex_IterateCPtrList(mutatorList, function(mutatorElement)

		local originatingEffectData = EEex_ReadDword(mutatorElement + 0x0)
		local functionName = EEex_ReadString(EEex_ReadDword(mutatorElement + 0x4))
		local func = _G[functionName].effectMutator

		if func then
			blockEffect = func(source, originatingEffectData, CGameAIBase, CProjectile, CGameEffect)
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
