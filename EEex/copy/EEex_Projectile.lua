
-------------
-- Globals --
-------------

EEex_Projectile_Type = {
	["Unknown"]                          = 0x1,
	["CProjectile"]                      = 0x2,     -- 0x14059A0E0
	["CProjectileAmbiant"]               = 0x4,     -- 0x14059B460
	["CProjectileArea"]                  = 0x8,     -- 0x14059AD30
	["CProjectileBAM"]                   = 0x10,    -- 0x14059A218
	--["CProjectileCallLightning"]       = (no dedicated VFTable)
	--["CProjectileCastingGlow"]         = (no dedicated VFTable)
	["CProjectileChain"]                 = 0x20,    -- 0x14059B590
	["CProjectileColorSpray"]            = 0x40,    -- 0x14059A710
	["CProjectileConeOfCold"]            = 0x80,    -- 0x14059A980
	["CProjectileFall"]                  = 0x100,   -- 0x14059ABF8
	["CProjectileFireHands"]             = 0x200,   -- 0x14059A848
	["CProjectileInstant"]               = 0x400,   -- 0x14059AFA0
	--["CProjectileInvisibleTravelling"] = (no dedicated VFTable)
	--["CProjectileLightningBolt"]       = (no dedicated VFTable)
	--["CProjectileLightningBoltGround"] = (no dedicated VFTable)
	--["CProjectileLightningBounce"]     = (no dedicated VFTable)
	--["CProjectileLightningStorm"]      = (no dedicated VFTable)
	--["CProjectileMagicMissileMulti"]   = (no dedicated VFTable)
	["CProjectileMulti"]                 = 0x800,   -- 0x14059AE68
	["CProjectileMushroom"]              = 0x1000,  -- 0x14059A5D0
	["CProjectileNewScorcher"]           = 0x2000,  -- 0x14059A488
	["CProjectileScorcher"]              = 0x4000,  -- 0x14059A350
	["CProjectileSegment"]               = 0x8000,  -- 0x14059AAB8
	["CProjectileSkyStrike"]             = 0x10000, -- 0x14059B200
	["CProjectileSkyStrikeBAM"]          = 0x20000, -- 0x14059B6C8
	["CProjectileSpellHit"]              = 0x40000, -- 0x14059B330
	["CProjectileTravelDoor"]            = 0x80000, -- 0x14059B0D0
}

EEex_Projectile_DecodeSource = {
	["CBounceList_Add"]                                 = 1,  -- 0x14014C816
	["CGameAIBase_FireItem"]                            = 2,  -- 0x14016A321
	["CGameAIBase_FireItemPoint"]                       = 3,  -- 0x14016A6F9
	["CGameAIBase_FireSpell"]                           = 4,  -- 0x14016AD39
	["CGameAIBase_FireSpellPoint"]                      = 5,  -- 0x14016BB0C
	["CGameAIBase_ForceSpell"]                          = 6,  -- 0x14016C7B7
	["CGameAIBase_ForceSpellPoint"]                     = 7,  -- 0x14016DD73
	["CGameEffect_FireSpell"]                           = 8,  -- 0x1401E4503
	["CGameEffectCastingGlow_ApplyEffect"]              = 9,  -- 0x1401A8A3F
	["CGameEffectChangeStatic_ApplyEffect"]             = 10, -- 0x1401A8CF5
	["CGameEffectSummon_ApplyVisualEffect"]             = 11, -- 0x1401CBD8D
	["CGameEffectVisualSpellHitIWD_ApplyEffect"]        = 12, -- 0x1401CA92E
	["CGameSprite_Spell"]                               = 13, -- 0x1403B5021
	["CGameSprite_SpellPoint"]                          = 14, -- 0x1403B6C4D
	["CGameSprite_Swing"]                               = 15, -- 0x1403B83E3, 0x1403B89AA, 0x1403B8A9B
	["CGameSprite_UpdateAOE"]                           = 16, -- 0x14037CF14
	["CGameSprite_UseItem"]                             = 17, -- 0x1403BB43C
	["CGameSprite_UseItemPoint"]                        = 18, -- 0x1403BBFC2
	["CMessageFireProjectile_Run"]                      = 19, -- 0x140212B28
	["CProjectile_DecodeProjectile_MultiMagicMissile"]  = 20, -- 0x14022C2BB
	["CProjectile_DecodeProjectile_ChainCallLightning"] = 21, -- 0x14022C501
	["CProjectile_DecodeProjectile_MultiProjectile"]    = 22, -- 0x14022E9B6
	["CProjectileArea_CreateSecondary"]                 = 23, -- 0x14022BB8E
	["CProjectileArea_Explode"]                         = 24, -- 0x14022F56B
	["CProjectileChain_AIUpdate"]                       = 25, -- 0x140228E04
	["CProjectileChain_Fire"]                           = 26, -- 0x140230554
	["CProjectileFall_AIUpdate"]                        = 27, -- 0x1402291DE
}

EEex_Projectile_AddEffectSource = {
	["CBounceList_Add"]             = 1,  -- 0x14014C7DB, 0x14014C82E,              r15
	["CGameAIBase_FireItem"]        = 2,  -- 0x14016A465, 0x14016A487,              rbp
	["CGameAIBase_FireItemPoint"]   = 3,  -- 0x14016A7F3,                           rsi
	["CGameAIBase_FireSpell"]       = 4,  -- 0x14016AE6F, 0x14016AFE2,              r14
	["CGameAIBase_FireSpellPoint"]  = 5,  -- 0x14016BC3B, 0x14016BCAD,              r14
	["CGameAIBase_ForceSpell"]      = 6,  -- 0x14016CE36, 0x14016CE53,              rbx
	["CGameAIBase_ForceSpellPoint"] = 7,  -- 0x14016DEA4,                           rbx
	["CGameEffect_FireSpell"]       = 8,  -- 0x1401E4715, 0x1401E4793,              source id at dword ptr ss:[rbp+0x7F]
	["CGameSprite_LoadProjectile"]  = 9,  -- 0x14035FBB6, 0x14035FD8A, 0x14035FF30, rdi
	["CGameSprite_Spell"]           = 10, -- 0x1403B5238, 0x1403B5259,              rbx
	["CGameSprite_SpellPoint"]      = 11, -- 0x1403B6DE2,                           rbx
	["CGameSprite_Swing"]           = 12, -- 0x1403B88B3, 0x1403B9291,              rbx
	["CGameSprite_UseItem"]         = 13, -- 0x1403BB59A, 0x1403BB5BF,              rbx
	["CGameSprite_UseItemPoint"]    = 14, -- 0x1403BC0DA,                           rbx
}

