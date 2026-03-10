
----------------------------------------------------------------------------------------------------------
-- Fix quick spell slots not updating when a special ability is added (for example, by op171 or act279) --
----------------------------------------------------------------------------------------------------------

function EEex_Fix_Hook_OnAddSpecialAbility(sprite, spell)
	EEex_RunWithStackManager({
		{ ["name"] = "abilityId", ["struct"] = "CAbilityId" } },
		function(manager)
			local abilityId = manager:getUD("abilityId")
			abilityId.m_itemType = 1 -- spell, not an item
			abilityId.m_res:copy(spell.cResRef)
			-- CAbilityId* ab, short changeAmount, int remove, int removeSpellIfZero
			sprite:CheckQuickLists(abilityId, 1, 0, 0);
		end)
end

--------------------------------------------------------------------------------------------------------------------------
-- Fix Spell() and SpellPoint() not being disruptable if the creature is facing SSW(1), SWW(3), NWW(5), NNW(7), NNE(9), --
-- NEE(11), SEE(13), or SSE(15)                                                                                         --
--------------------------------------------------------------------------------------------------------------------------

function EEex_Fix_Hook_ShouldForceMainSpellActionCode(sprite, point)

	local forcing = EEex_GetUDAux(sprite)["EEex_Fix_HasSpellOrSpellPointStartedCasting"] == 1

	-- If I force the main spell action code, the direction-setting code
	-- isn't run. Manually do that here so sprites still turn to face
	-- their target after they have started the casting glow.
	if forcing then
		local message = EEex_NewUD("CMessageSetDirection")
		message:Construct(point, sprite.m_id, sprite.m_id)
		EngineGlobals.g_pBaldurChitin.m_cMessageHandler:AddMessage(message, 0)
	end

	return forcing
end

function EEex_Fix_Hook_OnSpellOrSpellPointStartedCastingGlow(sprite)
	EEex_GetUDAux(sprite)["EEex_Fix_HasSpellOrSpellPointStartedCasting"] = 1
end

-----------------------------------------------------------------------------------------------------
-- Fix SPLPROT.2DA stat comparisons not respecting signed stat storage (e.g. negative resistances) --
-----------------------------------------------------------------------------------------------------

-- The patch-side assembly receives the raw stat id as an unsigned 16-bit value.
-- A 64 KiB byte map lets the hook answer "is this stat stored as signed?" with
-- one indexed load and no Lua / table lookup inside the hot compare path.
-- 0x10000 bytes = one byte for every possible 16-bit stat id value.
EEex_Fix_Private_SignedSplprotStatBitmap = EEex_Malloc(0x10000)
-- Default every entry to 0 ("not known to require signed relational compares").
-- This initial clear is a defensive safe default for freshly allocated native memory,
-- before the game-state initialization listener has had a chance to populate the bitmap.
-- Initialization below flips only the confirmed signed stat ids to 1.
EEex_Memset(EEex_Fix_Private_SignedSplprotStatBitmap, 0, 0x10000)

-- Source of truth for signedness:
--   * CDerivedStats::GetAtOffset() in the game executable
--   * CDerivedStatsTemplate in the matching PDB
--
-- The generated manifest contains the vanilla stat ids whose engine-native storage is signed.
--
-- Variants: BGEE, BG2EE, IWDEE

