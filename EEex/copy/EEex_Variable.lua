
function EEex_Variable_Find(variableHash, variableName)
	return EEex_RunWithStackManager({
		{ ["name"] = "variableName", ["struct"] = "CString", ["constructor"] = {["args"] = {variableName} }, ["noDestruct"] = true }, },
		function(manager)
			return variableHash:FindKey(manager:getUD("variableName"))
		end)
end
CVariableHash.find = EEex_Variable_Find

function EEex_Variable_GetInt(variableHash, variableName)
	local variable = variableHash:find(variableName)
	return variable and variable.m_intValue or 0
end
CVariableHash.getInt = EEex_Variable_GetInt

function EEex_Variable_GetString(variableHash, variableName)
	local variable = variableHash:find(variableName)
	return variable and variable.m_stringValue:get() or ""
end
CVariableHash.getString = EEex_Variable_GetString

function EEex_Variable_GetOrCreate(variableHash, variableName)
	local variable = variableHash:find(variableName)
	if variable then
		return variable
	else
		EEex_RunWithStackManager({
			{ ["name"] = "variableParam", ["struct"] = "CVariable" }, },
			function(manager)
				local variableParam = manager:getUD("variableParam")
				variableParam.m_name:set(variableName)
				variableHash:AddKey(variableParam)
			end)
		return variableHash:find(variableName)
	end
end
CVariableHash.getOrCreate = EEex_Variable_GetOrCreate

function EEex_Variable_SetInt(variableHash, variableName, value)
	variableHash:getOrCreate(variableName).m_intValue = value
end
CVariableHash.setInt = EEex_Variable_SetInt

function EEex_Variable_SetString(variableHash, variableName, value)
	variableHash:getOrCreate(variableName).m_stringValue:set(value)
end
CVariableHash.setString = EEex_Variable_SetString
