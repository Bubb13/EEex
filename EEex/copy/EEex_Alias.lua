
(function()

	local alias = function(func)
		if not func then error("Missing alias source") end
		return func
	end

	---------------
	-- CAIAction --
	---------------

	CAIAction.Construct1 = alias(CAIAction.Construct_Overload_ActionID_DestPoint_SpecificID_SpecificID2)
	CAIAction.ConstructCopy = alias(CAIAction.Construct_Overload_Copy)
	CAIAction.operator_equ = alias(CAIAction.AssignmentOperator)

	---------------
	-- CAIIdList --
	---------------

	CAIIdList.Construct1 = alias(CAIIdList.Construct_Overload_Default)
	CAIIdList.FindID = alias(CAIIdList.Find_Overload_ID)
	CAIIdList.LoadList2 = alias(CAIIdList.LoadList_Overload_Resref)

	-------------------
	-- CAIObjectType --
	-------------------

	CAIObjectType.Construct1 = alias(CAIObjectType.Construct_Overload_Manual)
	CAIObjectType.ConstructCopy = alias(CAIObjectType.Construct_Overload_Copy)

	---------------
	-- CAIScript --
	---------------

	CAIScript.Construct1 = alias(CAIScript.Construct_Overload_Manual)

	----------------
	-- CAITrigger --
	----------------

	CAITrigger.ConstructCopy = alias(CAITrigger.Construct_Overload_Copy)

	-----------------
	-- CGameAIBase --
	-----------------

	CGameAIBase.GetTargetShareType1 = alias(CGameAIBase.GetTargetShareType_Overload_AIType_ObjectType)
	CGameAIBase.GetTargetShareType2 = alias(CGameAIBase.GetTargetShareType_Overload_ObjectType)

	---------------
	-- CGameArea --
	---------------

	CGameArea.GetAllInRange1 = alias(CGameArea.GetAllInRange_Overload_Point)
	CGameArea.GetAllInRange2 = alias(CGameArea.GetAllInRange_Overload_VertListPos)
	CGameArea.GetNearest2 = alias(CGameArea.GetNearest_Overload_Point)

	-----------
	-- CItem --
	-----------

	CItem.Construct3 = alias(CItem.Construct_Overload_Manual)

	-------------
	-- CString --
	-------------

	CString.ConstructFromChars = alias(CString.Construct_Overload_String)
	CString.ConstructFromCString = alias(CString.Construct_Overload_CString)
	CString.SetFromChars = alias(CString.AssignmentOperator_Overload_String)
	CString.SetFromCString = alias(CString.AssignmentOperator_Overload_CString)

end)()