-- NOTE:
--   This list is generated from EXE/PDB analysis. It is embedded here so the
--   runtime hook can stay data-only: the hook just consults the bitmap and does
--   not need to know anything about engine field names or IDS labels.
EEex_Fix_Private_SignedSplprotStatIDs = {
	1, -- m_nMaxHitPoints
	2, -- m_nArmorClass
	3, -- m_nACCrushingMod
	4, -- m_nACMissileMod
	5, -- m_nACPiercingMod
	6, -- m_nACSlashingMod
	7, -- m_nTHAC0
	8, -- m_nNumberOfAttacks
	9, -- m_nSaveVSDeath
	10, -- m_nSaveVSWands
	11, -- m_nSaveVSPoly
	12, -- m_nSaveVSBreath
	13, -- m_nSaveVSSpell
	14, -- m_nResistFire
	15, -- m_nResistCold
	16, -- m_nResistElectricity
	17, -- m_nResistAcid
	18, -- m_nResistMagic
	19, -- m_nResistMagicFire
	20, -- m_nResistMagicCold
	21, -- m_nResistSlashing
	22, -- m_nResistCrushing
	23, -- m_nResistPiercing
	24, -- m_nResistMissile
	25, -- m_nLore
	26, -- m_nLockPicking
	27, -- m_nMoveSilently
	28, -- m_nTraps
	29, -- m_nPickPocket
	30, -- m_nFatigue
	31, -- m_nIntoxication
	32, -- m_nLuck
	33, -- m_nTracking
	35, -- m_nSex
	36, -- m_nSTR
	37, -- m_nSTRExtra
	38, -- m_nINT
	39, -- m_nWIS
	40, -- m_nDEX
	41, -- m_nCON
	42, -- m_nCHR
	48, -- m_nReputation
	49, -- m_nHatedRace
	50, -- m_nDamageBonus
	51, -- m_nSpellFailureMage
	52, -- m_nSpellFailurePriest
	53, -- m_nSpellDurationModMage
	54, -- m_nSpellDurationModPriest
	55, -- m_nTurnUndeadLevel
	56, -- m_nBackstabDamageMultiplier
	57, -- m_nLayOnHandsAmount
	58, -- m_bHeld
	59, -- m_bPolymorphed
	60, -- m_nTranslucent
	61, -- m_bIdentifyMode
	62, -- m_bEntangle
	63, -- m_bSanctuary
	64, -- m_bMinorGlobe
	65, -- m_bShieldGlobe
	66, -- m_bGrease
	67, -- m_bWeb
	70, -- m_bCasterHold
	71, -- m_nEncumberance
	72, -- m_nMissileTHAC0Bonus
	73, -- m_nMagicDamageResistance
	74, -- m_nResistPoison
	75, -- m_bDoNotJump
	76, -- m_bAuraCleansing
	77, -- m_nMentalSpeed
	78, -- m_nPhysicalSpeed
	79, -- m_nCastingLevelBonusMage
	80, -- m_nCastingLevelBonusCleric
	81, -- m_bSeeInvisible
	82, -- m_bIgnoreDialogPause
	83, -- m_nMinHitPoints
	84, -- m_THAC0BonusRight
	85, -- m_THAC0BonusLeft
	86, -- m_DamageBonusRight
	87, -- m_DamageBonusLeft
	88, -- m_nStoneSkins
	89, -- m_nProficiencyBastardSword
	90, -- m_nProficiencyLongSword
	91, -- m_nProficiencyShortSword
	92, -- m_nProficiencyAxe
	93, -- m_nProficiencyTwoHandedSword
	94, -- m_nProficiencyKatana
	95, -- m_nProficiencyScimitarWakisashiNinjaTo
	96, -- m_nProficiencyDagger
	97, -- m_nProficiencyWarhammer
	98, -- m_nProficiencySpear
	99, -- m_nProficiencyHalberd
	100, -- m_nProficiencyFlailMorningStar
	101, -- m_nProficiencyMace
	102, -- m_nProficiencyQuarterStaff
	103, -- m_nProficiencyCrossbow
	104, -- m_nProficiencyLongBow
	105, -- m_nProficiencyShortBow
	106, -- m_nProficiencyDart
	107, -- m_nProficiencySling
	108, -- m_nProficiencyBlackjack
	109, -- m_nProficiencyGun
	110, -- m_nProficiencyMartialArts
	111, -- m_nProficiency2Handed
	112, -- m_nProficiencySwordAndShield
	113, -- m_nProficiencySingleWeapon
	114, -- m_nProficiency2Weapon
	115, -- m_nProficiencyClub
	116, -- m_nExtraProficiency2
	117, -- m_nExtraProficiency3
	118, -- m_nExtraProficiency4
	119, -- m_nExtraProficiency5
	120, -- m_nExtraProficiency6
	121, -- m_nExtraProficiency7
	122, -- m_nExtraProficiency8
	123, -- m_nExtraProficiency9
	124, -- m_nExtraProficiency10
	125, -- m_nExtraProficiency11
	126, -- m_nExtraProficiency12
	127, -- m_nExtraProficiency13
	128, -- m_nExtraProficiency14
	129, -- m_nExtraProficiency15
	130, -- m_nExtraProficiency16
	131, -- m_nExtraProficiency17
	132, -- m_nExtraProficiency18
	133, -- m_nExtraProficiency19
	134, -- m_nExtraProficiency20
	135, -- m_nHideInShadows
	136, -- m_nDetectIllusion
	137, -- m_nSetTraps
	138, -- m_nPuppetMasterId
	139, -- m_nPuppetMasterType
	140, -- m_nPuppetType
	141, -- m_nPuppetId
	142, -- m_bCheckForBerserk
	143, -- m_bBerserkStage1
	144, -- m_bBerserkStage2
	145, -- m_nDamageLuck
	147, -- m_nVisualRange
	148, -- m_bExplore
	149, -- m_bThrullCharm
	150, -- m_bSummonDisable
	151, -- m_nHitBonus
	153, -- m_bForceSurge
	154, -- m_nSurgeMod
	155, -- m_bImprovedHaste
	166, -- m_nMeleeTHAC0Bonus
	167, -- m_nMeleeDamageBonus
	168, -- m_nMissileDamageBonus
	169, -- m_bDisableCircle
	170, -- m_nFistTHAC0Bonus
	171, -- m_nFistDamageBonus
	174, -- m_bPreventSpellProtectionEffects
	175, -- m_bImmunityToBackStab
	176, -- m_nLockPickingMTPBonus
	177, -- m_nMoveSilentlyMTPBonus
	178, -- m_nTrapsMTPBonus
	179, -- m_nPickPocketMTPBonus
	180, -- m_nHideInShadowsMTPBonus
	181, -- m_nDetectIllusionMTPBonus
	182, -- m_nSetTrapsMTPBonus
	183, -- m_bPreventAISlowDown
	184, -- m_nExistanceDelayOverride
	185, -- m_bAnimationOnlyHaste
	186, -- m_bNoPermanentDeath
	187, -- m_bImmuneToTurnUndead
	188, -- m_bSummonDisableAction
	189, -- m_nChaosShield
	190, -- m_bNPCBump
	191, -- m_bUseAnyItem
	192, -- m_nAssassinate
	193, -- m_bSexChanged
	194, -- m_nSpellFailureInnate
	195, -- m_bImmuneToTracking
	196, -- m_bDeadMagic
	197, -- m_bImmuneToTimeStop
	198, -- m_bImmuneToSequester
	199, -- m_nStoneSkinsGolem
	200, -- m_nLevelDrain
	201, -- m_bDoNotDraw
	202, -- m_bIgnoreDrainDeath
}

