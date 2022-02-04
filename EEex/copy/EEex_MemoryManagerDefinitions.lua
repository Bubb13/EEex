
--------------------------------
-- Memory Manager Definitions --
--------------------------------

EEex_MemoryManagerStructDefinitions["C2DArray"] = {
	["constructors"] = {
		["#default"] = C2DArray.Construct,
	},
	["destructor"] = C2DArray.Destruct,
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
