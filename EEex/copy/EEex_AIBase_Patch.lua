
(function()

	EEex_DisableCodeProtection()

	--[[
	+------------------------------------------------------------------------------------------------------------------+
	| Call a hook that tracks when scripting objects are updated                                                       |
	+------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] CGameAIBase::Override_ApplyTriggers()                                                               |
	|   [EEex.dll] CGameAIBase::Override_SetTrigger(pTrigger: const CAITrigger*)                                       |
	|   [EEex.dll] CMessageSetLastObject::Override_Run()                                                               |
	|   [Lua] EEex_AIBase_LuaHook_OnScriptingObjectUpdated(aiBase: CGameAIBase, scriptingObject: EEex_ScriptingObject) |
	+------------------------------------------------------------------------------------------------------------------+
	--]]

	local override = function(label, replacementLabel)
		EEex_JITAt(EEex_Label(label), {"jmp #$(1) #ENDL", {EEex_Label(replacementLabel)}})
	end

	override("Hook-CGameAIBase::ApplyTriggers()-FirstInstruction", "CGameAIBase::Override_ApplyTriggers")
	override("Hook-CGameAIBase::SetTrigger()-FirstInstruction", "CGameAIBase::Override_SetTrigger")
	override("Hook-CMessageSetLastObject::Run()-FirstInstruction", "CMessageSetLastObject::Override_Run")


	EEex_EnableCodeProtection()

end)()
