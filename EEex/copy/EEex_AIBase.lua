
-- @bubb_doc { EEex_AIBase_GetScriptLevel / instance_name=getScriptLevel }
--
-- @summary: Returns the ``aiBase``'s ``CAIScript`` for the given ``scriptLevel``.
--
-- @self { aiBase / usertype=CGameAIBase }: The object whose script is being fetched.
--
-- @param { scriptLevel / type=number }: The level of the script to fetch. Valid values identical to `SCRLEV.IDS`_.
--
-- @return { usertype=CAIScript }: See summary.
--
-- @extra_comment:
--
-- =================================================================================================================
--
-- **SCRLEV.IDS**
-- **************
--
-- +--------------+---------------+
-- | Script Level | Symbolic Name |
-- +==============+===============+
-- | 0            | OVERRIDE      |
-- +--------------+---------------+
-- | 1            | AREA          |
-- +--------------+---------------+
-- | 2            | SPECIFICS     |
-- +--------------+---------------+
-- | 4            | CLASS         |
-- +--------------+---------------+
-- | 5            | RACE          |
-- +--------------+---------------+
-- | 6            | GENERAL       |
-- +--------------+---------------+
-- | 7            | DEFAULT       |
-- +--------------+---------------+

function EEex_AIBase_GetScriptLevel(aiBase, scriptLevel)
	return ({
		[0] = aiBase.m_overrideScript,
		[1] = aiBase.m_areaScript,
		[2] = aiBase.m_specificsScript,
		[4] = aiBase.m_classScript,
		[5] = aiBase.m_raceScript,
		[6] = aiBase.m_generalScript,
		[7] = aiBase.m_defaultScript,
	})[scriptLevel]
end
CGameAIBase.getScriptLevel = EEex_AIBase_GetScriptLevel

-- @bubb_doc { EEex_AIBase_GetScriptLevelResRef / instance_name=getScriptLevelResRef }
--
-- @summary: Returns a string that represents the ``aiBase``'s ``CResRef`` for the given ``scriptLevel``.
--           If the given ``scriptLevel`` is not populated, returns ``""``.
--
-- @self { aiBase / usertype=CGameAIBase }: The object whose script resref is being fetched.
--
-- @param { scriptLevel / type=number }: The level of the script resref to fetch. Valid values identical to `SCRLEV.IDS`_.
--
-- @return { type=string }: See summary.

function EEex_AIBase_GetScriptLevelResRef(aiBase, scriptLevel)
	local script = aiBase:getScriptLevel(scriptLevel)
	return script and script.cResRef:get() or ""
end
CGameAIBase.getScriptLevelResRef = EEex_AIBase_GetScriptLevelResRef

-- @bubb_doc { EEex_AIBase_SetScriptLevel / instance_name=setScriptLevel }
--
-- @summary: Sets the ``aiBase``'s ``CAIScript`` for the given ``scriptLevel`` to ``script``.
--
-- @self { aiBase / usertype=CGameAIBase }: The object whose script level is being set.
--
-- @param { scriptLevel / type=number }: The level of the script to set. Valid values identical to `SCRLEV.IDS`_.
--
-- @param { script / usertype=CAIScript }:
--
--     The script to assign to ``scriptLevel``.  @EOL @EOL
--
--     **Note:** ``aiBase`` **holds a reference to this parameter; do not free it.**

function EEex_AIBase_SetScriptLevel(aiBase, scriptLevel, script)
	aiBase:virtual_SetScript(scriptLevel, script)
end
CGameAIBase.setScriptLevel = EEex_AIBase_SetScriptLevel

-- @bubb_doc { EEex_AIBase_SetScriptLevelResRef / instance_name=setScriptLevelResRef }
--
-- @summary: Loads the script with the given ``resref`` and sets the ``aiBase``'s ``CAIScript`` for the given ``scriptLevel`` to it.
--
-- @self { aiBase / usertype=CGameAIBase }: The object whose script level is being set.
--
-- @param { scriptLevel / type=number }: The level of the script to set. Valid values identical to `SCRLEV.IDS`_.
--
-- @param { resref / type=string }: The script resref to assign to ``scriptLevel``.
--
-- @param { bPlayerScript / type=boolean / default=false }:
--
--     If ``true``, signifies that ``resref`` has the extension ``.BS`` instead of ``.BCS``.  @EOL @EOL
--
--     **Note:** Due to the enhanced edition’s use of script caching, the engine has trouble  @EOL
--     differentiating between ``.BS`` and ``.BCS`` files with the same name. If a script     @EOL
--     with the given ``resref`` has already been loaded by the engine, that script will be   @EOL
--     used, regardless of ``bPlayerScript``.
--

function EEex_AIBase_SetScriptLevelResRef(aiBase, scriptLevel, resref, bPlayerScript)

	local newScript = EEex_NewUD("CAIScript")

	EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = {["args"] = {resref} }}, },
		function(manager)
			newScript:Construct1(manager:getUD("resref"), EEex_Utility_Default(bPlayerScript, false))
		end)

	aiBase:setScriptLevel(scriptLevel, newScript)
end
CGameAIBase.setScriptLevelResRef = EEex_AIBase_SetScriptLevelResRef

-- @bubb_doc { EEex_AIBase_SetStoredScriptingTarget / instance_name=setStoredScriptingTarget }
--
-- @summary: Stores ``target`` on ``aiBase`` for use with the ``EEex_Target`` scripting object.
--
-- @self { aiBase / usertype=CGameAIBase }: The object that the target is being stored on.
--
-- @param { targetKey / type=string }: The name to be used to refer to the target being stored.
--
-- @param { target / usertype=CGameObject }: The target being stored on ``aiBase`` as ``targetKey``.
--
-- @extra_comment:
--
-- ================================================================================================================
--
-- **Example**
-- ***********
--
-- A combination of ``EEex_AIBase_SetStoredScriptingTarget`` and ``EEex_LuaTrigger`` can be used to target specific
-- objects programmatically. The following example shows how you could use this concept to have a creature start
-- dialog once they see the current party leader:
--
-- **In M_*.lua file:**
-- """"""""""""""""""""
--
-- .. code-block:: Lua
--
--    function StoreAlivePartyLeader()
--
--        local partyLeader = nil
--
--        for i = 0, 5 do
--            local partyMember = EEex_Sprite_GetInPortrait(i)
--            if partyMember and EEex_BAnd(partyMember.m_baseStats.m_generalState, 0xFC0) == 0 then
--                partyLeader = partyMember
--                break
--            end
--        end
--
--        EEex_LuaTrigger_Object:setStoredScriptingTarget("AlivePartyLeader", partyLeader)
--        return partyLeader ~= nil
--    end
--
-- **In script:**
-- """"""""""""""
--
-- .. code-block:: text
--
--    IF
--        EEex_LuaTrigger("return StoreAlivePartyLeader()")
--        See(EEex_Target("AlivePartyLeader"))
--    THEN
--        RESPONSE #100
--            Dialog(EEex_Target("AlivePartyLeader"))
--    END
--

function EEex_AIBase_SetStoredScriptingTarget(aiBase, targetKey, target)
	local targetTable = EEex_Utility_GetOrCreateTable(EEex_GetUDAux(aiBase), "EEex_Target")
	targetTable[targetKey] = target and target.m_id or nil
end
CGameAIBase.setStoredScriptingTarget = EEex_AIBase_SetStoredScriptingTarget
