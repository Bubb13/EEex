
--------------------------------
-- Memory Manager Definitions --
--------------------------------

EEex_MemoryManagerStructDefinitions["C2DArray"] = {
	["constructors"] = {
		["#default"] = C2DArray.Construct,
	},
	["destructor"] = C2DArray.Destruct,
}

EEex_MemoryManagerStructDefinitions["CAIAction"] = {
	["constructors"] = {
		["copy"] = CAIAction.ConstructCopy,
	},
	["destructor"] = CAIAction.Destruct,
}

EEex_MemoryManagerStructDefinitions["CAIObjectType"] = {
	["constructors"] = {
		["#default"] = function(objectType)
			objectType:Construct1(0, 0, 0, 0, 0, 0, 0, -1)
		end,
		["copy"] = CAIObjectType.ConstructCopy,
	},
	["destructor"] = CAIObjectType.Destruct,
}

EEex_MemoryManagerStructDefinitions["CAIScriptFile"] = {
	["constructors"] = {
		["#default"] = CAIScriptFile.Construct,
	},
	["destructor"] = CAIScriptFile.Destruct,
}

EEex_MemoryManagerStructDefinitions["CPoint"] = {
	["constructors"] = {
		["fromXY"] = function(point, x, y)
			point.x = x
			point.y = y
		end,
	},
}

EEex_MemoryManagerStructDefinitions["CResRef"] = {
	["constructors"] = {
		["#default"] = CResRef.set,
	},
}

EEex_MemoryManagerStructDefinitions["CString"] = {
	["constructors"] = {
		["#default"] = CString.ConstructFromChars,
	},
	["destructor"] = CString.Destruct,
}

EEex_MemoryManagerStructDefinitions["CVariable"] = {
	["constructors"] = {
		["#default"] = CVariable.Construct,
	},
}

EEex_MemoryManagerStructDefinitions["string"] = {
	["constructors"] = {
		["#default"] = function(address, luaString)
			EEex_WriteString(address, luaString)
		end,
	},
	["size"] = function(luaString)
		return #luaString + 1
	end,
}

EEex_MemoryManagerStructDefinitions["uninitialized"] = {
	["size"] = function(size)
		return size
	end,
}