---------------------
-- Private Globals --
---------------------

EEex_Projectile_Private_Inheritance = {
	[EEex_Projectile_Type.CProjectile]                       = EEex_Flags({ EEex_Projectile_Type.CProjectile                                                                                                                                     }),
	[EEex_Projectile_Type.CProjectileAmbiant]                = EEex_Flags({ EEex_Projectile_Type.CProjectileAmbiant,             EEex_Projectile_Type.CProjectileSpellHit, EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileArea]                   = EEex_Flags({ EEex_Projectile_Type.CProjectileArea,                EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileBAM]                    = EEex_Flags({ EEex_Projectile_Type.CProjectileBAM,                 EEex_Projectile_Type.CProjectile                                                                                }),
	--[EEex_Projectile_Type.CProjectileCallLightning]        = EEex_Flags({ EEex_Projectile_Type.CProjectileCallLightning,       EEex_Projectile_Type.CProjectileInstant,  EEex_Projectile_Type.CProjectile                                      }),
	--[EEex_Projectile_Type.CProjectileCastingGlow]          = EEex_Flags({ EEex_Projectile_Type.CProjectileCastingGlow,         EEex_Projectile_Type.CProjectile                                                                                }),
	[EEex_Projectile_Type.CProjectileChain]                  = EEex_Flags({ EEex_Projectile_Type.CProjectileChain,               EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileColorSpray]             = EEex_Flags({ EEex_Projectile_Type.CProjectileColorSpray,          EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileConeOfCold]             = EEex_Flags({ EEex_Projectile_Type.CProjectileConeOfCold,          EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileFall]                   = EEex_Flags({ EEex_Projectile_Type.CProjectileFall,                EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileFireHands]              = EEex_Flags({ EEex_Projectile_Type.CProjectileFireHands,           EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileInstant]                = EEex_Flags({ EEex_Projectile_Type.CProjectileInstant,             EEex_Projectile_Type.CProjectile                                                                                }),
	--[EEex_Projectile_Type.CProjectileInvisibleTravelling]  = EEex_Flags({ EEex_Projectile_Type.CProjectileInvisibleTravelling, EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	--[EEex_Projectile_Type.CProjectileLightningBolt]        = EEex_Flags({ EEex_Projectile_Type.CProjectileLightningBolt,       EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	--[EEex_Projectile_Type.CProjectileLightningBoltGround]  = EEex_Flags({ EEex_Projectile_Type.CProjectileLightningBoltGround, EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	--[EEex_Projectile_Type.CProjectileLightningBounce]      = EEex_Flags({ EEex_Projectile_Type.CProjectileLightningBounce,     EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	--[EEex_Projectile_Type.CProjectileLightningStorm]       = EEex_Flags({ EEex_Projectile_Type.CProjectileLightningStorm,      EEex_Projectile_Type.CProjectileChain,    EEex_Projectile_Type.CProjectileBAM, EEex_Projectile_Type.CProjectile }),
	--[EEex_Projectile_Type.CProjectileMagicMissileMulti]    = EEex_Flags({ EEex_Projectile_Type.CProjectileMagicMissileMulti,   EEex_Projectile_Type.CProjectileMulti,    EEex_Projectile_Type.CProjectileBAM, EEex_Projectile_Type.CProjectile }),
	[EEex_Projectile_Type.CProjectileMulti]                  = EEex_Flags({ EEex_Projectile_Type.CProjectileMulti,               EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileMushroom]               = EEex_Flags({ EEex_Projectile_Type.CProjectileMushroom,            EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileNewScorcher]            = EEex_Flags({ EEex_Projectile_Type.CProjectileNewScorcher,         EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileScorcher]               = EEex_Flags({ EEex_Projectile_Type.CProjectileScorcher,            EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileSegment]                = EEex_Flags({ EEex_Projectile_Type.CProjectileSegment,             EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileSkyStrike]              = EEex_Flags({ EEex_Projectile_Type.CProjectileSkyStrike,           EEex_Projectile_Type.CProjectile                                                                                }),
	[EEex_Projectile_Type.CProjectileSkyStrikeBAM]           = EEex_Flags({ EEex_Projectile_Type.CProjectileSkyStrikeBAM,        EEex_Projectile_Type.CProjectileBAM,      EEex_Projectile_Type.CProjectile                                      }),
	[EEex_Projectile_Type.CProjectileSpellHit]               = EEex_Flags({ EEex_Projectile_Type.CProjectileSpellHit,            EEex_Projectile_Type.CProjectile                                                                                }),
	[EEex_Projectile_Type.CProjectileTravelDoor]             = EEex_Flags({ EEex_Projectile_Type.CProjectileTravelDoor,          EEex_Projectile_Type.CProjectile                                                                                }),
}

EEex_Projectile_Private_VFTableToType = {
	[ EEex_Label("CProjectile::VFTable")                ] = EEex_Projectile_Type.CProjectile,
	[ EEex_Label("CProjectileAmbiant::VFTable")         ] = EEex_Projectile_Type.CProjectileAmbiant,
	[ EEex_Label("CProjectileArea::VFTable")            ] = EEex_Projectile_Type.CProjectileArea,
	[ EEex_Label("CProjectileBAM::VFTable")             ] = EEex_Projectile_Type.CProjectileBAM,
	--[ EEex_Label("CProjectileCallLightning::VFTable") ] = EEex_Projectile_Type.CProjectileCallLightning,
	--[ EEex_Label("CProjectileCastingGlow::VFTable")   ] = EEex_Projectile_Type.CProjectileCastingGlow,
	[ EEex_Label("CProjectileChain::VFTable")           ] = EEex_Projectile_Type.CProjectileChain,
	[ EEex_Label("CProjectileColorSpray::VFTable")      ] = EEex_Projectile_Type.CProjectileColorSpray,
	[ EEex_Label("CProjectileConeOfCold::VFTable")      ] = EEex_Projectile_Type.CProjectileConeOfCold,
	[ EEex_Label("CProjectileFall::VFTable")            ] = EEex_Projectile_Type.CProjectileFall,
	[ EEex_Label("CProjectileFireHands::VFTable")       ] = EEex_Projectile_Type.CProjectileFireHands,
	[ EEex_Label("CProjectileInstant::VFTable")         ] = EEex_Projectile_Type.CProjectileInstant,
	--[ EEex_Label("CProjectileInvisibleTravelling")    ] = EEex_Projectile_Type.CProjectileInvisibleTravelling,
	--[ EEex_Label("CProjectileLightningBolt")          ] = EEex_Projectile_Type.CProjectileLightningBolt,
	--[ EEex_Label("CProjectileLightningBoltGround")    ] = EEex_Projectile_Type.CProjectileLightningBoltGround,
	--[ EEex_Label("CProjectileLightningBounce")        ] = EEex_Projectile_Type.CProjectileLightningBounce,
	--[ EEex_Label("CProjectileLightningStorm")         ] = EEex_Projectile_Type.CProjectileLightningStorm,
	--[ EEex_Label("CProjectileMagicMissileMulti")      ] = EEex_Projectile_Type.CProjectileMagicMissileMulti,
	[ EEex_Label("CProjectileMulti::VFTable")           ] = EEex_Projectile_Type.CProjectileMulti,
	[ EEex_Label("CProjectileMushroom::VFTable")        ] = EEex_Projectile_Type.CProjectileMushroom,
	[ EEex_Label("CProjectileNewScorcher::VFTable")     ] = EEex_Projectile_Type.CProjectileNewScorcher,
	[ EEex_Label("CProjectileScorcher::VFTable")        ] = EEex_Projectile_Type.CProjectileScorcher,
	[ EEex_Label("CProjectileSegment::VFTable")         ] = EEex_Projectile_Type.CProjectileSegment,
	[ EEex_Label("CProjectileSkyStrike::VFTable")       ] = EEex_Projectile_Type.CProjectileSkyStrike,
	[ EEex_Label("CProjectileSkyStrikeBAM::VFTable")    ] = EEex_Projectile_Type.CProjectileSkyStrikeBAM,
	[ EEex_Label("CProjectileSpellHit::VFTable")        ] = EEex_Projectile_Type.CProjectileSpellHit,
	[ EEex_Label("CProjectileTravelDoor::VFTable")      ] = EEex_Projectile_Type.CProjectileTravelDoor,
}

EEex_Projectile_Private_DecodeSources = {
	[ EEex_Label("Data-CBounceList::Add()-CProjectile::DecodeProjectile()-RetPtr")                          ] = EEex_Projectile_DecodeSource.CBounceList_Add,
	[ EEex_Label("Data-CGameAIBase::FireItem()-CProjectile::DecodeProjectile()-RetPtr")                     ] = EEex_Projectile_DecodeSource.CGameAIBase_FireItem,
	[ EEex_Label("Data-CGameAIBase::FireItemPoint()-CProjectile::DecodeProjectile()-RetPtr")                ] = EEex_Projectile_DecodeSource.CGameAIBase_FireItemPoint,
	[ EEex_Label("Data-CGameAIBase::FireSpell()-CProjectile::DecodeProjectile()-RetPtr")                    ] = EEex_Projectile_DecodeSource.CGameAIBase_FireSpell,
	[ EEex_Label("Data-CGameAIBase::FireSpellPoint()-CProjectile::DecodeProjectile()-RetPtr")               ] = EEex_Projectile_DecodeSource.CGameAIBase_FireSpellPoint,
	[ EEex_Label("Data-CGameAIBase::ForceSpell()-CProjectile::DecodeProjectile()-RetPtr")                   ] = EEex_Projectile_DecodeSource.CGameAIBase_ForceSpell,
	[ EEex_Label("Data-CGameAIBase::ForceSpellPoint()-CProjectile::DecodeProjectile()-RetPtr")              ] = EEex_Projectile_DecodeSource.CGameAIBase_ForceSpellPoint,
	[ EEex_Label("Data-CGameEffect::FireSpell()-CProjectile::DecodeProjectile()-RetPtr")                    ] = EEex_Projectile_DecodeSource.CGameEffect_FireSpell,
	[ EEex_Label("Data-CGameEffectCastingGlow::ApplyEffect()-CProjectile::DecodeProjectile()-RetPtr")       ] = EEex_Projectile_DecodeSource.CGameEffectCastingGlow_ApplyEffect,
	[ EEex_Label("Data-CGameEffectChangeStatic::ApplyEffect()-CProjectile::DecodeProjectile()-RetPtr")      ] = EEex_Projectile_DecodeSource.CGameEffectChangeStatic_ApplyEffect,
	[ EEex_Label("Data-CGameEffectSummon::ApplyVisualEffect()-CProjectile::DecodeProjectile()-RetPtr")      ] = EEex_Projectile_DecodeSource.CGameEffectSummon_ApplyVisualEffect,
	[ EEex_Label("Data-CGameEffectVisualSpellHitIWD::ApplyEffect()-CProjectile::DecodeProjectile()-RetPtr") ] = EEex_Projectile_DecodeSource.CGameEffectVisualSpellHitIWD_ApplyEffect,
	[ EEex_Label("Data-CGameSprite::Spell()-CProjectile::DecodeProjectile()-RetPtr")                        ] = EEex_Projectile_DecodeSource.CGameSprite_Spell,
	[ EEex_Label("Data-CGameSprite::SpellPoint()-CProjectile::DecodeProjectile()-RetPtr")                   ] = EEex_Projectile_DecodeSource.CGameSprite_SpellPoint,
	[ EEex_Label("Data-CGameSprite::Swing()-CProjectile::DecodeProjectile()-RetPtr")                        ] = EEex_Projectile_DecodeSource.CGameSprite_Swing,
	[ EEex_Label("Data-CGameSprite::Swing()-CProjectile::DecodeProjectile()-RetPtr-2")                      ] = EEex_Projectile_DecodeSource.CGameSprite_Swing,
	[ EEex_Label("Data-CGameSprite::Swing()-CProjectile::DecodeProjectile()-RetPtr-3")                      ] = EEex_Projectile_DecodeSource.CGameSprite_Swing,
	[ EEex_Label("Data-CGameSprite::UpdateAOE()-CProjectile::DecodeProjectile()-RetPtr")                    ] = EEex_Projectile_DecodeSource.CGameSprite_UpdateAOE,
	[ EEex_Label("Data-CGameSprite::UseItem()-CProjectile::DecodeProjectile()-RetPtr")                      ] = EEex_Projectile_DecodeSource.CGameSprite_UseItem,
	[ EEex_Label("Data-CGameSprite::UseItemPoint()-CProjectile::DecodeProjectile()-RetPtr")                 ] = EEex_Projectile_DecodeSource.CGameSprite_UseItemPoint,
	[ EEex_Label("Data-CMessageFireProjectile::Run()-CProjectile::DecodeProjectile()-RetPtr")               ] = EEex_Projectile_DecodeSource.CMessageFireProjectile_Run,
	[ EEex_Label("Data-CProjectile::DecodeProjectile()-CProjectile::DecodeProjectile()-RetPtr")             ] = EEex_Projectile_DecodeSource.CProjectile_DecodeProjectile_MultiMagicMissile,
	[ EEex_Label("Data-CProjectile::DecodeProjectile()-CProjectile::DecodeProjectile()-RetPtr-2")           ] = EEex_Projectile_DecodeSource.CProjectile_DecodeProjectile_ChainCallLightning,
	[ EEex_Label("Data-CProjectile::DecodeProjectile()-CProjectile::DecodeProjectile()-RetPtr-3")           ] = EEex_Projectile_DecodeSource.CProjectile_DecodeProjectile_MultiProjectile,
	[ EEex_Label("Data-CProjectileArea::CreateSecondary()-CProjectile::DecodeProjectile()-RetPtr")          ] = EEex_Projectile_DecodeSource.CProjectileArea_CreateSecondary,
	[ EEex_Label("Data-CProjectileArea::Explode()-CProjectile::DecodeProjectile()-RetPtr")                  ] = EEex_Projectile_DecodeSource.CProjectileArea_Explode,
	[ EEex_Label("Data-CProjectileChain::AIUpdate()-CProjectile::DecodeProjectile()-RetPtr")                ] = EEex_Projectile_DecodeSource.CProjectileChain_AIUpdate,
	[ EEex_Label("Data-CProjectileChain::Fire()-CProjectile::DecodeProjectile()-RetPtr")                    ] = EEex_Projectile_DecodeSource.CProjectileChain_Fire,
	[ EEex_Label("Data-CProjectileFall::AIUpdate()-CProjectile::DecodeProjectile()-RetPtr")                 ] = EEex_Projectile_DecodeSource.CProjectileFall_AIUpdate,
}

EEex_Projectile_Private_AddEffectSources = {
	[ EEex_Label("Data-CBounceList::Add()-CProjectile::AddEffect()-RetPtr")              ] = EEex_Projectile_AddEffectSource.CBounceList_Add,
	[ EEex_Label("Data-CBounceList::Add()-CProjectile::AddEffect()-RetPtr-2")            ] = EEex_Projectile_AddEffectSource.CBounceList_Add,
	[ EEex_Label("Data-CGameAIBase::FireItem()-CProjectile::AddEffect()-RetPtr")         ] = EEex_Projectile_AddEffectSource.CGameAIBase_FireItem,
	[ EEex_Label("Data-CGameAIBase::FireItem()-CProjectile::AddEffect()-RetPtr-2")       ] = EEex_Projectile_AddEffectSource.CGameAIBase_FireItem,
	[ EEex_Label("Data-CGameAIBase::FireItemPoint()-CProjectile::AddEffect()-RetPtr")    ] = EEex_Projectile_AddEffectSource.CGameAIBase_FireItemPoint,
	[ EEex_Label("Data-CGameAIBase::FireSpell()-CProjectile::AddEffect()-RetPtr")        ] = EEex_Projectile_AddEffectSource.CGameAIBase_FireSpell,
	[ EEex_Label("Data-CGameAIBase::FireSpell()-CProjectile::AddEffect()-RetPtr-2")      ] = EEex_Projectile_AddEffectSource.CGameAIBase_FireSpell,
	[ EEex_Label("Data-CGameAIBase::FireSpellPoint()-CProjectile::AddEffect()-RetPtr")   ] = EEex_Projectile_AddEffectSource.CGameAIBase_FireSpellPoint,
	[ EEex_Label("Data-CGameAIBase::FireSpellPoint()-CProjectile::AddEffect()-RetPtr-2") ] = EEex_Projectile_AddEffectSource.CGameAIBase_FireSpellPoint,
	[ EEex_Label("Data-CGameAIBase::ForceSpell()-CProjectile::AddEffect()-RetPtr")       ] = EEex_Projectile_AddEffectSource.CGameAIBase_ForceSpell,
	[ EEex_Label("Data-CGameAIBase::ForceSpell()-CProjectile::AddEffect()-RetPtr-2")     ] = EEex_Projectile_AddEffectSource.CGameAIBase_ForceSpell,
	[ EEex_Label("Data-CGameAIBase::ForceSpellPoint()-CProjectile::AddEffect()-RetPtr")  ] = EEex_Projectile_AddEffectSource.CGameAIBase_ForceSpellPoint,
	[ EEex_Label("Data-CGameEffect::FireSpell()-CProjectile::AddEffect()-RetPtr")        ] = EEex_Projectile_AddEffectSource.CGameEffect_FireSpell,
	[ EEex_Label("Data-CGameEffect::FireSpell()-CProjectile::AddEffect()-RetPtr-2")      ] = EEex_Projectile_AddEffectSource.CGameEffect_FireSpell,
	[ EEex_Label("Data-CGameSprite::LoadProjectile()-CProjectile::AddEffect()-RetPtr")   ] = EEex_Projectile_AddEffectSource.CGameSprite_LoadProjectile,
	[ EEex_Label("Data-CGameSprite::LoadProjectile()-CProjectile::AddEffect()-RetPtr-2") ] = EEex_Projectile_AddEffectSource.CGameSprite_LoadProjectile,
	[ EEex_Label("Data-CGameSprite::LoadProjectile()-CProjectile::AddEffect()-RetPtr-3") ] = EEex_Projectile_AddEffectSource.CGameSprite_LoadProjectile,
	[ EEex_Label("Data-CGameSprite::Spell()-CProjectile::AddEffect()-RetPtr")            ] = EEex_Projectile_AddEffectSource.CGameSprite_Spell,
	[ EEex_Label("Data-CGameSprite::Spell()-CProjectile::AddEffect()-RetPtr-2")          ] = EEex_Projectile_AddEffectSource.CGameSprite_Spell,
	[ EEex_Label("Data-CGameSprite::SpellPoint()-CProjectile::AddEffect()-RetPtr")       ] = EEex_Projectile_AddEffectSource.CGameSprite_SpellPoint,
	[ EEex_Label("Data-CGameSprite::Swing()-CProjectile::AddEffect()-RetPtr")            ] = EEex_Projectile_AddEffectSource.CGameSprite_Swing,
	[ EEex_Label("Data-CGameSprite::Swing()-CProjectile::AddEffect()-RetPtr-2")          ] = EEex_Projectile_AddEffectSource.CGameSprite_Swing,
	[ EEex_Label("Data-CGameSprite::UseItem()-CProjectile::AddEffect()-RetPtr")          ] = EEex_Projectile_AddEffectSource.CGameSprite_UseItem,
	[ EEex_Label("Data-CGameSprite::UseItem()-CProjectile::AddEffect()-RetPtr-2")        ] = EEex_Projectile_AddEffectSource.CGameSprite_UseItem,
	[ EEex_Label("Data-CGameSprite::UseItemPoint()-CProjectile::AddEffect()-RetPtr")     ] = EEex_Projectile_AddEffectSource.CGameSprite_UseItemPoint,
}

EEex_Projectile_Private_GlobalMutators = {}

---------------
-- Functions --
---------------

-- @bubb_doc { EEex_Projectile_RegisterGlobalMutator }
--
-- @summary: Registers a global Lua table as a global (always processed) projectile mutator.
--
-- @param { mutatorTableName / type=string }: The name of the table to register.
--
-- @extra_comment:
--
-- ==========================================================================================================================================================================================================
--
-- **The Mutator Table**
-- *********************
--
-- A mutator table can contain three optional keys, each of which should be assigned a respective mutator function.
--
-- The valid function keys are: ``typeMutator``, ``projectileMutator``, and ``effectMutator``:
--
-- ==========================================================================================================================================================================================================
--
-- **typeMutator**
-- """""""""""""""
--
-- **Parameters:**
--
-- +---------+-------+---------------------------------------------+
-- | Name    | Type  | Description                                 |
-- +=========+=======+=============================================+
-- | context | table | A table containing the context of the hook. |
-- +---------+-------+---------------------------------------------+
--
-- ``context`` **keys:**
--
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | Context Key       | Value Type                   | Description                                                                                                                                      |
-- +===================+==============================+==================================================================================================================================================+
-- | decodeSource      | EEex_Projectile_DecodeSource | The source of the hook, such as ``EEex_Projectile_DecodeSource.CGameSprite_Spell``                           :raw-html:`<br/>`                   |
-- |                   |                              | for the ``Spell()`` action, ``EEex_Projectile_DecodeSource.CGameSprite_SpellPoint``                          :raw-html:`<br/>`                   |
-- |                   |                              | for the ``SpellPoint()`` action, etc.                                                                                                            |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | originatingEffect | CGameEffect | nil            | The op408 (ProjectileMutator) effect that registered the containing mutator table.                           :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                              |                                                                                                                                                  |
-- |                   |                              | This is always ``nil`` for global mutator tables registered via ``EEex_Projectile_RegisterGlobalMutator()``.                                     |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | originatingSprite | CGameSprite | nil            | The sprite that is decoding (creating) the projectile.                                                       :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                              |                                                                                                                                                  |
-- |                   |                              | Global mutator tables registered via ``EEex_Projectile_RegisterGlobalMutator()``                             :raw-html:`<br/>`                   |
-- |                   |                              | also run for non-sprite decode sources; in these cases this is ``nil``.                                                                          |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | projectileType    | number                       | The projectile type about to be decoded.                                                                     :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                              |                                                                                                                                                  |
-- |                   |                              | This is equivalent to the value at ``.SPL->Ability Header->[+0x26]``.                                        :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                              |                                                                                                                                                  |
-- |                   |                              | Subtract one from this value to get the corresponding ``PROJECTL.IDS`` index.                                                                    |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
--
-- **Return Values:**
--
-- +--------------+-------------------------------------------------------------------------------------------------------------------+
-- | Type         | Description                                                                                                       |
-- +==============+===================================================================================================================+
-- | number | nil | The new projectile type, or ``nil`` if the type should not be overridden.     :raw-html:`<br/>` :raw-html:`<br/>` |
-- |              |                                                                                                                   |
-- |              | This is equivalent to the value at ``.SPL->Ability Header->[+0x26]``.         :raw-html:`<br/>` :raw-html:`<br/>` |
-- |              |                                                                                                                   |
-- |              | Subtract one from this value to get the corresponding ``PROJECTL.IDS`` index.                                     |
-- +--------------+-------------------------------------------------------------------------------------------------------------------+
--
-- ==========================================================================================================================================================================================================
--
-- **projectileMutator**
-- """""""""""""""""""""
--
-- **Parameters:**
--
-- +---------+-------+---------------------------------------------+
-- | Name    | Type  | Description                                 |
-- +=========+=======+=============================================+
-- | context | table | A table containing the context of the hook. |
-- +---------+-------+---------------------------------------------+
--
-- ``context`` **keys:**
--
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | Context Key       | Value Type                   | Description                                                                                                                                      |
-- +===================+==============================+==================================================================================================================================================+
-- | decodeSource      | EEex_Projectile_DecodeSource | The source of the hook, such as ``EEex_Projectile_DecodeSource.CGameSprite_Spell``                           :raw-html:`<br/>`                   |
-- |                   |                              | for the ``Spell()`` action, ``EEex_Projectile_DecodeSource.CGameSprite_SpellPoint``                          :raw-html:`<br/>`                   |
-- |                   |                              | for the ``SpellPoint()`` action, etc.                                                                                                            |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | originatingEffect | CGameEffect | nil            | The op408 (ProjectileMutator) effect that registered the containing mutator table.                           :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                              |                                                                                                                                                  |
-- |                   |                              | This is always ``nil`` for global mutator tables registered via ``EEex_Projectile_RegisterGlobalMutator()``.                                     |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | originatingSprite | CGameSprite | nil            | The sprite that is decoding (creating) the projectile.                                                       :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                              |                                                                                                                                                  |
-- |                   |                              | Global mutator tables registered via ``EEex_Projectile_RegisterGlobalMutator()``                             :raw-html:`<br/>`                   |
-- |                   |                              | also run for non-sprite decode sources; in these cases this is ``nil``.                                                                          |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | projectile        | CProjectile                  | The projectile about to be returned from the decoding process.                                                                                   |
-- +-------------------+------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
--
-- ==========================================================================================================================================================================================================
--
-- **effectMutator**
-- """""""""""""""""
--
-- **Parameters:**
--
-- +---------+-------+---------------------------------------------+
-- | Name    | Type  | Description                                 |
-- +=========+=======+=============================================+
-- | context | table | A table containing the context of the hook. |
-- +---------+-------+---------------------------------------------+
--
-- ``context`` **keys:**
--
-- +-------------------+---------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | Context Key       | Value Type                      | Description                                                                                                                                      |
-- +===================+=================================+==================================================================================================================================================+
-- | addEffectSource   | EEex_Projectile_AddEffectSource | The source of the hook, such as ``EEex_Projectile_AddEffectSource.CGameSprite_Spell``                           :raw-html:`<br/>`                |
-- |                   |                                 | for the ``Spell()`` action, ``EEex_Projectile_AddEffectSource.CGameSprite_SpellPoint``                          :raw-html:`<br/>`                |
-- |                   |                                 | for the ``SpellPoint()`` action, etc.                                                                                                            |
-- +-------------------+---------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | effect            | CGameEffect                     | The effect that is being added to ``projectile``.                                                                                                |
-- +-------------------+---------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | originatingEffect | CGameEffect | nil               | The op408 (ProjectileMutator) effect that registered the containing mutator table.                           :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                                 |                                                                                                                                                  |
-- |                   |                                 | This is always ``nil`` for global mutator tables registered via ``EEex_Projectile_RegisterGlobalMutator()``.                                     |
-- +-------------------+---------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | originatingSprite | CGameSprite | nil               | The sprite that decoded (created) the projectile.                                                            :raw-html:`<br/>` :raw-html:`<br/>` |
-- |                   |                                 |                                                                                                                                                  |
-- |                   |                                 | Global mutator tables registered via ``EEex_Projectile_RegisterGlobalMutator()``                             :raw-html:`<br/>`                   |
-- |                   |                                 | also run for non-sprite sources; in these cases this is ``nil``.                                                                                 |
-- +-------------------+---------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
-- | projectile        | CProjectile                     | The projectile that ``effect`` is being added to.                                                                                                |
-- +-------------------+---------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------+
--
-- ==========================================================================================================================================================================================================
--
-- **EEex_Projectile_DecodeSource**
-- """"""""""""""""""""""""""""""""
-- +-------------------------------------------------+-------------+
-- | Name                                            | Description |
-- +=================================================+=============+
-- | CBounceList_Add                                 |             |
-- +-------------------------------------------------+-------------+
-- | CGameAIBase_FireItem                            |             |
-- +-------------------------------------------------+-------------+
-- | CGameAIBase_FireItemPoint                       |             |
-- +-------------------------------------------------+-------------+
-- | CGameAIBase_FireSpell                           |             |
-- +-------------------------------------------------+-------------+
-- | CGameAIBase_FireSpellPoint                      |             |
-- +-------------------------------------------------+-------------+
-- | CGameAIBase_ForceSpell                          |             |
-- +-------------------------------------------------+-------------+
-- | CGameAIBase_ForceSpellPoint                     |             |
-- +-------------------------------------------------+-------------+
-- | CGameEffect_FireSpell                           |             |
-- +-------------------------------------------------+-------------+
-- | CGameEffectCastingGlow_ApplyEffect              |             |
-- +-------------------------------------------------+-------------+
-- | CGameEffectChangeStatic_ApplyEffect             |             |
-- +-------------------------------------------------+-------------+
-- | CGameEffectSummon_ApplyVisualEffect             |             |
-- +-------------------------------------------------+-------------+
-- | CGameEffectVisualSpellHitIWD_ApplyEffect        |             |
-- +-------------------------------------------------+-------------+
-- | CGameSprite_Spell                               |             |
-- +-------------------------------------------------+-------------+
-- | CGameSprite_SpellPoint                          |             |
-- +-------------------------------------------------+-------------+
-- | CGameSprite_Swing                               |             |
-- +-------------------------------------------------+-------------+
-- | CGameSprite_UpdateAOE                           |             |
-- +-------------------------------------------------+-------------+
-- | CGameSprite_UseItem                             |             |
-- +-------------------------------------------------+-------------+
-- | CGameSprite_UseItemPoint                        |             |
-- +-------------------------------------------------+-------------+
-- | CMessageFireProjectile_Run                      |             |
-- +-------------------------------------------------+-------------+
-- | CProjectile_DecodeProjectile_MultiMagicMissile  |             |
-- +-------------------------------------------------+-------------+
-- | CProjectile_DecodeProjectile_ChainCallLightning |             |
-- +-------------------------------------------------+-------------+
-- | CProjectile_DecodeProjectile_MultiProjectile    |             |
-- +-------------------------------------------------+-------------+
-- | CProjectileArea_CreateSecondary                 |             |
-- +-------------------------------------------------+-------------+
-- | CProjectileArea_Explode                         |             |
-- +-------------------------------------------------+-------------+
-- | CProjectileChain_AIUpdate                       |             |
-- +-------------------------------------------------+-------------+
-- | CProjectileChain_Fire                           |             |
-- +-------------------------------------------------+-------------+
-- | CProjectileFall_AIUpdate                        |             |
-- +-------------------------------------------------+-------------+
--
-- **EEex_Projectile_AddEffectSource**
-- """""""""""""""""""""""""""""""""""
-- +-----------------------------+-------------+
-- | Name                        | Description |
-- +=============================+=============+
-- | CBounceList_Add             |             |
-- +-----------------------------+-------------+
-- | CGameAIBase_FireItem        |             |
-- +-----------------------------+-------------+
-- | CGameAIBase_FireItemPoint   |             |
-- +-----------------------------+-------------+
-- | CGameAIBase_FireSpell       |             |
-- +-----------------------------+-------------+
-- | CGameAIBase_FireSpellPoint  |             |
-- +-----------------------------+-------------+
-- | CGameAIBase_ForceSpell      |             |
-- +-----------------------------+-------------+
-- | CGameAIBase_ForceSpellPoint |             |
-- +-----------------------------+-------------+
-- | CGameEffect_FireSpell       |             |
-- +-----------------------------+-------------+
-- | CGameSprite_LoadProjectile  |             |
-- +-----------------------------+-------------+
-- | CGameSprite_Spell           |             |
-- +-----------------------------+-------------+
-- | CGameSprite_SpellPoint      |             |
-- +-----------------------------+-------------+
-- | CGameSprite_Swing           |             |
-- +-----------------------------+-------------+
-- | CGameSprite_UseItem         |             |
-- +-----------------------------+-------------+
-- | CGameSprite_UseItemPoint    |             |
-- +-----------------------------+-------------+

function EEex_Projectile_RegisterGlobalMutator(mutatorTableName)
	if type(mutatorTableName) ~= "string" then
		EEex_Error("[EEex_Projectile_RegisterGlobalMutator] Invalid mutatorTableName parameter value")
	end
	table.insert(EEex_Projectile_Private_GlobalMutators, mutatorTableName)
end

-- @bubb_doc { EEex_Projectile_CastUserType / alias=EEex_Projectile_CastUT }
-- @summary:
--
--     Takes the given ``projectile`` and returns a cast userdata that represents ``projectile``'s true type.
--
--     Most EEex functions will call this function before passing a projectile to the modder API.
--
-- @param { projectile / usertype=CProjectile }: The projectile to cast.
--
-- @return {
--
--     usertype =
--     @|
--         CProjectile                    | CProjectileAmbiant             | CProjectileArea                | @EOL
--         CProjectileBAM                 | CProjectileCallLightning       | CProjectileCastingGlow         | @EOL
--         CProjectileChain               | CProjectileColorSpray          | CProjectileConeOfCold          | @EOL
--         CProjectileFall                | CProjectileFireHands           | CProjectileInstant             | @EOL
--         CProjectileInvisibleTravelling | CProjectileLightningBolt       | CProjectileLightningBoltGround | @EOL
--         CProjectileLightningBounce     | CProjectileLightningStorm      | CProjectileMagicMissileMulti   | @EOL
--         CProjectileMulti               | CProjectileMushroom            | CProjectileNewScorcher         | @EOL
--         CProjectileScorcher            | CProjectileSegment             | CProjectileSkyStrike           | @EOL
--         CProjectileSkyStrikeBAM        | CProjectileSpellHit            | CProjectileTravelDoor          | nil
--     @|
--
-- }: See summary.

EEex_Projectile_Private_CastUserTypes = {
	[EEex_Projectile_Type.CProjectile]                      = "CProjectile",
	[EEex_Projectile_Type.CProjectileAmbiant]               = "CProjectileAmbiant",
	[EEex_Projectile_Type.CProjectileArea]                  = "CProjectileArea",
	[EEex_Projectile_Type.CProjectileBAM]                   = "CProjectileBAM",
	--[EEex_Projectile_Type.CProjectileCallLightning]       = "CProjectileCallLightning",
	--[EEex_Projectile_Type.CProjectileCastingGlow]         = "CProjectileCastingGlow",
	[EEex_Projectile_Type.CProjectileChain]                 = "CProjectileChain",
	[EEex_Projectile_Type.CProjectileColorSpray]            = "CProjectileColorSpray",
	[EEex_Projectile_Type.CProjectileConeOfCold]            = "CProjectileConeOfCold",
	[EEex_Projectile_Type.CProjectileFall]                  = "CProjectileFall",
	[EEex_Projectile_Type.CProjectileFireHands]             = "CProjectileFireHands",
	[EEex_Projectile_Type.CProjectileInstant]               = "CProjectileInstant",
	--[EEex_Projectile_Type.CProjectileInvisibleTravelling] = "CProjectileInvisibleTravelling",
	--[EEex_Projectile_Type.CProjectileLightningBolt]       = "CProjectileLightningBolt",
	--[EEex_Projectile_Type.CProjectileLightningBoltGround] = "CProjectileLightningBoltGround",
	--[EEex_Projectile_Type.CProjectileLightningBounce]     = "CProjectileLightningBounce",
	--[EEex_Projectile_Type.CProjectileLightningStorm]      = "CProjectileLightningStorm",
	--[EEex_Projectile_Type.CProjectileMagicMissileMulti]   = "CProjectileMagicMissileMulti",
	[EEex_Projectile_Type.CProjectileMulti]                 = "CProjectileMulti",
	[EEex_Projectile_Type.CProjectileMushroom]              = "CProjectileMushroom",
	[EEex_Projectile_Type.CProjectileNewScorcher]           = "CProjectileNewScorcher",
	[EEex_Projectile_Type.CProjectileScorcher]              = "CProjectileScorcher",
	[EEex_Projectile_Type.CProjectileSegment]               = "CProjectileSegment",
	[EEex_Projectile_Type.CProjectileSkyStrike]             = "CProjectileSkyStrike",
	[EEex_Projectile_Type.CProjectileSkyStrikeBAM]          = "CProjectileSkyStrikeBAM",
	[EEex_Projectile_Type.CProjectileSpellHit]              = "CProjectileSpellHit",
	[EEex_Projectile_Type.CProjectileTravelDoor]            = "CProjectileTravelDoor",
}

function EEex_Projectile_CastUserType(projectile)

	if not projectile then
		return nil
	end

	local usertype = EEex_Projectile_Private_CastUserTypes[projectile:getType()]
	return usertype and EEex_CastUD(projectile, usertype) or projectile
end
EEex_Projectile_CastUT = EEex_Projectile_CastUserType

-- @bubb_doc { EEex_Projectile_GetType / instance_name=getType }
--
-- @summary: Returns the ``EEex_Projectile_Type`` of the given ``projectile``.
--
-- @self { projectile / usertype=CProjectile }: The projectile whose type is being fetched.
--
-- @return { type = EEex_Projectile_Type }: See summary.
--
-- @extra_comment:
--
-- ==========================================================================================================================================================================================================
--
-- **EEex_Projectile_Type**
-- ************************
-- +-------------------------+-------------+
-- | Name                    | Description |
-- +=========================+=============+
-- | Unknown                 |             |
-- +-------------------------+-------------+
-- | CProjectile             |             |
-- +-------------------------+-------------+
-- | CProjectileAmbiant      |             |
-- +-------------------------+-------------+
-- | CProjectileArea         |             |
-- +-------------------------+-------------+
-- | CProjectileBAM          |             |
-- +-------------------------+-------------+
-- | CProjectileChain        |             |
-- +-------------------------+-------------+
-- | CProjectileColorSpray   |             |
-- +-------------------------+-------------+
-- | CProjectileConeOfCold   |             |
-- +-------------------------+-------------+
-- | CProjectileFall         |             |
-- +-------------------------+-------------+
-- | CProjectileFireHands    |             |
-- +-------------------------+-------------+
-- | CProjectileInstant      |             |
-- +-------------------------+-------------+
-- | CProjectileMulti        |             |
-- +-------------------------+-------------+
-- | CProjectileMushroom     |             |
-- +-------------------------+-------------+
-- | CProjectileNewScorcher  |             |
-- +-------------------------+-------------+
-- | CProjectileScorcher     |             |
-- +-------------------------+-------------+
-- | CProjectileSegment      |             |
-- +-------------------------+-------------+
-- | CProjectileSkyStrike    |             |
-- +-------------------------+-------------+
-- | CProjectileSkyStrikeBAM |             |
-- +-------------------------+-------------+
-- | CProjectileSpellHit     |             |
-- +-------------------------+-------------+
-- | CProjectileTravelDoor   |             |
-- +-------------------------+-------------+

function EEex_Projectile_GetType(projectile)
	local type = EEex_Projectile_Private_VFTableToType[EEex_ReadPtr(EEex_UDToPtr(projectile))]
	return type or EEex_Projectile_Type.Unknown
end
CProjectile.getType = EEex_Projectile_GetType

-- @bubb_doc { EEex_Projectile_IsOfType / instance_name=isOfType }
--
-- @summary:
--
--     Returns ``true`` if ``projectile`` has the type ``checkType`` or is a derivative thereof.
--
--     This is useful to ensure that a projectile is of a certain type before accessing members
--     it may or may not have.
--
-- @self { projectile / usertype=CProjectile }: The projectile whose type is being checked.
--
-- @param { checkType / type=EEex_Projectile_Type }: The type to check against.
--
-- @return { type=boolean }: See summary.

function EEex_Projectile_IsOfType(projectile, checkType)
	local projType = projectile:getType()
	return EEex_BAnd(EEex_Projectile_Private_Inheritance[projType], checkType) ~= 0x0
end
CProjectile.isOfType = EEex_Projectile_IsOfType
