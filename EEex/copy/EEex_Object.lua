
EEex_LuaObject = nil

-------------
-- General --
-------------

-- Compiles the given object string and returns the resulting CAIObjectType.
-- If the string contains errors, the resulting type acts as "Myself".
-- Call :free() on the returned CAIObjectType when it is no longer needed.
function EEex_Object_ParseString(string)
	local toReturn = EEex_NewUD("CAIObjectType")
	toReturn.free = function(objectType)
		objectType:Destruct()
		EEex_FreeUD(objectType)
	end
	EEex_RunWithStackManager({
		{ ["name"] = "scriptFile", ["struct"] = "CAIScriptFile" },
		{ ["name"] = "cstring", ["struct"] = "CString", ["constructor"] = { ["args"] = { string } } } },
		function(manager)
			manager:getUD("scriptFile"):ParseObjectType(toReturn, manager:getUD("cstring"))
		end)
	return toReturn
end

-- Evaluates the given CAIObjectType in the context of aiBase and returns the found object (or nil).
function EEex_Object_EvalAsAIBase(objectType, aiBase, checkBackList)
	return EEex_RunWithStackManager({
		{ ["name"] = "objectTypeCopy", ["struct"] = "CAIObjectType",
			["constructor"] = { ["variant"] = "copy", ["args"] = { objectType } }
		} },
		function(manager)
			local objectTypeCopy = manager:getUD("objectTypeCopy")
			objectTypeCopy:Decode(aiBase)
			return EEex_GameObject_CastUT(objectTypeCopy:GetShare(aiBase, checkBackList and 1 or 0))
		end)
end
CAIObjectType.evalAsAIBase = EEex_Object_EvalAsAIBase

-- Evaluates the given object string in the context of aiBase and returns the found object (or nil).
-- Prefer using compiled object types when efficiency is required.
function EEex_Object_EvalStringAsAIBase(string, aiBase, checkBackList)
	return EEex_RunWithStackManager({
		{ ["name"] = "scriptFile", ["struct"] = "CAIScriptFile" },
		{ ["name"] = "cstring", ["struct"] = "CString", ["constructor"] = { ["args"] = { string } } },
		{ ["name"] = "objectType", ["struct"] = "CAIObjectType" } },
		function(manager)
			local objectType = manager:getUD("objectType")
			manager:getUD("scriptFile"):ParseObjectType(objectType, manager:getUD("cstring"))
			objectType:Decode(aiBase)
			return EEex_GameObject_CastUT(objectType:GetShare(aiBase, checkBackList and 1 or 0))
		end)
end

-----------
-- Hooks --
-----------

function EEex_Object_Hook_ForceIgnoreActorScriptName(aiType)
	return aiType.m_SpecialCase:get(0) == 117
end

EEex_Object_Hook_OnEvaluatingUnknown_ReturnType = {
	["HANDLED_CONTINUE"] = 0,
	["HANDLED_DONE"] = 1,
	["UNHANDLED"] = 2,
}

function EEex_Object_Hook_OnEvaluatingUnknown(decodingAIType, caller, nSpecialCaseI, curAIType)

	local nObjectIDS = decodingAIType.m_SpecialCase:get(nSpecialCaseI)

	local setObject = function(object)
		if object then
			curAIType:Set(object:virtual_GetAIType())
			return EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_CONTINUE
		else
			decodingAIType:Set(CAIObjectType.NOONE)
			return EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_DONE
		end
	end

	local setInstance = function(objectID)
		return setObject(objectID and EEex_GameObject_Get(objectID) or nil)
	end

	if nObjectIDS == 115 then -- EEex_LuaObject

		return setObject(EEex_LuaObject)

	elseif nObjectIDS == 116 then -- EEex_MatchObject

		return setInstance(EEex_GetUDAux(caller)["EEex_MatchObject"])

	elseif nObjectIDS == 117 then -- EEex_Target

		local targetTable = EEex_Utility_GetOrCreate(EEex_GetUDAux(caller), "EEex_Target", {})
		return setInstance(targetTable[curAIType.m_name.m_pchData:get()])
	end

	return EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.UNHANDLED
end