-- Special cases intentionally excluded from EEex_Fix_Private_SignedSplprotStatIDs:
--   Stat id 146: GetAtOffset() does not resolve this case to a single CDerivedStatsTemplate field load.
--   m_nSpellDurationModBard: signed CDerivedStatsTemplate field, but no vanilla GetAtOffset() case returns it.
--   m_nClassTypeOverrideMixed: signed CDerivedStatsTemplate field, but no vanilla GetAtOffset() case returns it.
--   m_nClassTypeOverrideLower: signed CDerivedStatsTemplate field, but no vanilla GetAtOffset() case returns it.

local function EEex_Fix_Private_InitializeSignedSplprotStatBitmap()
	-- Rebuild from the manifest each time the game state initializes so the
	-- bitmap always reflects the authoritative signed-id list for this build.
	-- This clear is still required even though the buffer was zeroed at allocation time:
	-- reinitialization only writes 1-bits for signed ids, so stale entries must be cleared first.
	EEex_Memset(EEex_Fix_Private_SignedSplprotStatBitmap, 0, 0x10000)

	for _, statID in ipairs(EEex_Fix_Private_SignedSplprotStatIDs) do
		-- Presence means "treat relational SPLPROT compares for this stat as signed".
		EEex_Write8(EEex_Fix_Private_SignedSplprotStatBitmap + statID, 1)
	end
end

EEex_GameState_AddInitializedListener(function()
	-- The patch code reads this bitmap from native memory, so populate it only
	-- once EEex runtime state is fully available for the current game session.
	EEex_Fix_Private_InitializeSignedSplprotStatBitmap()
end)

--------------------------------------------
-- Fix Baldur.lua values not escaping '\' --
--------------------------------------------

EEex_GameState_AddInitializedListener(function()
	local oldNeedsEscape = needsEscape
	needsEscape = function(str)
		return str:find("\\") or oldNeedsEscape(str)
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- Fix closing the local area map with a double click resulting in the world screen responding to the button up event --
------------------------------------------------------------------------------------------------------------------------

EEex_Fix_Private_IgnoreLButtonUp = false

function EEex_Fix_LuaHook_OnLocalMapDoubleClick()
	EEex_Fix_Private_IgnoreLButtonUp = true
end
