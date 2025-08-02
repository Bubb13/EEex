
--=============
-- Constants ==
--=============

EEex_Options_KeybindFireType = {
	["UP"]   = true,
	["DOWN"] = false,
}

--=========
-- Types ==
--=========

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutObject  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutObject = {}
EEex_Options_Private_LayoutObject.__index = EEex_Options_Private_LayoutObject
--print("EEex_Options_Private_LayoutObject: "..tostring(EEex_Options_Private_LayoutObject))

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutObject:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutObject, "_init", self)
	-- Derived
	self._layoutLeft   = 0
	self._layoutTop    = 0
	self._layoutRight  = 0
	self._layoutBottom = 0
	self._layoutWidth  = 0
	self._layoutHeight = 0
end

function EEex_Options_Private_LayoutObject:_calculateDerivedLayout()
	self._layoutWidth = self._layoutRight - self._layoutLeft
	self._layoutHeight = self._layoutBottom - self._layoutTop
end

function EEex_Options_Private_LayoutObject:_onParentLayoutCalculated(left, top, right, bottom)
	-- Empty stub
end

function EEex_Options_Private_LayoutObject:_onInitLayout()
	-- Empty stub
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutObject:inset(o)
	o.children = {self}
	return EEex_Options_Private_LayoutInset.new(o)
end

function EEex_Options_Private_LayoutObject:layout(left, top, right, bottom)
	self:_onInitLayout()
	self:calculateLayout(left, top, right, bottom)
	self:doLayout()
end

function EEex_Options_Private_LayoutObject:getLayoutLeft()
	return self._layoutLeft
end

function EEex_Options_Private_LayoutObject:getLayoutTop()
	return self._layoutTop
end

function EEex_Options_Private_LayoutObject:getLayoutRight()
	return self._layoutRight
end

function EEex_Options_Private_LayoutObject:getLayoutBottom()
	return self._layoutBottom
end

function EEex_Options_Private_LayoutObject:getLayoutWidth()
	return self._layoutWidth
end

function EEex_Options_Private_LayoutObject:getLayoutHeight()
	return self._layoutHeight
end

function EEex_Options_Private_LayoutObject:showBeforeLayout()
	-- Empty stub
end

function EEex_Options_Private_LayoutObject:showAfterLayout()
	-- Empty stub
end

function EEex_Options_Private_LayoutObject:hide()
	-- Empty stub
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutObject  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutParent  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutParent = {}
EEex_Options_Private_LayoutParent.__index = EEex_Options_Private_LayoutParent
setmetatable(EEex_Options_Private_LayoutParent, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutParent: "..tostring(EEex_Options_Private_LayoutParent))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutParent.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutParent)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutParent:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutParent, "_init", self)
	if self.children == nil then self.children = {} end
end

function EEex_Options_Private_LayoutParent:_getChildLayout(child)
	return child
end

function EEex_Options_Private_LayoutParent:_onInitLayout()
	for _, child in ipairs(self.children) do
		self:_getChildLayout(child):_onInitLayout()
	end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutParent:calculateLayout(left, top, right, bottom)

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = right
	self._layoutBottom = bottom
	self:_calculateDerivedLayout()

	for _, child in ipairs(self.children) do
		local childLayout = self:_getChildLayout(child)
		childLayout:calculateLayout(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
		childLayout:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
		-- TODO: Re-layout child
	end

	--print(string.format("[EEex_Options_Private_LayoutParent:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutParent:doLayout()
	for _, child in ipairs(self.children) do
		self:_getChildLayout(child):doLayout()
	end
end

function EEex_Options_Private_LayoutParent:showBeforeLayout()
	for _, child in ipairs(self.children) do
		self:_getChildLayout(child):showBeforeLayout()
	end
end

function EEex_Options_Private_LayoutParent:showAfterLayout()
	for _, child in ipairs(self.children) do
		self:_getChildLayout(child):showAfterLayout()
	end
end

function EEex_Options_Private_LayoutParent:hide()
	for _, child in ipairs(self.children) do
		self:_getChildLayout(child):hide()
	end
end

function EEex_Options_Private_LayoutParent:addChild(child)
	table.insert(self.children, child)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutParent  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutVerticalTabArea ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutVerticalTabArea = {}
EEex_Options_Private_LayoutVerticalTabArea.__index = EEex_Options_Private_LayoutVerticalTabArea
setmetatable(EEex_Options_Private_LayoutVerticalTabArea, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutVerticalTabArea: "..tostring(EEex_Options_Private_LayoutVerticalTabArea))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutVerticalTabArea.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutVerticalTabArea)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutVerticalTabArea:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutVerticalTabArea, "_init", self)
	if self.menuName               == nil then EEex_Error("menuName required")             end
	if self.tabs                   == nil then EEex_Error("tabs required")                 end
	if self.tabsListName           == nil then EEex_Error("tabsListName required")         end
	if self.tabsSelectionVarName   == nil then EEex_Error("tabsSelectionVarName required") end
	if self.tabsListRowHeight      == nil then EEex_Error("tabsListRowHeight required")    end
	if self.separatorPad           == nil then self.separatorPad           = 5             end
	if self.separatorWidth         == nil then self.separatorWidth         = 2             end
	if self.tabsListTopPad         == nil then self.tabsListTopPad         = 0             end
	if self.tabsListBottomPad      == nil then self.tabsListBottomPad      = 0             end
	if self.tabsListScrollbarWidth == nil then self.tabsListScrollbarWidth = 0             end
	-- Derived
	--   self._openTabIndex
end

function EEex_Options_Private_LayoutVerticalTabArea:_onInitLayout()
	for _, tab in ipairs(self.tabs) do
		tab.layout:_onInitLayout()
	end
end

function EEex_Options_Private_LayoutVerticalTabArea:_calculateSidebarWidth()

	local maxWidth = 0

	for _, v in ipairs(self.tabs) do
		local width = EEex_Options_Private_GetTextWidthHeight(styles.normal.font, styles.normal.point, t(v.label))
		if width > maxWidth then
			maxWidth = width
		end
	end

	self.sidebarWidth = maxWidth + self.tabsListScrollbarWidth
end

function EEex_Options_Private_LayoutVerticalTabArea:_onTabSelected(index)
	if self._openTabIndex == index then return end
	self:closeCurrentTab()
	local tabEntry = self.tabs[index]
	if tabEntry == nil then return end
	self._openTabIndex = index
	local tabLayout = tabEntry.layout
	tabLayout:showBeforeLayout()
	tabLayout:doLayout()
	tabLayout:showAfterLayout()
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutVerticalTabArea:calculateLayout(left, top, right, bottom)

	self:_calculateSidebarWidth()
	local contentLeft = left + self.sidebarWidth + self.separatorPad + self.separatorWidth + self.separatorPad

	local maxRight = 0
	local maxBottom = top + self.tabsListTopPad + #self.tabs * self.tabsListRowHeight + self.tabsListBottomPad

	for _, tab in ipairs(self.tabs) do
		local tabLayout = tab.layout
		tabLayout:calculateLayout(contentLeft, top, right, bottom)
		local tabLayoutRight = tabLayout:getLayoutRight()
		local tabLayoutBottom = tabLayout:getLayoutBottom()
		if tabLayoutRight > maxRight then maxRight = tabLayoutRight end
		if tabLayoutBottom > maxBottom then maxBottom = tabLayoutBottom end
	end

	self._layoutLeft = left
	self._layoutTop = top
	self._layoutRight = maxRight
	self._layoutBottom = maxBottom
	self:_calculateDerivedLayout()

	for _, tab in ipairs(self.tabs) do
		tab.layout:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
		-- TODO: Re-layout child
	end

	--print(string.format("[EEex_Options_Private_LayoutVerticalTabArea:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutVerticalTabArea:doLayout()

	Infinity_SetArea(self.tabsListName,
		self._layoutLeft,
		self._layoutTop + self.tabsListTopPad,
		self.sidebarWidth,
		self._layoutHeight - self.tabsListTopPad - self.tabsListBottomPad
	)

	EEex_Options_Private_CreateSeparator(self.menuName, nil,
		self._layoutLeft + self.sidebarWidth + self.separatorPad, self._layoutTop, self.separatorWidth, self._layoutHeight)

	if self._openTabIndex ~= nil then
		self.tabs[self._openTabIndex].layout:doLayout()
	end
end

function EEex_Options_Private_LayoutVerticalTabArea:closeCurrentTab()
	if self._openTabIndex == nil then return end
	local tabLayout = self.tabs[self._openTabIndex].layout
	tabLayout:hide()
	self._openTabIndex = nil
end

function EEex_Options_Private_LayoutVerticalTabArea:showBeforeLayout()
	_G[self.tabsSelectionVarName] = 0
end

function EEex_Options_Private_LayoutVerticalTabArea:hide()
	self:closeCurrentTab()
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutVerticalTabArea ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutStacking  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutStacking = {}
EEex_Options_Private_LayoutStacking.__index = EEex_Options_Private_LayoutStacking
setmetatable(EEex_Options_Private_LayoutStacking, EEex_Options_Private_LayoutParent)
--print("EEex_Options_Private_LayoutStacking: "..tostring(EEex_Options_Private_LayoutStacking))

EEex_Options_Private_LayoutStacking_AlignFlags = {
	["HORIZONTAL_CENTER"] = 0x1,
	["HORIZONTAL_RIGHT"]  = 0x2,
	["VERTICAL_CENTER"]   = 0x4,
	["VERTICAL_BOTTOM"]   = 0x8,
}

EEex_Options_Private_LayoutStacking_Align = {
	["TOP_LEFT"]      = EEex_Flags({                                                                                                                                  }),
	["TOP_CENTER"]    = EEex_Flags({                                                                 EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_CENTER }),
	["TOP_RIGHT"]     = EEex_Flags({                                                                 EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_RIGHT  }),
	["CENTER_RIGHT"]  = EEex_Flags({ EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_CENTER, EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_RIGHT  }),
	["BOTTOM_RIGHT"]  = EEex_Flags({ EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_BOTTOM, EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_RIGHT  }),
	["BOTTOM_CENTER"] = EEex_Flags({ EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_BOTTOM, EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_CENTER }),
	["BOTTOM_LEFT"]   = EEex_Flags({ EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_BOTTOM                                                                   }),
	["CENTER_LEFT"]   = EEex_Flags({ EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_CENTER                                                                   }),
	["CENTER_CENTER"] = EEex_Flags({ EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_CENTER, EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_CENTER }),
}

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutStacking.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutStacking)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutStacking:_init()
	-- EEex_Options_Private_LayoutParent
	--   self.children
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutStacking, "_init", self)
	if self.growHorizontally == nil then self.growHorizontally = false end
	if self.growVertically   == nil then self.growVertically   = false end
	-- Derived
	--   self._curLayoutWidth
	--   self._curLayoutHeight
end

function EEex_Options_Private_LayoutStacking:_getChildLayout(child)
	return child.layout
end

function EEex_Options_Private_LayoutStacking:_onInitLayout()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutStacking, "_onInitLayout", self)
	self._curLayoutWidth  = nil
	self._curLayoutHeight = nil
end

function EEex_Options_Private_LayoutStacking:_onParentLayoutCalculated(left, top, right, bottom)
	self._curLayoutWidth  = right  - self._layoutLeft
	self._curLayoutHeight = bottom - self._layoutTop
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutStacking:calculateLayout(left, top, right, bottom)

	local calculateLayoutFromChildren = function()

		self._layoutLeft = left
		self._layoutTop  = top

		if not self.growHorizontally or self._curLayoutWidth == nil then

			local maxChildRight  = 0

			for _, child in ipairs(self.children) do
				local childLayout = child.layout
				childLayout:calculateLayout(left, top, right, bottom)
				local childRight = childLayout:getLayoutRight()
				if childRight > maxChildRight then maxChildRight = childRight end
			end

			self._layoutRight = maxChildRight
		else
			self._layoutRight = self._layoutLeft + self._curLayoutWidth
		end

		if not self.growVertically or self._curLayoutHeight == nil then

			local maxChildBottom = 0

			for _, child in ipairs(self.children) do
				local childLayout = child.layout
				childLayout:calculateLayout(left, top, right, bottom)
				local childBottom = childLayout:getLayoutBottom()
				if childBottom > maxChildBottom then maxChildBottom = childBottom end
			end

			self._layoutBottom = maxChildBottom
		else
			self._layoutBottom = self._layoutTop + self._curLayoutHeight
		end

		self:_calculateDerivedLayout()
	end

	while true do

		calculateLayoutFromChildren()

		local dirty = false
		for _, child in ipairs(self.children) do
			if child.layout:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom) then
				dirty = true
			end
		end

		if not dirty then
			break
		end
	end

	if self._curLayoutWidth ~= nil or self._curLayoutHeight ~= nil then

		for _, child in ipairs(self.children) do

			local childAlign  = child.align

			if childAlign then

				local childLayout = child.layout
				local childLeft   = childLayout:getLayoutLeft()
				local childTop    = childLayout:getLayoutTop()
				local childRight  = childLayout:getLayoutRight()
				local childBottom = childLayout:getLayoutBottom()

				if EEex_IsMaskSet(childAlign, EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_CENTER) then
					local centerOffset = (self._layoutHeight - childLayout:getLayoutHeight()) / 2
					childLayout:calculateLayout(childLeft, childTop + centerOffset, childRight, childBottom + centerOffset)
				elseif EEex_IsMaskSet(childAlign, EEex_Options_Private_LayoutStacking_AlignFlags.VERTICAL_BOTTOM) then
					local bottomOffset = self._layoutHeight - childLayout:getLayoutHeight()
					childLayout:calculateLayout(childLeft, childTop + bottomOffset, childRight, childBottom + bottomOffset)
				end

				if EEex_IsMaskSet(childAlign, EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_CENTER) then
					local centerOffset = (self._layoutWidth - childLayout:getLayoutWidth()) / 2
					childLayout:calculateLayout(childLeft + centerOffset, childTop, childRight + centerOffset, childBottom)
				elseif EEex_IsMaskSet(childAlign, EEex_Options_Private_LayoutStacking_AlignFlags.HORIZONTAL_RIGHT) then
					local rightOffset = self._layoutWidth - childLayout:getLayoutWidth()
					childLayout:calculateLayout(childLeft + rightOffset, childTop, childRight + rightOffset, childBottom)
				end
			end
		end
	end

	--print(string.format("[EEex_Options_Private_LayoutStacking:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutStacking  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutVBox  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutVBox = {}
EEex_Options_Private_LayoutVBox.__index = EEex_Options_Private_LayoutVBox
setmetatable(EEex_Options_Private_LayoutVBox, EEex_Options_Private_LayoutParent)
--print("EEex_Options_Private_LayoutVBox: "..tostring(EEex_Options_Private_LayoutVBox))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutVBox.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutVBox)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutVBox:_init()
	-- EEex_Options_Private_LayoutParent
	--   self.children
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutVBox, "_init", self)
	if self.shrinkToChildren == nil then self.shrinkToChildren = true end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutVBox:calculateLayout(left, top, right, bottom)

	local calculateLayoutFromChildren = function()

		local newLayoutRight = right
		local curTop = top

		if self.shrinkToChildren then

			local maxChildRight = 0

			for _, child in ipairs(self.children) do
				child:calculateLayout(left, curTop, right, bottom)
				curTop = curTop + child:getLayoutHeight()
				local childRight = child:getLayoutRight()
				if childRight > maxChildRight then maxChildRight = childRight end
			end

			if maxChildRight < newLayoutRight then
				newLayoutRight = maxChildRight
			end
		else
			for _, child in ipairs(self.children) do
				child:calculateLayout(left, curTop, right, bottom)
				curTop = curTop + child:getLayoutHeight()
			end
		end

		self._layoutLeft   = left
		self._layoutTop    = top
		self._layoutRight  = newLayoutRight
		self._layoutBottom = curTop
		self:_calculateDerivedLayout()
	end

	calculateLayoutFromChildren()

	for _, child in ipairs(self.children) do
		child:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
	end

	-- TODO: Only run this if children changed
	calculateLayoutFromChildren()

	--print(string.format("[EEex_Options_Private_LayoutVBox:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutVBox  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutHBox  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutHBox = {}
EEex_Options_Private_LayoutHBox.__index = EEex_Options_Private_LayoutHBox
setmetatable(EEex_Options_Private_LayoutHBox, EEex_Options_Private_LayoutParent)
--print("EEex_Options_Private_LayoutHBox: "..tostring(EEex_Options_Private_LayoutHBox))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutHBox.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutHBox)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutHBox:_init()
	-- EEex_Options_Private_LayoutParent
	--   self.children
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutHBox, "_init", self)
	if self.shrinkToChildren == nil then self.shrinkToChildren = true end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutHBox:calculateLayout(left, top, right, bottom)

	local calculateLayoutFromChildren = function()

		local newLayoutBottom = bottom
		local curLeft = left

		if self.shrinkToChildren then

			local maxChildBottom = 0

			for _, child in ipairs(self.children) do
				child:calculateLayout(curLeft, top, right, bottom)
				curLeft = curLeft + child:getLayoutWidth()
				local childBottom = child:getLayoutBottom()
				if childBottom > maxChildBottom then maxChildBottom = childBottom end
			end

			if maxChildBottom < newLayoutBottom then
				newLayoutBottom = maxChildBottom
			end
		else
			for _, child in ipairs(self.children) do
				child:calculateLayout(curLeft, top, right, bottom)
				curLeft = curLeft + child:getLayoutWidth()
			end
		end

		self._layoutLeft   = left
		self._layoutTop    = top
		self._layoutRight  = curLeft
		self._layoutBottom = newLayoutBottom
		self:_calculateDerivedLayout()
	end

	calculateLayoutFromChildren()

	for _, child in ipairs(self.children) do
		child:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
	end

	-- TODO: Only run this if children changed
	calculateLayoutFromChildren()

	--print(string.format("[EEex_Options_Private_LayoutHBox:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutHBox  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutInset ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutInset = {}
EEex_Options_Private_LayoutInset.__index = EEex_Options_Private_LayoutInset
setmetatable(EEex_Options_Private_LayoutInset, EEex_Options_Private_LayoutParent)
--print("EEex_Options_Private_LayoutInset: "..tostring(EEex_Options_Private_LayoutInset))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutInset.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutInset)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutInset:_init()
	-- EEex_Options_Private_LayoutParent
	--   self.children
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutInset, "_init", self)
	if self.insetLeft        == nil then self.insetLeft        = 0     end
	if self.insetTop         == nil then self.insetTop         = 0     end
	if self.insetRight       == nil then self.insetRight       = 0     end
	if self.insetBottom      == nil then self.insetBottom      = 0     end
	if self.growToParent     == nil then self.growToParent     = false end
	if self.shrinkToChildren == nil then self.shrinkToChildren = true  end
end

function EEex_Options_Private_LayoutInset:_onParentLayoutCalculated(left, top, right, bottom)

	if not self.growToParent then return end

	local innerLeft   = left   + self.insetLeft
	local innerTop    = top    + self.insetTop
	local innerRight  = right  - self.insetRight
	local innerBottom = bottom - self.insetBottom

	local dirty = false
	for _, child in ipairs(self.children) do
		if child:_onParentLayoutCalculated(innerLeft, innerTop, innerRight, innerBottom) then
			dirty = true
		end
	end

	return dirty
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutInset:calculateLayout(left, top, right, bottom)

	local innerLeft   = left   + self.insetLeft
	local innerTop    = top    + self.insetTop
	local innerRight  = right  - self.insetRight
	local innerBottom = bottom - self.insetBottom

	local calculateLayoutFromChildren = function()

		self._layoutLeft   = left
		self._layoutTop    = top
		self._layoutRight  = right
		self._layoutBottom = bottom

		if self.shrinkToChildren then

			local maxChildRight  = 0
			local maxChildBottom = 0

			for _, child in ipairs(self.children) do
				child:calculateLayout(innerLeft, innerTop, innerRight, innerBottom)
				local childRight  = child:getLayoutRight()
				local childBottom = child:getLayoutBottom()
				if childRight  > maxChildRight  then maxChildRight  = childRight  end
				if childBottom > maxChildBottom then maxChildBottom = childBottom end
			end

			if maxChildRight < self._layoutRight then
				self._layoutRight = maxChildRight     + self.insetRight
				innerRight        = self._layoutRight - self.insetRight
			end

			if maxChildBottom < self._layoutBottom then
				self._layoutBottom = maxChildBottom     + self.insetBottom
				innerBottom        = self._layoutBottom - self.insetBottom
			end
		else
			for _, child in ipairs(self.children) do
				child:calculateLayout(innerLeft, innerTop, innerRight, innerBottom)
			end
		end

		self:_calculateDerivedLayout()
	end

	while true do

		calculateLayoutFromChildren()

		local dirty = false
		for _, child in ipairs(self.children) do
			if child:_onParentLayoutCalculated(innerLeft, innerTop, innerRight, innerBottom) then
				dirty = true
			end
		end

		if not dirty then
			break
		end
	end

	--print(string.format("[EEex_Options_Private_LayoutInset:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutInset ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutFixed ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutFixed = {}
EEex_Options_Private_LayoutFixed.__index = EEex_Options_Private_LayoutFixed
setmetatable(EEex_Options_Private_LayoutFixed, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutFixed: "..tostring(EEex_Options_Private_LayoutFixed))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutFixed.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutFixed)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutFixed:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutFixed, "_init", self)
	-- Optional
	--   self.itemName
	--   self.width
	--   self.height
	-- Derived
	-- 	 self._curLayoutWidth
	--   self._curLayoutHeight
end

function EEex_Options_Private_LayoutFixed:_onInitLayout()
	self._curLayoutWidth  = self.width  or 0
	self._curLayoutHeight = self.height or 0
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutFixed:calculateLayout(left, top, right, bottom)

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + self._curLayoutWidth
	self._layoutBottom = self._layoutTop  + self._curLayoutHeight
	self:_calculateDerivedLayout()

	--print(string.format("[EEex_Options_Private_LayoutFixed:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutFixed:_onParentLayoutCalculated(left, top, right, bottom)
	if self.width  == nil then self._curLayoutWidth  = right  - self._layoutLeft end
	if self.height == nil then self._curLayoutHeight = bottom - self._layoutTop  end
end

function EEex_Options_Private_LayoutFixed:doLayout()
	if self.itemName == nil then return end
	Infinity_SetArea(self.itemName, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutFixed ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutTemplate  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutTemplate = {}
EEex_Options_Private_LayoutTemplate.__index = EEex_Options_Private_LayoutTemplate
setmetatable(EEex_Options_Private_LayoutTemplate, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutTemplate: "..tostring(EEex_Options_Private_LayoutTemplate))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutTemplate.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutTemplate)
	o:_init()
	if o.templateName == nil then EEex_Error("templateName required") end
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutTemplate:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutTemplate, "_init", self)
	if self.menuName == nil then EEex_Error("menuName required") end
	-- Optional
	--   self.width
	--   self.height
	--   self.templateName (only optional for subclasses)
	-- Derived
	-- 	 self._curLayoutWidth
	--   self._curLayoutHeight
end

function EEex_Options_Private_LayoutTemplate:_onInitLayout()
	self._curLayoutWidth  = self.width  or 0
	self._curLayoutHeight = self.height or 0
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutTemplate:calculateLayout(left, top, right, bottom)

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + self._curLayoutWidth
	self._layoutBottom = self._layoutTop  + self._curLayoutHeight
	self:_calculateDerivedLayout()

	--print(string.format("[EEex_Options_Private_LayoutTemplate:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutTemplate:_onParentLayoutCalculated(left, top, right, bottom)
	if self.width  == nil then self._curLayoutWidth  = right  - self._layoutLeft end
	if self.height == nil then self._curLayoutHeight = bottom - self._layoutTop  end
end

function EEex_Options_Private_LayoutTemplate:doLayout()
	EEex_Options_Private_CreateInstance(self.menuName, self.templateName, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutTemplate  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutDelayIcon ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutDelayIcon = {}
EEex_Options_Private_LayoutDelayIcon.__index = EEex_Options_Private_LayoutDelayIcon
setmetatable(EEex_Options_Private_LayoutDelayIcon, EEex_Options_Private_LayoutTemplate)
--print("EEex_Options_Private_LayoutDelayIcon: "..tostring(EEex_Options_Private_LayoutDelayIcon))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutDelayIcon.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutDelayIcon)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutDelayIcon:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutKeybindBackground, "_init", self)
	if self.displayEntry == nil then EEex_Error("displayEntry required") end
end

function EEex_Options_Private_LayoutDelayIcon:_onParentLayoutCalculated(left, top, right, bottom)
	local parentHeight = bottom - top
	self._curLayoutWidth = parentHeight
	self._curLayoutHeight = parentHeight
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutDelayIcon:doLayout()
	EEex_Options_Private_CreateDelayIcon(self.menuName, self.displayEntry, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
end

function EEex_Options_Private_TEMPLATE_DelayIcon_Enabled()
	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_DelayIcon"][instanceId]
	local option = instanceData.displayEntry._option
	return option:_getWorkingValue() ~= option:_get()
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutDelayIcon ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutExitButton  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutExitButton = {}
EEex_Options_Private_LayoutExitButton.__index = EEex_Options_Private_LayoutExitButton
setmetatable(EEex_Options_Private_LayoutExitButton, EEex_Options_Private_LayoutTemplate)
--print("EEex_Options_Private_LayoutExitButton: "..tostring(EEex_Options_Private_LayoutExitButton))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutExitButton.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutExitButton)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutExitButton:_onParentLayoutCalculated(left, top, right, bottom)

	local parentHeight = bottom - top
	local dirty = false

	if self._curLayoutWidth ~= parentHeight then
		self._curLayoutWidth = parentHeight
		dirty = true
	end

	if self._curLayoutHeight ~= parentHeight then
		self._curLayoutHeight = parentHeight
		dirty = true
	end

	return dirty
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutExitButton:doLayout()
	EEex_Options_Private_CreateExitButton(self.menuName, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
end

function EEex_Options_Private_TEMPLATE_ExitButton_Action()
	EEex_Options_Close()
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutExitButton  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutSeparator ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutSeparator = {}
EEex_Options_Private_LayoutSeparator.__index = EEex_Options_Private_LayoutSeparator
setmetatable(EEex_Options_Private_LayoutSeparator, EEex_Options_Private_LayoutTemplate)
--print("EEex_Options_Private_LayoutSeparator: "..tostring(EEex_Options_Private_LayoutSeparator))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutSeparator.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutSeparator)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutSeparator:_init()
	-- EEex_Options_Private_LayoutTemplate
	--   self.menuName
	--   Optional
	--     self.width
	--     self.height
	--   Derived
	-- 	   self._curLayoutWidth
	--     self._curLayoutHeight
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutSeparator, "_init", self)
	-- Optional
	--   self.color
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutSeparator:doLayout()
	EEex_Options_Private_CreateSeparator(self.menuName, self.color, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutSeparator ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutKeybindBackground ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutKeybindBackground = {}
EEex_Options_Private_LayoutKeybindBackground.__index = EEex_Options_Private_LayoutKeybindBackground
setmetatable(EEex_Options_Private_LayoutKeybindBackground, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutKeybindBackground: "..tostring(EEex_Options_Private_LayoutKeybindBackground))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutKeybindBackground.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutKeybindBackground)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutKeybindBackground:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutKeybindBackground, "_init", self)
	if self.menuName          == nil then EEex_Error("menuName required")         end
	if self.displayEntry      == nil then EEex_Error("displayEntry required")     end
	if self.startColor        == nil then self.startColor        = 0x406F6F70     end
	if self.endColor          == nil then self.endColor          = 0x40FFFFFF     end
	if self.pulseMilliseconds == nil then self.pulseMilliseconds = 500            end
	if self.layoutCallback    == nil then self.layoutCallback    = function() end end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutKeybindBackground:calculateLayout(left, top, right, bottom)
	local width, height = EEex_Options_Private_GetMaxTextBounds(styles.normal.font, styles.normal.point, 10)
	width  = width  + 3 + 3 -- Hardcoded pads (X-Option.menu)
	height = height + 3 + 3 -- Hardcoded pads (X-Option.menu)
	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + width
	self._layoutBottom = self._layoutTop  + height
	self:_calculateDerivedLayout()
end

function EEex_Options_Private_LayoutKeybindBackground:doLayout()

	local instanceData = EEex_Options_Private_CreateInstance(self.menuName, "EEex_Options_TEMPLATE_KeybindBackground", self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)

	instanceData.displayEntry = self.displayEntry
	instanceData.startColor = self.startColor
	instanceData.endColor = self.endColor
	instanceData.pulseMilliseconds = self.pulseMilliseconds
	instanceData.text = ""
	EEex_Options_Private_KeybindResetPulse(instanceData)

	local value = self.displayEntry:_getWorkingValue()
	EEex_Options_Private_KeybindUpdateText(instanceData, value[1], value[2])

	self.layoutCallback(instanceData)
end

function EEex_Options_Private_TEMPLATE_KeybindBackground_Action()
	EEex_Options_Private_KeybindPendingFocusedInstance = instanceId
end

function EEex_Options_Private_TEMPLATE_KeybindBackground_Fill()
	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][instanceId]
	return instanceData.currentColor
end

function EEex_Options_Private_TEMPLATE_KeybindBackground_Text()
	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][instanceId]
	return instanceData.text
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutKeybindBackground ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutKeybindButton ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutKeybindButton = {}
EEex_Options_Private_LayoutKeybindButton.__index = EEex_Options_Private_LayoutKeybindButton
setmetatable(EEex_Options_Private_LayoutKeybindButton, EEex_Options_Private_LayoutTemplate)
--print("EEex_Options_Private_LayoutKeybindButton: "..tostring(EEex_Options_Private_LayoutKeybindButton))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutKeybindButton.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutKeybindButton)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutKeybindButton:_init()
	-- EEex_Options_Private_LayoutTemplate
	--   self.menuName
	--   Optional
	--     self.width
	--     self.height
	--   Derived
	-- 	   self._curLayoutWidth
	--     self._curLayoutHeight
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutKeybindButton, "_init", self)
	if self.layoutCallback == nil then self.layoutCallback = function() end end
end

function EEex_Options_Private_LayoutKeybindButton:_onParentLayoutCalculated(left, top, right, bottom)
	local parentHeight = bottom - top
	self._curLayoutWidth = parentHeight
	self._curLayoutHeight = parentHeight
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutKeybindButton:doLayout()
	local instanceData = EEex_Options_Private_CreateInstance(self.menuName, "EEex_Options_TEMPLATE_KeybindButton", self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
	self.layoutCallback(instanceData)
end

function EEex_Options_Private_TEMPLATE_KeybindButton_Action()

	local buttonInstanceData     = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindButton"][instanceId]
	local backgroundInstanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][buttonInstanceData._pairedBackgroundInstance]

	if instanceId == EEex_Options_Private_KeybindFocusedInstance then
		EEex_Options_Private_KeybindEndFocus(backgroundInstanceData)
	else
		local displayEntry = backgroundInstanceData.displayEntry
		local default = displayEntry:_setWorkingValue(displayEntry:_getDefault())
		EEex_Options_Private_KeybindUpdateText(backgroundInstanceData, default[1], default[2])
	end
end

function EEex_Options_Private_TEMPLATE_KeybindButton_Tooltip()
	return instanceId == EEex_Options_Private_KeybindFocusedInstance and t("EEex_Options_TRANSLATION_Accept") or t("EEex_Options_TRANSLATION_Reset_to_Default")
end

function EEex_Options_Private_TEMPLATE_KeybindButton_Sequence()
	return instanceId == EEex_Options_Private_KeybindFocusedInstance and 1 or 0
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutKeybindButton ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutKeybindUpDownButton ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutKeybindUpDownButton = {}
EEex_Options_Private_LayoutKeybindUpDownButton.__index = EEex_Options_Private_LayoutKeybindUpDownButton
setmetatable(EEex_Options_Private_LayoutKeybindUpDownButton, EEex_Options_Private_LayoutTemplate)
--print("EEex_Options_Private_LayoutKeybindUpDownButton: "..tostring(EEex_Options_Private_LayoutKeybindUpDownButton))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutKeybindUpDownButton.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutKeybindUpDownButton)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutKeybindUpDownButton:_init()
	-- EEex_Options_Private_LayoutTemplate
	--   self.menuName
	--   Optional
	--     self.width
	--     self.height
	--   Derived
	-- 	   self._curLayoutWidth
	--     self._curLayoutHeight
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutKeybindUpDownButton, "_init", self)
	if self.layoutCallback == nil then self.layoutCallback = function() end end
end

function EEex_Options_Private_LayoutKeybindUpDownButton:_onParentLayoutCalculated(left, top, right, bottom)
	local parentHeight = bottom - top
	self._curLayoutWidth = parentHeight
	self._curLayoutHeight = parentHeight
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutKeybindUpDownButton:doLayout()
	local instanceData = EEex_Options_Private_CreateInstance(self.menuName, "EEex_Options_TEMPLATE_KeybindButtonUpDown", self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
	self.layoutCallback(instanceData)
end

function EEex_Options_Private_KeybindButtonUpDown_GetDisplayEntry()
	local buttonInstanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindButtonUpDown"][instanceId]
	local backgroundInstanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][buttonInstanceData._pairedBackgroundInstance]
	return backgroundInstanceData.displayEntry
end

function EEex_Options_Private_TEMPLATE_KeybindButtonUpDown_Action()
	local displayEntry = EEex_Options_Private_KeybindButtonUpDown_GetDisplayEntry()
	local existingVal = EEex.DeepCopy(displayEntry:_getWorkingValue()) -- Copy for subsequent modification
	local fireType = existingVal[3]
	existingVal[3] = not fireType
	displayEntry:_setWorkingValue(existingVal)
end

function EEex_Options_Private_TEMPLATE_KeybindButtonUpDown_Tooltip()
	local displayEntry = EEex_Options_Private_KeybindButtonUpDown_GetDisplayEntry()
	local fireType = displayEntry:_getWorkingValue()[3]
	local result = fireType and t("EEex_Options_TRANSLATION_On_Sequence_Released") or t("EEex_Options_TRANSLATION_On_Sequence_Pressed")
	return displayEntry._option.type.lockedFireType == nil and result or result.." "..t("EEex_Options_TRANSLATION_Locked")
end

function EEex_Options_Private_TEMPLATE_KeybindButtonUpDown_Sequence()
	local displayEntry = EEex_Options_Private_KeybindButtonUpDown_GetDisplayEntry()
	local fireType = displayEntry:_getWorkingValue()[3]
	local sequence = fireType and 2 or 4
	return displayEntry._option.type.lockedFireType == nil and sequence or sequence + 1
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutKeybindUpDownButton ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutToggle  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutToggle = {}
EEex_Options_Private_LayoutToggle.__index = EEex_Options_Private_LayoutToggle
setmetatable(EEex_Options_Private_LayoutToggle, EEex_Options_Private_LayoutTemplate)
--print("EEex_Options_Private_LayoutToggle: "..tostring(EEex_Options_Private_LayoutToggle))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutToggle.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutToggle)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutToggle:_init()

	-- EEex_Options_Private_LayoutTemplate
	--   self.menuName
	--   Optional
	--     self.width
	--     self.height
	--   Derived
	-- 	   self._curLayoutWidth
	--     self._curLayoutHeight
	if self.width  == nil then self.width  = 32 end
	if self.height == nil then self.height = 32 end
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutToggle, "_init", self)

	if self.displayEntry == nil then EEex_Error("displayEntry required") end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutToggle:doLayout()
	EEex_Options_Private_CreateToggle(self.menuName, self.displayEntry, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutToggle  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutEdit  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutEdit = {}
EEex_Options_Private_LayoutEdit.__index = EEex_Options_Private_LayoutEdit
setmetatable(EEex_Options_Private_LayoutEdit, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutEdit: "..tostring(EEex_Options_Private_LayoutEdit))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutEdit.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutEdit)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutEdit:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutEdit, "_init", self)
	if self.menuName     == nil then EEex_Error("menuName required")     end
	if self.font         == nil then EEex_Error("font required")         end
	if self.point        == nil then EEex_Error("point required")        end
	if self.displayEntry == nil then EEex_Error("displayEntry required") end
	if self.padLeft      == nil then self.padLeft   = 3                  end
	if self.padTop       == nil then self.padTop    = 3                  end
	if self.padRight     == nil then self.padRight  = 3                  end
	if self.padBottom    == nil then self.padBottom = 3                  end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutEdit:calculateLayout(left, top, right, bottom)
	local editWidth, editHeight = EEex_Options_Private_GetMaxTextBounds(self.font, self.point, self.displayEntry.widget.maxCharacters)
	editWidth  = editWidth  + self.padLeft + self.padRight
	editHeight = editHeight + self.padTop  + self.padBottom
	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + editWidth
	self._layoutBottom = self._layoutTop  + editHeight
	self:_calculateDerivedLayout()
end

function EEex_Options_Private_LayoutEdit:doLayout()

	local backgroundInstance = EEex_Options_Private_CreateInstance(self.menuName, "EEex_Options_TEMPLATE_EditBackground",
		self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)

	local editInstance = EEex_Options_Private_CreateEdit(self.menuName, self.displayEntry,
		self._layoutLeft   + self.padLeft,
		self._layoutTop    + self.padTop,
		self._layoutWidth  - self.padLeft - self.padRight,
		self._layoutHeight - self.padTop - self.padBottom)

	backgroundInstance._pairedEditLUD = EEex_UDToLightUD(editInstance.uiItem)
end

function EEex_Options_Private_TEMPLATE_EditBackground_Action()
	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_EditBackground"][instanceId]
	nameToItem["EEex_Options_Temp"] = instanceData._pairedEditLUD
	EEex_Options_Private_PendingEditFocus = "EEex_Options_Temp"
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutEdit  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutText  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutText = {}
EEex_Options_Private_LayoutText.__index = EEex_Options_Private_LayoutText
setmetatable(EEex_Options_Private_LayoutText, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutText: "..tostring(EEex_Options_Private_LayoutText))

EEex_Options_Private_LayoutText_VerticalAlign = {
	["TOP"]    = 0x00,
	["BOTTOM"] = 0x01,
	["CENTER"] = 0x02,
}

EEex_Options_Private_LayoutText_HorizontalAlign = {
	["LEFT"]   = 0x00,
	["RIGHT"]  = 0x01,
	["CENTER"] = 0x02,
}

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutText.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutText)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutText:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutText, "_init", self)
	if self.menuName        == nil then EEex_Error("menuName required")                                             end
	if self.font            == nil then EEex_Error("font required")                                                 end
	if self.point           == nil then EEex_Error("point required")                                                end
	if self.text            == nil then EEex_Error("text required")                                                 end
	if self.translate       == nil then self.translate = false                                                      end
	if self.horizontalAlign == nil then self.horizontalAlign = EEex_Options_Private_LayoutText_HorizontalAlign.LEFT end
	if self.verticalAlign   == nil then self.verticalAlign   = EEex_Options_Private_LayoutText_VerticalAlign.TOP    end
	-- Derived
	-- 	 self._curLayoutWidth
	--   self._curLayoutHeight
end

function EEex_Options_Private_LayoutText:_onInitLayout()
	self._curLayoutWidth  = nil
	self._curLayoutHeight = nil
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutText:calculateLayout(left, top, right, bottom)

	local width  = self._curLayoutWidth
	local height = self._curLayoutHeight

	if width == nil or height == nil then
		local text = self.translate and t(self.text) or self.text
		local textWidth, textHeight = EEex_Options_Private_GetTextWidthHeight(self.font, self.point, text)
		if width  == nil then self._curLayoutWidth  = textWidth;  width  = textWidth   end
		if height == nil then self._curLayoutHeight = textHeight; height = textHeight  end
	end

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + width
	self._layoutBottom = self._layoutTop  + height
	self:_calculateDerivedLayout()

	--print(string.format("[EEex_Options_Private_LayoutText:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutText:_onParentLayoutCalculated(left, top, right, bottom)

	local dirty = false

	if self.horizontalAlign ~= EEex_Options_Private_LayoutText_HorizontalAlign.LEFT then
		local newVal = right - self._layoutLeft
		if self._curLayoutWidth ~= newVal then
			self._curLayoutWidth = newVal
			dirty = true
		end
	end

	if self.verticalAlign ~= EEex_Options_Private_LayoutText_VerticalAlign.TOP then
		local newVal = bottom - self._layoutTop
		if self._curLayoutHeight ~= newVal then
			self._curLayoutHeight = newVal
			dirty = true
		end
	end

	return dirty
end

function EEex_Options_Private_LayoutText:doLayout()
	local text = self.translate and t(self.text) or self.text
	EEex_Options_Private_CreateText(self.menuName, text, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight, {
		["font"]            = self.font,
		["point"]           = self.point,
		["horizontalAlign"] = self.horizontalAlign,
		["verticalAlign"]   = self.verticalAlign,
	})
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutText  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutGrid  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutGrid = {}
EEex_Options_Private_LayoutGrid.__index = EEex_Options_Private_LayoutGrid
setmetatable(EEex_Options_Private_LayoutGrid, EEex_Options_Private_LayoutObject)
--print("EEex_Options_Private_LayoutGrid: "..tostring(EEex_Options_Private_LayoutGrid))

EEex_Options_Private_LayoutGrid_AlignFlags = {
	["HORIZONTAL_CENTER"] = 0x1,
	["HORIZONTAL_RIGHT"]  = 0x2,
	["VERTICAL_CENTER"]   = 0x4,
	["VERTICAL_BOTTOM"]   = 0x8,
}

EEex_Options_Private_LayoutGrid_Align = {
	["TOP_LEFT"]      = EEex_Flags({                                                                                                                          }),
	["TOP_CENTER"]    = EEex_Flags({                                                             EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_CENTER }),
	["TOP_RIGHT"]     = EEex_Flags({                                                             EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_RIGHT  }),
	["CENTER_RIGHT"]  = EEex_Flags({ EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_CENTER, EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_RIGHT  }),
	["BOTTOM_RIGHT"]  = EEex_Flags({ EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_BOTTOM, EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_RIGHT  }),
	["BOTTOM_CENTER"] = EEex_Flags({ EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_BOTTOM, EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_CENTER }),
	["BOTTOM_LEFT"]   = EEex_Flags({ EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_BOTTOM                                                               }),
	["CENTER_LEFT"]   = EEex_Flags({ EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_CENTER                                                               }),
	["CENTER_CENTER"] = EEex_Flags({ EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_CENTER, EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_CENTER }),
}

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutGrid.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutGrid)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutGrid:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutGrid, "_init", self)
	if self.uniformRowHeight == nil then self.uniformRowHeight = false end
	-- Derived
	self._columns             = {}
	self._columnHoleIndex     = 1
	self._rowsLayoutData      = {}
	self._rowsLayoutDataIndex = 1
end

function EEex_Options_Private_LayoutGrid:_onInitLayout()
	for _, column in ipairs(self._columns) do
		for _, cell in ipairs(column) do
			cell.layout:_onInitLayout()
		end
	end
end

function EEex_Options_Private_LayoutGrid:_getColumn(x)

	local columns = self._columns
	local column

	local columnHoleIndex = self._columnHoleIndex
	if x >= columnHoleIndex then
		for columnIndex = columnHoleIndex, x - 1 do
			columns[columnIndex] = { ["padLeft"] = 0, ["padRight"] = 0, ["rowHoleIndex"] = 1 }
		end
		column = { ["padLeft"] = 0, ["padRight"] = 0, ["rowHoleIndex"] = 1 }
		columns[x] = column
		self._columnHoleIndex = x + 1
	else
		column = columns[x]
	end

	return column
end

function EEex_Options_Private_LayoutGrid:_getOrCreateRowLayoutData(y)

	local rowsLayoutData = self._rowsLayoutData
	local rowsLayoutDataIndex = self._rowsLayoutDataIndex
	local rowLayoutData

	if y >= rowsLayoutDataIndex then
		for rowIndex = rowsLayoutDataIndex, y - 1 do
			rowsLayoutData[rowIndex] = { ["padTop"] = 0, ["padBottom"] = 0 }
		end
		rowLayoutData = { ["padTop"] = 0, ["padBottom"] = 0 }
		rowsLayoutData[y] = rowLayoutData
		self._rowsLayoutDataIndex = y + 1
	else
		rowLayoutData = rowsLayoutData[y]
	end

	return rowLayoutData
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutGrid:calculateLayout(left, top, right, bottom)

	local uniformRowHeight = self.uniformRowHeight
	local rowsLayoutData   = self._rowsLayoutData

	local localColumnsLayoutData = {}
	local localRowsLayoutData    = {}

	local totalColumnWidth = 0
	local totalRowHeight   = 0

	local maxCellHeight = 0

	-- Dummy layout children to calculate column / row dimensions
	for columnIndex, column in ipairs(self._columns) do

		local maxCellRight = left

		for rowIndex, cell in ipairs(column) do

			local cellLayout = cell.layout
			cellLayout:calculateLayout(left, top, right, bottom) -- Dummy layout

			local cellLayoutRight = cellLayout:getLayoutRight()
			if cellLayoutRight > maxCellRight then maxCellRight = cellLayoutRight end

			local rowLayoutData = EEex_Utility_GetOrCreateTable(localRowsLayoutData, rowIndex, function(t) t.maxCellHeight = 0 end)
			local cellHeight = cellLayout:getLayoutBottom() - top
			if cellHeight > rowLayoutData.maxCellHeight then rowLayoutData.maxCellHeight = cellHeight end
			if cellHeight > maxCellHeight               then maxCellHeight               = cellHeight end
		end

		local maxCellWidth = maxCellRight - left
		totalColumnWidth = totalColumnWidth + column.padLeft + maxCellWidth + column.padRight

		localColumnsLayoutData[columnIndex] = {
			["maxCellWidth"] = maxCellWidth,
		}
	end

	for i, localRowLayoutData in ipairs(localRowsLayoutData) do
		local rowLayoutData = rowsLayoutData[i]
		local effectiveCellHeight = uniformRowHeight and maxCellHeight or localRowLayoutData.maxCellHeight
		totalRowHeight = totalRowHeight + rowLayoutData.padTop + effectiveCellHeight + rowLayoutData.padBottom
	end

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + totalColumnWidth
	self._layoutBottom = self._layoutTop  + totalRowHeight
	self:_calculateDerivedLayout()

	-- Real layout children
	local curLeft = left

	for columnIndex, column in ipairs(self._columns) do

		local columnLayoutData = localColumnsLayoutData[columnIndex]
		local maxCellWidth = columnLayoutData.maxCellWidth

		curLeft = curLeft + column.padLeft
		local curTop = top
		local curRight = curLeft + maxCellWidth

		for rowIndex, cell in ipairs(column) do

			local cellLayout = cell.layout

			local rowLayoutData = rowsLayoutData[rowIndex]
			local localRowLayoutData = localRowsLayoutData[rowIndex]
			local maxCellHeight = uniformRowHeight and maxCellHeight or localRowLayoutData.maxCellHeight

			curTop = curTop + rowLayoutData.padTop
			local curBottom = curTop + maxCellHeight
			cellLayout:calculateLayout(curLeft, curTop, curRight, curBottom)
			cellLayout:_onParentLayoutCalculated(curLeft, curTop, curRight, curBottom) -- Only allow element to access the cell
			-- TODO: Re-layout child

			if EEex_IsMaskSet(cell.align, EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_CENTER) then
				local centerOffset = (maxCellHeight - cellLayout:getLayoutHeight()) / 2
				cellLayout:calculateLayout(curLeft, curTop + centerOffset, curRight, curBottom + centerOffset)
			elseif EEex_IsMaskSet(cell.align, EEex_Options_Private_LayoutGrid_AlignFlags.VERTICAL_BOTTOM) then
				local bottomOffset = maxCellHeight - cellLayout:getLayoutHeight()
				cellLayout:calculateLayout(curLeft, curTop + bottomOffset, curRight, curBottom + bottomOffset)
			end

			if EEex_IsMaskSet(cell.align, EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_CENTER) then
				local centerOffset = (maxCellWidth - cellLayout:getLayoutWidth()) / 2
				cellLayout:calculateLayout(curLeft + centerOffset, curTop, curRight + centerOffset, curBottom)
			elseif EEex_IsMaskSet(cell.align, EEex_Options_Private_LayoutGrid_AlignFlags.HORIZONTAL_RIGHT) then
				local rightOffset = maxCellWidth - cellLayout:getLayoutWidth()
				cellLayout:calculateLayout(curLeft + rightOffset, curTop, curRight + rightOffset, curBottom)
			end

			curTop = curTop + maxCellHeight + rowLayoutData.padBottom
		end

		curLeft = curLeft + maxCellWidth + column.padRight
	end

	--print(string.format("[EEex_Options_Private_LayoutGrid:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutGrid:doLayout()
	for _, column in ipairs(self._columns) do
		for _, cell in ipairs(column) do
			cell.layout:doLayout()
		end
	end
end

function EEex_Options_Private_LayoutGrid:setCell(x, y, layoutObject, align)

	if align == nil then align = EEex_Options_Private_LayoutGrid_Align.TOP_LEFT end

	local column = self:_getColumn(x)

	local rowHoleIndex = column.rowHoleIndex
	if y >= rowHoleIndex then
		for rowIndex = rowHoleIndex, y - 1 do
			column[rowIndex] = { ["align"] = align, ["layout"] = EEex_Options_Private_LayoutFixed.new({ ["width"] = 0, ["height"] = 0 }) }
		end
		column.rowHoleIndex = y + 1
	end

	column[y] = { ["align"] = align, ["layout"] = layoutObject }

	self:_getOrCreateRowLayoutData(y) -- To generate rowsLayoutData entry
	return self
end

function EEex_Options_Private_LayoutGrid:setColumnPad(x, padLeft, padRight)
	local column = self:_getColumn(x)
	if padLeft  ~= nil then column.padLeft  = padLeft  end
	if padRight ~= nil then column.padRight = padRight end
end

function EEex_Options_Private_LayoutGrid:setRowPad(y, padTop, padBottom)
	local rowLayoutData = self:_getOrCreateRowLayoutData(y)
	if padTop    ~= nil then rowLayoutData.padTop    = padTop    end
	if padBottom ~= nil then rowLayoutData.padBottom = padBottom end
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutGrid  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LayoutOptionsPanel  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LayoutOptionsPanel = {}
EEex_Options_Private_LayoutOptionsPanel.__index = EEex_Options_Private_LayoutOptionsPanel
setmetatable(EEex_Options_Private_LayoutOptionsPanel, EEex_Options_Private_LayoutGrid)
--print("EEex_Options_Private_LayoutOptionsPanel: "..tostring(EEex_Options_Private_LayoutOptionsPanel))

--////////////
--// Static //
--////////////

EEex_Options_Private_LayoutOptionsPanel.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Private_LayoutOptionsPanel)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LayoutOptionsPanel:_init()

	-- EEex_Options_Private_LayoutGrid
	--   self.uniformRowHeight
	if self.uniformRowHeight == nil then self.uniformRowHeight = true end
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutOptionsPanel, "_init", self)

	if self.menuName       == nil then EEex_Error("menuName required")        end
	if self.displayEntries == nil then EEex_Error("displayEntries required")  end
	if self.columnGap      == nil then self.columnGap   = 20                  end
	if self.layerIndent    == nil then self.layerIndent = 20                  end
	if self.rowGap         == nil then self.rowGap      = 5                   end
	if self.widgetGap      == nil then self.widgetGap   = 10                  end

	self:_mapOptions()
	self:_buildLayout()
end

function EEex_Options_Private_LayoutOptionsPanel:_mapOptions()

	local handleGroup
	handleGroup = function(group)

		for _, displayEntry in ipairs(group) do

			local optionID = displayEntry.optionID
			local option = EEex_Options_Get(optionID)

			if option == nil then
				EEex_Error(string.format("option with id \"%s\" not found", optionID))
			end

			EEex_Options_Private_IdToDisplayEntry[optionID] = displayEntry
			displayEntry._option = option
			displayEntry.widget:_onMap(displayEntry, optionID)

			if displayEntry.subOptions then
				handleGroup(displayEntry.subOptions)
			end
		end
	end

	for _, columnGroup in ipairs(self.displayEntries) do
		handleGroup(columnGroup)
	end
end

function EEex_Options_Private_LayoutOptionsPanel:_buildLayout()

	local normalStyle = styles.normal
	local normalFont  = normalStyle.font
	local normalPoint = normalStyle.point

	local globalColumnOffset = 0
	local maxRowIndex        = 0

	for columnGroupIndex, columnGroup in ipairs(self.displayEntries) do

		local curColumnOffset = globalColumnOffset
		local rowIndex        = 1

		local handleGroup
		handleGroup = function(group, layer)

			for _, displayEntry in ipairs(group) do

				if rowIndex > maxRowIndex then
					maxRowIndex = rowIndex
				end

				local xOffset = layer * self.layerIndent

				local optionLabel = EEex_Options_Private_LayoutText.new({
					["menuName"]  = self.menuName,
					["font"]      = normalFont,
					["point"]     = normalPoint,
					["text"]      = displayEntry.label,
					["translate"] = true,
				})
				:inset({ ["insetLeft"] = xOffset })

				local labelColumnIndex  = curColumnOffset + columnGroupIndex * 2 - 1
				local widgetColumnIndex = labelColumnIndex + 1

				if columnGroupIndex ~= 1 then
					self:setColumnPad(labelColumnIndex, self.columnGap)
				end

				self:setCell(labelColumnIndex, rowIndex, optionLabel, EEex_Options_Private_LayoutGrid_Align.CENTER_LEFT)
				self:setColumnPad(widgetColumnIndex, self.widgetGap)

				local widgetLayout = displayEntry.widget:_buildLayout(displayEntry, self.menuName)

				if widgetLayout ~= nil then

					self:setCell(widgetColumnIndex, rowIndex, widgetLayout, EEex_Options_Private_LayoutGrid_Align.CENTER_LEFT)

					if displayEntry._option.requiresRestart then

						local requiresRestartLayout = EEex_Options_Private_LayoutDelayIcon.new({
							["menuName"]     = self.menuName,
							["displayEntry"] = displayEntry,
						})

						local requiresRestartColumnIndex = widgetColumnIndex + 1
						self:setCell(requiresRestartColumnIndex, rowIndex, requiresRestartLayout, EEex_Options_Private_LayoutGrid_Align.CENTER_LEFT)
						self:setColumnPad(requiresRestartColumnIndex, self.widgetGap)
						globalColumnOffset = globalColumnOffset + 1
					end
				end

				rowIndex = rowIndex + 1

				if displayEntry.subOptions then
					handleGroup(displayEntry.subOptions, layer + 1)
				end
			end
		end
		handleGroup(columnGroup, 0)
	end

	for rowIndex = 2, maxRowIndex do
		self:setRowPad(rowIndex, self.rowGap)
	end
end

function EEex_Options_Private_LayoutOptionsPanel:_onShowBeforeLayout()

	local handleGroup
	handleGroup = function(group)

		for _, displayEntry in ipairs(group) do

			displayEntry.widget:_onShowBeforeLayout(displayEntry)

			if displayEntry.subOptions then
				handleGroup(displayEntry.subOptions)
			end
		end
	end

	for _, columnGroup in ipairs(self.displayEntries) do
		handleGroup(columnGroup)
	end
end

function EEex_Options_Private_LayoutOptionsPanel:_onShowAfterLayout()

	local handleGroup
	handleGroup = function(group)

		for _, displayEntry in ipairs(group) do

			displayEntry.widget:_onShowAfterLayout(displayEntry)

			if displayEntry.subOptions then
				handleGroup(displayEntry.subOptions)
			end
		end
	end

	for _, columnGroup in ipairs(self.displayEntries) do
		handleGroup(columnGroup)
	end
end

function EEex_Options_Private_LayoutOptionsPanel:_writeNewValues()

	local handleGroup
	handleGroup = function(group)

		for _, displayEntry in ipairs(group) do

			if not displayEntry.widget.deferTo then
				displayEntry:_set(displayEntry:_getWorkingValue())
			end

			if displayEntry.subOptions then
				handleGroup(displayEntry.subOptions)
			end
		end
	end

	for _, columnGroup in ipairs(self.displayEntries) do
		handleGroup(columnGroup)
	end
end

--////////////////////////////////
--// EEex_Options_TEMPLATE_Edit //
--////////////////////////////////

function EEex_Options_Private_TEMPLATE_Edit_Action()

	if letter_pressed == nil then
		return 1 -- Allow
	end

	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Edit"][instanceId]
	local displayEntry = instanceData.displayEntry

	if displayEntry.widget.number then
		if letter_pressed ~= "-" and letter_pressed ~= "." and tonumber(letter_pressed) == nil then
			return 0 -- Block
		end
	end

	return 1 -- Allow
end

--/////////////////////////////////////
--// EEex_Options_TEMPLATE_Separator //
--/////////////////////////////////////

function EEex_Options_Private_TEMPLATE_Separator_Fill()
	return EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Separator"][instanceId].color
end

--////////////////////////////////
--// EEex_Options_TEMPLATE_Text //
--////////////////////////////////

function EEex_Options_Private_TEMPLATE_Text_Text()
	return EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Text"][instanceId].text
end

--//////////////////////////////////
--// EEex_Options_TEMPLATE_Toggle //
--//////////////////////////////////

function EEex_Options_Private_ToggleAction(displayEntry)

	local widget = displayEntry.widget
	local newToggleState = not widget.toggleState

	if not newToggleState and widget.disallowToggleOff then
		return
	end

	widget.toggleState = newToggleState

	local forceOthers = widget.forceOthers

	if forceOthers then

		for _, forceEntry in ipairs(forceOthers[widget.toggleState] or {}) do

			local forceDisplayEntry = EEex_Options_Private_IdToDisplayEntry[forceEntry[1]]
			local forceWidget = forceDisplayEntry.widget
			local newForceToggleState = forceEntry[2]

			if type(newForceToggleState) == "function" then
				newForceToggleState = newForceToggleState()
			end

			if newForceToggleState ~= nil then

				forceWidget.toggleState = newForceToggleState

				if newForceToggleState or not forceWidget.disallowToggleOff then
					local mainForceDisplayEntry = forceWidget.deferTo and EEex_Options_Private_IdToDisplayEntry[forceWidget.deferTo] or forceDisplayEntry
					local newForceVal = newForceToggleState and mainForceDisplayEntry.widget.toggleValue or 0
					mainForceDisplayEntry:_setWorkingValue(newForceVal)
				end
			end
		end
	end

	local mainDisplayEntry = widget.deferTo and EEex_Options_Private_IdToDisplayEntry[widget.deferTo] or displayEntry
	local newVal = newToggleState and mainDisplayEntry.widget.toggleValue or 0
	mainDisplayEntry:_setWorkingValue(newVal)
end

function EEex_Options_Private_TEMPLATE_Toggle_Action()

	local displayEntry = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Toggle"][instanceId].displayEntry

	local doToggle = function()
		EEex_Options_Private_ToggleAction(displayEntry)
	end

	local toggleWarning = displayEntry.widget.toggleWarning
	if toggleWarning == nil or not toggleWarning(doToggle) then
		doToggle()
	end
end

function EEex_Options_Private_TEMPLATE_Toggle_Frame()
	local displayEntry = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Toggle"][instanceId].displayEntry
	return displayEntry.widget.toggleState and 2 or 0
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutOptionsPanel:doLayout()
	EEex_Menu_DestroyAllTemplates(self.menuName)
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutOptionsPanel, "doLayout", self)
end

function EEex_Options_Private_LayoutOptionsPanel:showBeforeLayout()
	self:_onShowBeforeLayout()
end

function EEex_Options_Private_LayoutOptionsPanel:showAfterLayout()
	self:_onShowAfterLayout()
	Infinity_PushMenu(self.menuName)
end

function EEex_Options_Private_LayoutOptionsPanel:hide()
	self:_writeNewValues()
	Infinity_PopMenu(self.menuName)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutOptionsPanel  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Option  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Option = {}
EEex_Options_Option.__index = EEex_Options_Option
--setmetatable(EEex_Options_Option, )
--print("EEex_Options_Option: "..tostring(EEex_Options_Option))

--////////////
--// Static //
--////////////

EEex_Options_Option.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_Option)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Option:_init()
	EEex_Utility_CallSuper(EEex_Options_Option, "_init", self)
	if self.id              == nil then EEex_Error("id required")                                 end
	if self.default         == nil then EEex_Error("default required")                            end
	if self.accessor        == nil then self.accessor        = EEex_Options_PrivateAccessor.new() end
	if self.requiresRestart == nil then self.requiresRestart = false                              end
	-- Optional
	--   self.storage
end

function EEex_Options_Option:_canReadEarly()
	local storage = self.storage
	if storage == nil then return false end
	return storage:canReadEarly()
end

function EEex_Options_Option:_get()
	return self.accessor:get(self)
end

function EEex_Options_Option:_getDefault()
	return self.default
end

function EEex_Options_Option:_getWorkingValue()
	return self._workingValue
end

function EEex_Options_Option:_read()
	local storage = self.storage
	if storage == nil then return end
	return storage:read(self)
end

function EEex_Options_Option:_set(newValue, fromRead, needCopy)

	if not fromRead and self.requiresRestart then
		newValue = self:_setWorkingValue(newValue, needCopy)
		self:_write(newValue)
		return newValue
	end

	local oldValue = self:_get()
	newValue = self.accessor:set(self, newValue, needCopy)
	self._workingValue = newValue

	if not fromRead then
		self:_write(newValue)
	end

	if self.onChange ~= nil and newValue ~= oldValue then
		self:onChange()
	end

	return newValue
end

function EEex_Options_Option:_setWorkingValue(newValue, needCopy)
	newValue = self.accessor:validate(self, newValue, needCopy)
	self._workingValue = newValue
	return newValue
end

function EEex_Options_Option:_write(newValue)
	local storage = self.storage
	if storage == nil then return end
	storage:write(self, newValue)
end

------------
-- Public --
------------

function EEex_Options_Option:getDefault()
	-- Copy so the user can't modify internal state via a reference
	return EEex.DeepCopy(self:_getDefault())
end

function EEex_Options_Option:get()
	-- Copy so the user can't modify internal state via a reference
	return EEex.DeepCopy(self:_get())
end

function EEex_Options_Option:set(newValue)
	if newValue == nil then return self:_set(self:_getDefault()) end
	-- Copy `newValue` if it is used so the user can't modify it via a reference
	return self:_set(newValue, false, true)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Option  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_DisplayEntry  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_DisplayEntry = {}
EEex_Options_DisplayEntry.__index = EEex_Options_DisplayEntry
--setmetatable(EEex_Options_DisplayEntry, )
--print("EEex_Options_DisplayEntry: "..tostring(EEex_Options_DisplayEntry))

--////////////
--// Static //
--////////////

EEex_Options_DisplayEntry.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_DisplayEntry)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_DisplayEntry:_init()
	EEex_Utility_CallSuper(EEex_Options_DisplayEntry, "_init", self)
	if self.label    == nil then EEex_Error("label required")    end
	if self.optionID == nil then EEex_Error("optionID required") end
	if self.widget   == nil then EEex_Error("widget required")   end
	-- Derived
	--   self._option
end

function EEex_Options_DisplayEntry:_getDefault()
	return self._option:_getDefault()
end

function EEex_Options_DisplayEntry:_getWorkingValue()
	return self._option:_getWorkingValue()
end

function EEex_Options_DisplayEntry:_set(newValue, fromRead, needCopy)
	return self._option:_set(newValue, fromRead, needCopy)
end

function EEex_Options_DisplayEntry:_setWorkingValue(newValue, needCopy)
	return self._option:_setWorkingValue(newValue, needCopy)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_DisplayEntry  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Accessor  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Accessor = {}
EEex_Options_Accessor.__index = EEex_Options_Accessor
--setmetatable(EEex_Options_Accessor, )
--print("EEex_Options_Accessor: "..tostring(EEex_Options_Accessor))

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Accessor:_init()
	-- Empty stub
end

------------
-- Public --
------------

function EEex_Options_Accessor:validate(option, newValue, needCopy)
	return needCopy and EEex.DeepCopy(newValue) or newValue
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Accessor  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_PrivateAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_PrivateAccessor = {}
EEex_Options_PrivateAccessor.__index = EEex_Options_PrivateAccessor
setmetatable(EEex_Options_PrivateAccessor, EEex_Options_Accessor)
--print("EEex_Options_PrivateAccessor: "..tostring(EEex_Options_PrivateAccessor))

--////////////
--// Static //
--////////////

EEex_Options_PrivateAccessor.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_PrivateAccessor)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_PrivateAccessor:get(option)
	return self._value
end

function EEex_Options_PrivateAccessor:set(option, newValue, needCopy)
	self._value = newValue
	return newValue
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_PrivateAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_GlobalAccessor  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_GlobalAccessor = {}
EEex_Options_GlobalAccessor.__index = EEex_Options_GlobalAccessor
setmetatable(EEex_Options_GlobalAccessor, EEex_Options_Accessor)
--print("EEex_Options_GlobalAccessor: "..tostring(EEex_Options_GlobalAccessor))

--////////////
--// Static //
--////////////

EEex_Options_GlobalAccessor.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_GlobalAccessor)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_GlobalAccessor:_init()
	EEex_Utility_CallSuper(EEex_Options_GlobalAccessor, "_init", self)
	if self.name == nil then EEex_Error("name required") end
end

------------
-- Public --
------------

function EEex_Options_GlobalAccessor:get(option)
	return _G[self.name]
end

function EEex_Options_GlobalAccessor:set(option, newValue, needCopy)
	_G[self.name] = newValue
	return newValue
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_GlobalAccessor  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_KeybindAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_KeybindAccessor = {}
EEex_Options_KeybindAccessor.__index = EEex_Options_KeybindAccessor
setmetatable(EEex_Options_KeybindAccessor, EEex_Options_Accessor)
--print("EEex_Options_KeybindAccessor: "..tostring(EEex_Options_KeybindAccessor))

--////////////
--// Static //
--////////////

EEex_Options_KeybindAccessor.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_KeybindAccessor)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_KeybindAccessor:_init()
	EEex_Utility_CallSuper(EEex_Options_KeybindAccessor, "_init", self)
	if self.keybindID == nil then EEex_Error("keybindID required") end
end

------------
-- Public --
------------

function EEex_Options_KeybindAccessor:validate(option, newValue, needCopy)
	local lockedFireType = option.type.lockedFireType
	if lockedFireType ~= nil and newValue[3] ~= lockedFireType then
		newValue = EEex.DeepCopy(newValue) -- Copy for subsequent modification
		newValue[3] = lockedFireType
		return newValue
	end
	return EEex_Utility_CallSuper(EEex_Options_KeybindAccessor, "validate", self, option, newValue, needCopy)
end

function EEex_Options_KeybindAccessor:get(option)
	local modifierKeys, keys, fireType = EEex_Keybinds_GetBinding(self.keybindID)
	return { modifierKeys, keys, fireType }
end

function EEex_Options_KeybindAccessor:set(option, newValue, needCopy)
	newValue = self:validate(option, newValue, needCopy)
	EEex_Keybinds_SetBinding(self.keybindID, newValue[1], newValue[2], newValue[3], option.type.callback)
	return newValue
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_KeybindAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_ClampedAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_ClampedAccessor = {}
EEex_Options_ClampedAccessor.__index = EEex_Options_ClampedAccessor
setmetatable(EEex_Options_ClampedAccessor, EEex_Options_Accessor)
--print("EEex_Options_ClampedAccessor: "..tostring(EEex_Options_ClampedAccessor))

--////////////
--// Static //
--////////////

EEex_Options_ClampedAccessor.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_ClampedAccessor)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_ClampedAccessor:_init()
	EEex_Utility_CallSuper(EEex_Options_ClampedAccessor, "_init", self)
	if self.accessor == nil then self.accessor = EEex_Options_PrivateAccessor.new() end
	if self.floating == nil then self.floating = false                              end
	-- Optional
	--   self.min
	--   self.max
end

------------
-- Public --
------------

function EEex_Options_ClampedAccessor:validate(option, newValue, needCopy)

	if not self.floating then
		newValue = math.floor(newValue)
	end

	local min = self.min
	if min ~= nil and newValue < min then
		newValue = min
	end

	local max = self.max
	if max ~= nil and newValue > max then
		newValue = max
	end

	return newValue
end

function EEex_Options_ClampedAccessor:get(option)
	return self.accessor:get()
end

function EEex_Options_ClampedAccessor:set(option, newValue, needCopy)
	newValue = self:validate(option, newValue, needCopy)
	return self.accessor:set(option, newValue)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_ClampedAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_Storage ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_Storage = {}
EEex_Options_Private_Storage.__index = EEex_Options_Private_Storage
--setmetatable(EEex_Options_Private_Storage, )
--print("EEex_Options_Private_Storage: "..tostring(EEex_Options_Private_Storage))

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_Private_Storage:canReadEarly()
	return false
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_Storage ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_LuaStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_LuaStorage = {}
EEex_Options_Private_LuaStorage.__index = EEex_Options_Private_LuaStorage
setmetatable(EEex_Options_Private_LuaStorage, EEex_Options_Private_Storage)
--print("EEex_Options_Private_LuaStorage: "..tostring(EEex_Options_Private_LuaStorage))

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_LuaStorage:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_LuaStorage, "_init", self)
	if self.section == nil then EEex_Error("section required") end
	if self.key     == nil then EEex_Error("key required")     end
end

function EEex_Options_Private_LuaStorage:_escape(str)
	str = tostring(str)
	str = str:gsub("%%", "%%%%")
	return str:gsub("[\\]", function(char)
		return "%"..string.byte(char)
	end)
end

function EEex_Options_Private_LuaStorage:_unescape(str)
	str = str:gsub("(%%*)%%(%d+)", function(extraEscapeChars, escapedCode)
		if #extraEscapeChars % 2 ~= 0 then return end
		return extraEscapeChars..string.char(escapedCode)
	end)
	return str:gsub("%%%%", "%%")
end

------------
-- Public --
------------

function EEex_Options_Private_LuaStorage:read(option)
	local str = Infinity_GetINIString(self.section, self.key, "X-DEFAULT")
	return str ~= "X-DEFAULT" and self:_unescape(str) or nil
end

function EEex_Options_Private_LuaStorage:write(option, value)
	Infinity_SetINIValue(self.section, self.key, self:_escape(value))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LuaStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_KeybindLuaStorage ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_KeybindLuaStorage = {}
EEex_Options_KeybindLuaStorage.__index = EEex_Options_KeybindLuaStorage
setmetatable(EEex_Options_KeybindLuaStorage, EEex_Options_Private_LuaStorage)
--print("EEex_Options_KeybindLuaStorage: "..tostring(EEex_Options_KeybindLuaStorage))

--////////////
--// Static //
--////////////

EEex_Options_KeybindLuaStorage.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_KeybindLuaStorage)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_KeybindLuaStorage:read(option)
	local str = EEex_Utility_CallSuper(EEex_Options_KeybindLuaStorage, "read", self, option)
	return str ~= nil and EEex_Options_UnmarshalKeybind(str) or option:_getDefault()
end

function EEex_Options_KeybindLuaStorage:write(option, value)
	local marshalled = EEex_Options_MarshalKeybind(value[1], value[2], value[3])
	EEex_Utility_CallSuper(EEex_Options_KeybindLuaStorage, "write", self, option, marshalled)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_KeybindLuaStorage ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_NumberLuaStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_NumberLuaStorage = {}
EEex_Options_NumberLuaStorage.__index = EEex_Options_NumberLuaStorage
setmetatable(EEex_Options_NumberLuaStorage, EEex_Options_Private_LuaStorage)
--print("EEex_Options_NumberLuaStorage: "..tostring(EEex_Options_NumberLuaStorage))

--////////////
--// Static //
--////////////

EEex_Options_NumberLuaStorage.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_NumberLuaStorage)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_NumberLuaStorage:read(option)
	local strVal = EEex_Utility_CallSuper(EEex_Options_NumberLuaStorage, "read", self, option)
	return tonumber(strVal) or option:_getDefault()
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_NumberLuaStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_StringLuaStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_StringLuaStorage = {}
EEex_Options_StringLuaStorage.__index = EEex_Options_StringLuaStorage
setmetatable(EEex_Options_StringLuaStorage, EEex_Options_Private_LuaStorage)
--print("EEex_Options_StringLuaStorage: "..tostring(EEex_Options_StringLuaStorage))

--////////////
--// Static //
--////////////

EEex_Options_StringLuaStorage.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_StringLuaStorage)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_StringLuaStorage:read(option)
	local str = EEex_Utility_CallSuper(EEex_Options_StringLuaStorage, "read", self, option)
	return str or option:_getDefault()
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_StringLuaStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_INIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_INIStorage = {}
EEex_Options_Private_INIStorage.__index = EEex_Options_Private_INIStorage
setmetatable(EEex_Options_Private_INIStorage, EEex_Options_Private_Storage)
--print("EEex_Options_Private_INIStorage: "..tostring(EEex_Options_Private_INIStorage))

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_INIStorage:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_INIStorage, "_init", self)
	if self.path    == nil then EEex_Error("path required")    end
	if self.section == nil then EEex_Error("section required") end
	if self.key     == nil then EEex_Error("key required")     end
end

------------
-- Public --
------------

function EEex_Options_Private_INIStorage:canReadEarly()
	return true
end

function EEex_Options_Private_INIStorage:write(option, value)
	EEex.SetINIString(self.path, self.section, self.key, tostring(value))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_INIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_NumberINIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_NumberINIStorage = {}
EEex_Options_NumberINIStorage.__index = EEex_Options_NumberINIStorage
setmetatable(EEex_Options_NumberINIStorage, EEex_Options_Private_INIStorage)
--print("EEex_Options_NumberINIStorage: "..tostring(EEex_Options_NumberINIStorage))

--////////////
--// Static //
--////////////

EEex_Options_NumberINIStorage.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_NumberINIStorage)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_NumberINIStorage:read(option)
	local strVal = EEex.GetINIString(self.path, self.section, self.key, "X-DEFAULT")
	local intVal = strVal ~= "X-DEFAULT" and tonumber(strVal) or nil
	return intVal or option:_getDefault()
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_NumberINIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_StringINIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_StringINIStorage = {}
EEex_Options_StringINIStorage.__index = EEex_Options_StringINIStorage
setmetatable(EEex_Options_StringINIStorage, EEex_Options_Private_INIStorage)
--print("EEex_Options_StringINIStorage: "..tostring(EEex_Options_StringINIStorage))

--////////////
--// Static //
--////////////

EEex_Options_StringINIStorage.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_StringINIStorage)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_StringINIStorage:read(option)
	return EEex.GetINIString(self.path, self.section, self.key, option:_getDefault())
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_StringINIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Type  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Type = {}
EEex_Options_Type.__index = EEex_Options_Type
--setmetatable(EEex_Options_Type, )
--print("EEex_Options_Type: "..tostring(EEex_Options_Type))

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Type:_init()
	-- Empty stub
end

--=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Type  ==
--=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_EditType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_EditType = {}
EEex_Options_EditType.__index = EEex_Options_EditType
setmetatable(EEex_Options_EditType, EEex_Options_Type)
--print("EEex_Options_EditType: "..tostring(EEex_Options_EditType))

--////////////
--// Static //
--////////////

EEex_Options_EditType.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_EditType)
	o:_init()
	return o
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_EditType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_KeybindType ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_KeybindType = {}
EEex_Options_KeybindType.__index = EEex_Options_KeybindType
setmetatable(EEex_Options_KeybindType, EEex_Options_Type)
--print("EEex_Options_KeybindType: "..tostring(EEex_Options_KeybindType))

--////////////
--// Static //
--////////////

EEex_Options_KeybindType.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_KeybindType)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_KeybindType:_init()
	EEex_Utility_CallSuper(EEex_Options_KeybindType, "_init", self)
	if self.callback == nil then EEex_Error("callback required") end
	-- Optional
	--   self.lockedFireType
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_KeybindType ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_ToggleType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_ToggleType = {}
EEex_Options_ToggleType.__index = EEex_Options_ToggleType
setmetatable(EEex_Options_ToggleType, EEex_Options_Type)
--print("EEex_Options_ToggleType: "..tostring(EEex_Options_ToggleType))

--////////////
--// Static //
--////////////

EEex_Options_ToggleType.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_ToggleType)
	o:_init()
	return o
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_ToggleType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Widget  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Widget = {}
EEex_Options_Widget.__index = EEex_Options_Widget
--setmetatable(EEex_Options_Widget, )
--print("EEex_Options_Widget: "..tostring(EEex_Options_Widget))

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Widget:_init()
	-- Empty stub
end

function EEex_Options_Widget:_onMap(displayEntry, optionName)
	-- Empty stub
end

function EEex_Options_Widget:_buildLayout(displayEntry, menuName)
	-- Empty stub
end

function EEex_Options_Widget:_onShowBeforeLayout(displayEntry)
	-- Empty stub
end

function EEex_Options_Widget:_onShowAfterLayout(displayEntry)
	-- Empty stub
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Widget  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_EditWidget  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_EditWidget = {}
EEex_Options_EditWidget.__index = EEex_Options_EditWidget
setmetatable(EEex_Options_EditWidget, EEex_Options_Widget)
--print("EEex_Options_EditWidget: "..tostring(EEex_Options_EditWidget))

--////////////
--// Static //
--////////////

EEex_Options_EditWidget.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_EditWidget)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_EditWidget:_init()
	EEex_Utility_CallSuper(EEex_Options_EditWidget, "_init", self)
	if self.maxCharacters == nil then EEex_Error("maxCharacters required") end
	if self.number        == nil then self.number = false                  end
	-- Derived
	--   self._editVar
end

function EEex_Options_EditWidget:_onMap(displayEntry, optionID)
	self._editVar = "EEex_Options_Private_"..optionID.."_EditVar"
end

function EEex_Options_EditWidget:_buildLayout(displayEntry, menuName)
	local normalStyle = styles.normal
	return EEex_Options_Private_LayoutEdit.new({
		["menuName"]     = menuName,
		["font"]         = normalStyle.font,
		["point"]        = normalStyle.point,
		["displayEntry"] = displayEntry,
	})
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_EditWidget  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_KeybindWidget ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_KeybindWidget = {}
EEex_Options_KeybindWidget.__index = EEex_Options_KeybindWidget
setmetatable(EEex_Options_KeybindWidget, EEex_Options_Widget)
--print("EEex_Options_KeybindWidget: "..tostring(EEex_Options_KeybindWidget))

--////////////
--// Static //
--////////////

EEex_Options_KeybindWidget.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_KeybindWidget)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_KeybindWidget:_buildLayout(displayEntry, menuName)

	local backgroundInstance

	local backgroundLayoutCallback = function(instanceData)
		backgroundInstance = instanceData.id
	end

	local buttonLayoutCallback = function(instanceData)
		instanceData._pairedBackgroundInstance = backgroundInstance
	end

	return EEex_Options_Private_LayoutHBox.new({
		["children"] = {
			EEex_Options_Private_LayoutKeybindBackground.new({
				["menuName"]       = menuName,
				["layoutCallback"] = backgroundLayoutCallback,
				["displayEntry"]   = displayEntry,
			}),
			EEex_Options_Private_LayoutFixed.new({
				["width"] = 5,
			}),
			EEex_Options_Private_LayoutKeybindButton.new({
				["menuName"]       = menuName,
				["layoutCallback"] = buttonLayoutCallback,
			}),
			EEex_Options_Private_LayoutFixed.new({
				["width"] = 5,
			}),
			EEex_Options_Private_LayoutKeybindUpDownButton.new({
				["menuName"]       = menuName,
				["layoutCallback"] = buttonLayoutCallback,
			}),
		}
	})
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_KeybindWidget ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_ToggleWidget  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_ToggleWidget = {}
EEex_Options_ToggleWidget.__index = EEex_Options_ToggleWidget
setmetatable(EEex_Options_ToggleWidget, EEex_Options_Widget)
--print("EEex_Options_ToggleWidget: "..tostring(EEex_Options_ToggleWidget))

--////////////
--// Static //
--////////////

EEex_Options_ToggleWidget.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_ToggleWidget)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_ToggleWidget:_init()
	EEex_Utility_CallSuper(EEex_Options_ToggleWidget, "_init", self)
	if self.disallowToggleOff == nil then self.disallowToggleOff = false end
	if self.forceOthers       == nil then self.forceOthers       = {}    end
	if self.toggleValue       == nil then self.toggleValue       = 1     end
	-- Optional
	--   self.toggleState
	--   self.toggleWarning
end

function EEex_Options_ToggleWidget:_buildLayout(displayEntry, menuName)
	return EEex_Options_Private_LayoutToggle.new({
		["menuName"]     = menuName,
		["displayEntry"] = displayEntry,
	})
end

function EEex_Options_ToggleWidget:_onShowBeforeLayout(displayEntry)
	local widget = displayEntry.widget
	local mainDisplayEntry = widget.deferTo and EEex_Options_Private_IdToDisplayEntry[widget.deferTo] or displayEntry
	widget.toggleState = mainDisplayEntry:_getWorkingValue() == widget.toggleValue
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_ToggleWidget  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--===========
-- Globals ==
--===========

EEex_Options_Private_CapturedEdit            = nil -- uiItem
EEex_Options_Private_IdToDisplayEntry        = {}
EEex_Options_Private_IdToOption              = {}
EEex_Options_Private_MainInset               = nil -- EEex_Options_Private_LayoutInset
EEex_Options_Private_MainVerticalTabArea     = nil -- EEex_Options_Private_LayoutVerticalTabArea
EEex_Options_Private_PendingEditFocus        = nil
EEex_Options_Private_TabInsertIndex          = 1
EEex_Options_Private_Tabs                    = {}
EEex_Options_Private_TemplateInstancesByName = {}

EEex_Options_Private_KeybindFocusedInstance        = nil
EEex_Options_Private_KeybindPendingFocusedInstance = nil
EEex_Options_Private_KeybindRecordedKeys           = {}
EEex_Options_Private_KeybindRecordedModifiers      = {}

--===========
-- Utility ==
--===========

function EEex_Options_Private_UnpackColor(color)
	local alpha = EEex_BAnd(EEex_RShift(color, 24), 0xFF)
	local blue = EEex_BAnd(EEex_RShift(color, 16), 0xFF)
	local green = EEex_BAnd(EEex_RShift(color, 8), 0xFF)
	local red = EEex_BAnd(color, 0xFF)
	return alpha, blue, green, red
end

function EEex_Options_Private_PackColor(alpha, blue, green, red)
	return EEex_Flags({EEex_LShift(alpha, 24), EEex_LShift(blue, 16), EEex_LShift(green, 8), red})
end

function EEex_Options_Private_GetTextWidthHeight(font, pointSize, text)

	-- Ensure space so that the text wraps
	if text:sub(-1) ~= " " then
		text = text.." "
	end

	local effectivePoint = math.floor(EngineGlobals.g_pBaldurChitin.cVideo.pCurrentMode.nHeight * pointSize / CVidMode.SCREENHEIGHT)
	if effectivePoint == 0 then
		 -- This case causes Infinity_GetContentHeight() to crash (yes, really...)
		return 0, 0
	end

	local oneLineHeight = Infinity_GetContentHeight(font, 0, "", pointSize, 0)
	local currentWidth = 0
	local currentHeight = nil
	repeat
		currentWidth = currentWidth + 1
		currentHeight = Infinity_GetContentHeight(font, currentWidth, text, pointSize, 0)
	until currentHeight <= oneLineHeight

	return currentWidth, oneLineHeight
end

function EEex_Options_Private_GetMaxTextBounds(font, pointSize, numChars)
	local str = ""
	for i = 1, numChars do str = str.."W" end
	return EEex_Options_Private_GetTextWidthHeight(font, pointSize, str)
end

function EEex_Options_Private_CreateInstance(menuName, templateName, x, y, w, h)

	local instanceNameEntry = EEex_Options_Private_TemplateInstancesByName[templateName]

	if not instanceNameEntry then
		instanceNameEntry = {["maxID"] = 0}
		EEex_Options_Private_TemplateInstancesByName[templateName] = instanceNameEntry
	end

	local newID = instanceNameEntry.maxID + 1
	instanceNameEntry.maxID = newID

	local instanceEntry = {
		["id"] = newID,
		["uiItem"] = EEex_Menu_InjectTemplateInstance(menuName, templateName, newID, x, y, w, h),
	}

	instanceNameEntry[newID] = instanceEntry
	return instanceEntry
end

function EEex_Options_Private_CreateDelayIcon(menuName, displayEntry, x, y, w, h)
	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_DelayIcon", x, y, w, h)
	instanceData.displayEntry = displayEntry
	return instanceData
end

function EEex_Options_Private_CreateEdit(menuName, displayEntry, x, y, w, h)

	local widget = displayEntry.widget

	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_Edit", x, y, w, h)
	instanceData.displayEntry = displayEntry

	local editUD = instanceData.uiItem.edit
	editUD.var:pointTo(EEex_WriteStringCache(widget._editVar))
	if widget.maxCharacters then editUD.maxchars = widget.maxCharacters + 1 end

	_G[widget._editVar] = tostring(displayEntry:_getWorkingValue())
	return instanceData
end

function EEex_Options_Private_CreateExitButton(menuName, x, y, w, h)
	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_ExitButton", x, y, w, h)
	return instanceData
end

function EEex_Options_Private_CreateSeparator(menuName, color, x, y, w, h)
	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_Separator", x, y, w, h)
	instanceData.color = color or 0x406F6F70
	return instanceData
end

function EEex_Options_Private_CreateText(menuName, text, x, y, w, h, extraArgs)

	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_Text", x, y, w, h)
	instanceData.text = text

	local uiItem = instanceData.uiItem
	local textUD = uiItem.text

	if extraArgs == nil then extraArgs = {} end
	if extraArgs.font            ~= nil then textUD.font:pointTo(EEex_WriteStringCache(extraArgs.font)) end
	if extraArgs.point           ~= nil then textUD.point = extraArgs.point                             end
	if extraArgs.horizontalAlign ~= nil then uiItem.ha    = extraArgs.horizontalAlign                   end
	if extraArgs.verticalAlign   ~= nil then uiItem.va    = extraArgs.verticalAlign                     end

	return instanceData
end

function EEex_Options_Private_CreateToggle(menuName, displayEntry, x, y, w, h)
	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_Toggle", x, y, w, h)
	instanceData.displayEntry = displayEntry
	return instanceData
end

--=============
-- Functions ==
--=============

----------
-- Edit --
----------

function EEex_Options_Private_EditSetOption(displayEntry)

	local option = displayEntry._option
	local widget = displayEntry.widget
	local strVal = _G[widget._editVar]

	if widget.number then
		-- Don't allow floating numbers to be set without a leading 0 (this bypasses character limits)
		local toSetVal = strVal:find("^%s*%.") == nil and tonumber(strVal) or option:_getDefault()
		strVal = tostring(displayEntry:_setWorkingValue(toSetVal))
	else
		strVal = strVal:gsub("^%s+", "")
		strVal = strVal:gsub("%s+$", "")
		strVal = displayEntry:_setWorkingValue(strVal)
	end

	_G[widget._editVar] = strVal
end

function EEex_Options_Private_EditCheckSetCapturedValue()
	if EEex_Options_Private_CapturedEdit == nil then return end
	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Edit"][EEex_Options_Private_CapturedEdit.instanceId]
	EEex_Options_Private_EditSetOption(instanceData.displayEntry)
end

-- On menu tick
function EEex_Options_Private_EditCheckPendingFocus()
	if EEex_Options_Private_PendingEditFocus == nil then return end
	Infinity_FocusTextEdit(EEex_Options_Private_PendingEditFocus)
	EEex_Options_Private_PendingEditFocus = nil
end

-- On menu tick
function EEex_Options_Private_EditCheckUnfocused()

	local captured = EngineGlobals.capture.item
	local editCaptured = false

	if captured ~= nil and captured.templateName:get() == "EEex_Options_TEMPLATE_Edit" then
		if EEex_Options_Private_CapturedEdit ~= nil and EEex_UDEqual(EEex_Options_Private_CapturedEdit, captured) then
			-- Same edit instance as last time
			return
		end
		editCaptured = true
	end

	EEex_Options_Private_EditCheckSetCapturedValue()
	EEex_Options_Private_CapturedEdit = editCaptured and captured or nil
end

-- On menu close
function EEex_Options_Private_EditCheckKillFocus()
	EEex_Options_Private_PendingEditFocus = nil
	EEex_Options_Private_EditCheckSetCapturedValue()
	EEex_Options_Private_CapturedEdit = nil
end

-------------
-- Keybind --
-------------

function EEex_Options_Private_KeybindResetPulse(instanceData)
	instanceData.currentAlpha, instanceData.currentBlue, instanceData.currentGreen, instanceData.currentRed = EEex_Options_Private_UnpackColor(startColor)
	instanceData.currentColor = instanceData.startColor
	instanceData.direction = true
end

function EEex_Options_Private_KeybindAdvancePulse(instanceData)

	local startAlpha, startBlue, startGreen, startRed = EEex_Options_Private_UnpackColor(instanceData.startColor)
	local endAlpha,   endBlue,   endGreen,   endRed   = EEex_Options_Private_UnpackColor(instanceData.endColor)

	local currentAlpha = instanceData.currentAlpha
	local currentBlue  = instanceData.currentBlue
	local currentGreen = instanceData.currentGreen
	local currentRed   = instanceData.currentRed

	local dir         = instanceData.direction and 1 or -1
	local stepPercent = EEex_CChitin.TIMER_UPDATES_PER_SECOND / instanceData.pulseMilliseconds

	local stepColor = function(startColor, currentColor, endColor)
		local newColor = currentColor + dir * (endColor - startColor) * stepPercent
		if endColor >= startColor then
			newColor = math.max(startColor, math.min(newColor, endColor))
		else
			newColor = math.max(endColor, math.min(newColor, startColor))
		end
		return newColor
	end

	currentAlpha = stepColor( startAlpha, currentAlpha, endAlpha )
	currentBlue  = stepColor( startBlue,  currentBlue,  endBlue  )
	currentGreen = stepColor( startGreen, currentGreen, endGreen )
	currentRed   = stepColor( startRed,   currentRed,   endRed   )

	instanceData.currentAlpha = currentAlpha
	instanceData.currentBlue  = currentBlue
	instanceData.currentGreen = currentGreen
	instanceData.currentRed   = currentRed
	instanceData.currentColor = EEex_Options_Private_PackColor(currentAlpha, currentBlue, currentGreen, currentRed)

	if instanceData.direction then
		if currentAlpha == endAlpha and currentRed == endRed and currentGreen == endGreen and currentBlue == endBlue then
			instanceData.direction = false
		end
	else
		if currentAlpha == startAlpha and currentRed == startRed and currentGreen == startGreen and currentBlue == startBlue then
			instanceData.direction = true
		end
	end
end

function EEex_Options_Private_KeybindUpdateText(instanceData, modifierKeys, keys)
	instanceData.text = EEex_Options_MarshalKeybind(modifierKeys, keys)
end

function EEex_Options_Private_KeybindUpdateTextFromRecorded(instanceData)
	EEex_Options_Private_KeybindUpdateText(instanceData, EEex_Options_Private_KeybindRecordedModifiers, EEex_Options_Private_KeybindRecordedKeys)
end

function EEex_Options_Private_KeybindRecordKey(instanceData, key)

	-- Avoid duplicates
	for _, recordedKey in ipairs(EEex_Options_Private_KeybindRecordedKeys) do
		if recordedKey == key then
			return
		end
	end

	-- Insert
	table.insert(EEex_Options_Private_KeybindRecordedKeys, key)

	-- Update text
	EEex_Options_Private_KeybindUpdateTextFromRecorded(instanceData)
end

EEex_Options_Private_KeybindSpecificModifierOrder = {
	[ EEex_Key_GetFromName("Left Ctrl")   ] = 1,
	[ EEex_Key_GetFromName("Left Shift")  ] = 2,
	[ EEex_Key_GetFromName("Left Alt")    ] = 3,
	[ EEex_Key_GetFromName("Right Ctrl")  ] = 4,
	[ EEex_Key_GetFromName("Right Shift") ] = 5,
	[ EEex_Key_GetFromName("Right Alt")   ] = 6,
}

EEex_Options_Private_KeybindDefaultModifierOrder = #EEex_Options_Private_KeybindSpecificModifierOrder + 1

function EEex_Options_Private_KeybindGetModifierOrder(key)
	return EEex_Options_Private_KeybindSpecificModifierOrder[key] or EEex_Options_Private_KeybindDefaultModifierOrder
end

function EEex_Options_Private_KeybindRecordModifierKey(instanceData, key)

	-- Avoid duplicates
	for _, recordedKey in ipairs(EEex_Options_Private_KeybindRecordedModifiers) do
		if recordedKey == key then
			return
		end
	end

	-- Insert and sort
	table.insert(EEex_Options_Private_KeybindRecordedModifiers, key)
	table.sort(EEex_Options_Private_KeybindRecordedModifiers, function(a, b)
		return EEex_Options_Private_KeybindGetModifierOrder(a) < EEex_Options_Private_KeybindGetModifierOrder(b)
	end)

	-- Update text
	EEex_Options_Private_KeybindUpdateTextFromRecorded(instanceData)
end

-- On keybind focus gained
function EEex_Options_Private_KeybindOnActivateFocus(instanceData)
	EEex_Options_Private_KeybindUpdateTextFromRecorded(instanceData)
	EEex_Key_EnterCaptureMode(EEex_Options_Private_KeybindOnCaptureKey)
end

EEex_Options_Private_ModifierKeys = {
	[ EEex_Key_GetFromName("Left Ctrl")   ] = true,
	[ EEex_Key_GetFromName("Left Shift")  ] = true,
	[ EEex_Key_GetFromName("Left Alt")    ] = true,
	[ EEex_Key_GetFromName("Right Ctrl")  ] = true,
	[ EEex_Key_GetFromName("Right Shift") ] = true,
	[ EEex_Key_GetFromName("Right Alt")   ] = true,
}

-- On focused keybind captured key
function EEex_Options_Private_KeybindOnCaptureKey(key)

	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][EEex_Options_Private_KeybindFocusedInstance]

	if key == EEex_Key_GetFromName("Escape") then
		EEex_Options_Private_KeybindKillFocus(instanceData)
		return
	end

	if key == EEex_Key_GetFromName("Return") then
		EEex_Options_Private_KeybindEndFocus(instanceData)
		return
	end

	if key == EEex_Key_GetFromName("Backspace") or key == EEex_Key_GetFromName("Delete") then
		EEex_Options_Private_KeybindRecordedModifiers = {}
		EEex_Options_Private_KeybindRecordedKeys = {}
		EEex_Options_Private_KeybindUpdateTextFromRecorded(instanceData)
		return
	end

	if EEex_Options_Private_ModifierKeys[key] then
		EEex_Options_Private_KeybindRecordModifierKey(instanceData, key)
	else
		EEex_Options_Private_KeybindRecordKey(instanceData, key)
	end
end

-- On keybind accepted (via Enter key or Submit button)
function EEex_Options_Private_KeybindEndFocus(instanceData)

	local displayEntry = instanceData.displayEntry

	local existingVal = EEex.DeepCopy(displayEntry:_getWorkingValue()) -- Copy for subsequent modification
	existingVal[1] = EEex_Options_Private_KeybindRecordedModifiers
	existingVal[2] = EEex_Options_Private_KeybindRecordedKeys
	displayEntry:_setWorkingValue(existingVal)

	EEex_Options_Private_KeybindKillFocus(instanceData, true)
end

-- On keybind killed when accepted (see above), or canceled (via Escape key or menu closing)
function EEex_Options_Private_KeybindKillFocus(instanceData, accepted)

	EEex_Key_ExitCaptureMode()
	EEex_Options_Private_KeybindResetPulse(instanceData)
	EEex_Options_Private_KeybindFocusedInstance   = nil
	EEex_Options_Private_KeybindRecordedModifiers = {}
	EEex_Options_Private_KeybindRecordedKeys      = {}

	if not accepted then
		local value = instanceData.displayEntry:_getWorkingValue()
		EEex_Options_Private_KeybindUpdateText(instanceData, value[1], value[2])
	end
end

-- On menu tick
function EEex_Options_Private_KeybindCheckUnfocused(instanceData)

	local captured = EngineGlobals.capture.item
	if captured == nil then return end

	local templateName = captured.templateName:get()
	local instanceId = captured.instanceId

	if templateName == "EEex_Options_TEMPLATE_KeybindButton" or templateName == "EEex_Options_TEMPLATE_KeybindButtonUpDown" then

		local buttonInstanceData = EEex_Options_Private_TemplateInstancesByName[templateName][instanceId]

		if buttonInstanceData._pairedBackgroundInstance ~= EEex_Options_Private_KeybindFocusedInstance then
			EEex_Options_Private_KeybindKillFocus(instanceData)
			EEex_Options_Private_KeybindPendingFocusedInstance = nil
		end

	elseif templateName == "EEex_Options_TEMPLATE_KeybindBackground" then

		if instanceId ~= EEex_Options_Private_KeybindFocusedInstance then
			EEex_Options_Private_KeybindKillFocus(instanceData)
		end
	else
		EEex_Options_Private_KeybindKillFocus(instanceData)
		EEex_Options_Private_KeybindPendingFocusedInstance = nil
	end
end

-- On menu tick
function EEex_Options_Private_KeybindTick()

	local instanceData

	if EEex_Options_Private_KeybindFocusedInstance ~= nil then
		instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][EEex_Options_Private_KeybindFocusedInstance]
		EEex_Options_Private_KeybindCheckUnfocused(instanceData)
	end

	if EEex_Options_Private_KeybindPendingFocusedInstance ~= nil then
		EEex_Options_Private_KeybindFocusedInstance = EEex_Options_Private_KeybindPendingFocusedInstance
		EEex_Options_Private_KeybindPendingFocusedInstance = nil
		instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][EEex_Options_Private_KeybindFocusedInstance]
		EEex_Options_Private_KeybindOnActivateFocus(instanceData)
	end

	if EEex_Options_Private_KeybindFocusedInstance ~= nil then
		EEex_Options_Private_KeybindAdvancePulse(instanceData)
	end
end

-- On menu close
function EEex_Options_Private_KeybindCheckKillFocus()
	if EEex_Options_Private_KeybindFocusedInstance ~= nil then
		local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_KeybindBackground"][EEex_Options_Private_KeybindFocusedInstance]
		EEex_Options_Private_KeybindKillFocus(instanceData)
	end
	EEex_Options_Private_KeybindPendingFocusedInstance = nil
end

-------------
-- General --
-------------

function EEex_Options_Private_Tick()
	EEex_Options_Private_KeybindTick()
	EEex_Options_Private_EditCheckPendingFocus()
	EEex_Options_Private_EditCheckUnfocused()
	return 1
end

EEex.RegisterSlicedRect("EEex_Options_BackgroundRect", {
	["topLeft"]     = {  0,  0, 32, 32 },
	["top"]         = { 16,  0, 32, 32 },
	["topRight"]    = { 32,  0, 32, 32 },
	["right"]       = { 32, 16, 32, 32 },
	["bottomRight"] = { 32, 32, 32, 32 },
	["bottom"]      = { 16, 32, 32, 32 },
	["bottomLeft"]  = {  0, 32, 32, 32 },
	["left"]        = {  0, 16, 32, 32 },
	["center"]      = { 16, 16, 32, 32 },
	["dimensions"]  = { 64, 64 },
	["resref"]      = "X-OPTBOX",
	["flags"]       = 0,
})

function EEex_Options_Private_Background_Render(item)
	EEex.DrawSlicedRect("EEex_Options_BackgroundRect", { item:getArea() })
end

function EEex_Options_Private_BuildLayout()

	EEex_Options_Private_MainVerticalTabArea = EEex_Options_Private_LayoutVerticalTabArea.new({
		["menuName"]               = "EEex_Options",
		["tabs"]                   = EEex_Options_Private_Tabs,
		["tabsListName"]           = "EEex_Options_Sidebar",
		["tabsSelectionVarName"]   = "EEex_Options_Private_CurrentTab",
		["tabsListRowHeight"]      = 36,
		["separatorPad"]           = 10,
		["tabsListTopPad"]         = 5,
		["tabsListBottomPad"]      = 5,
		["tabsListScrollbarWidth"] = 31,
	})

	EEex_Options_Private_MainInset = EEex_Options_Private_LayoutVBox.new({
		["children"] = {
			EEex_Options_Private_LayoutFixed.new({ ["height"] = 4 }),
			EEex_Options_Private_LayoutStacking.new({
				["growHorizontally"] = true,
				["children"] = {
					{
						["layout"] = EEex_Options_Private_LayoutText.new({
							["menuName"]        = "EEex_Options",
							["font"]            = styles.normal.font,
							["point"]           = 16,
							["horizontalAlign"] = EEex_Options_Private_LayoutText_HorizontalAlign.CENTER,
							["text"]            = "EEex_Options_TRANSLATION_Options",
							["translate"]       = true,
						}),
					},
					{
						["align"]  = EEex_Options_Private_LayoutStacking_Align.TOP_RIGHT,
						["layout"] = EEex_Options_Private_LayoutExitButton.new({ ["menuName"] = "EEex_Options" })
									 :inset({ ["growToParent"] = true, ["insetRight"] = 5 }),
					},
				},
			}),
			EEex_Options_Private_LayoutFixed.new({ ["height"] = 7 }),
			EEex_Options_Private_LayoutSeparator.new({ ["menuName"] = "EEex_Options", ["height"] = 2 }),
			EEex_Options_Private_MainVerticalTabArea,
		},
	})
	:inset({ ["insetLeft"] = 10, ["insetTop"] = 10, ["insetRight"] = 10, ["insetBottom"] = 10 })
end

function EEex_Options_Private_SpecialSortTabs()

	local modulesTabIndex
	local firstModuleTabIndex

	for i, tabEntry in ipairs(EEex_Options_Private_Tabs) do
		if tabEntry.label == "EEex_Options_TRANSLATION_Modules" then
			modulesTabIndex = i
			break
		end
	end

	for i, tabEntry in ipairs(EEex_Options_Private_Tabs) do
		local tabName = t(tabEntry.label)
		if #tabName >= 8 and tabName:sub(1, 8) == "Module: " then
			firstModuleTabIndex = i
			break
		end
	end

	if modulesTabIndex == nil or firstModuleTabIndex == nil then
		return
	end

	local modulesTab = EEex_Options_Private_Tabs[modulesTabIndex]
	table.remove(EEex_Options_Private_Tabs, modulesTabIndex)
	table.insert(EEex_Options_Private_Tabs, firstModuleTabIndex, modulesTab)
end

function EEex_Options_Private_ReadOptions(early)
	for _, option in pairs(EEex_Options_Private_IdToOption) do
		if early == option:_canReadEarly() then
			option:_set(option:_read(), true)
		end
	end
end

function EEex_Options_Private_Layout()

	-- Reset top level instances
	EEex_Menu_DestroyAllTemplates("EEex_Options")

	local screenWidth, screenHeight = Infinity_GetScreenSize()

	-- Calculate the layout
	EEex_Options_Private_MainInset:_onInitLayout()
	EEex_Options_Private_MainInset:calculateLayout(0, 0, screenWidth, screenHeight)
	local layoutWidth = EEex_Options_Private_MainInset:getLayoutWidth()
	local layoutHeight = EEex_Options_Private_MainInset:getLayoutHeight()

	-- Find the coordinates required to center the popup
	local popupLeft = (screenWidth - layoutWidth) / 2
	local popupTop = (screenHeight - layoutHeight) / 2
	local popupRight = popupLeft + layoutWidth
	local popupBottom = popupTop + layoutHeight

	-- Actually layout the popup
	EEex_Options_Private_MainInset:layout(popupLeft, popupTop, popupRight, popupBottom)

	-- Move the background
	Infinity_SetArea("EEex_Options_Background", popupLeft, popupTop, layoutWidth, layoutHeight)
end

function EEex_Options_Private_FindItemByBam(menu, toFindBam)
	if menu == nil then return end
	local item = menu.items
	while item ~= nil do
		if EEex_Menu_GetItemVariant(item.bam.resref) == toFindBam then
			return item
		end
		item = item.next
	end
end

function EEex_Options_Private_FindItemByListTable(menu, toFindListTable)
	if menu == nil then return end
	local item = menu.items
	while item ~= nil do
		if item.type == uiItemType.ITEM_LIST and EEex_GetLuaRegistryIndex(item.list.table)() == toFindListTable then
			return item
		end
		item = item.next
	end
end

function EEex_Options_Private_FindItemByName(menu, toFindName)
	if menu == nil then return end
	local item = menu.items
	while item ~= nil do
		if item.name:get() == toFindName then
			return item
		end
		item = item.next
	end
end

function EEex_Options_Private_FindItemByText(menu, toFindText)
	if menu == nil then return end
	local item = menu.items
	while item ~= nil do
		local text = EEex_Menu_GetItemVariant(item.text.text)
		if type(text) == "function" then text = text() end
		if text == toFindText then
			return item
		end
		item = item.next
	end
end

function EEex_Options_Private_FindItemByType(menu, toFindType)
	if menu == nil then return end
	local item = menu.items
	while item ~= nil do
		if item.type == toFindType then
			return item
		end
		item = item.next
	end
end

function EEex_Options_Private_InstallButtons()

	local injectCopyButton = function(existingMenuName, existingButton, mode)

		local existingMenu = EEex_Menu_Find(existingMenuName)
		if existingMenu == nil then return false end

		local existingButtonArea = existingButton.area
		local existingButtonBam  = existingButton.bam
		local existingButtonPad  = existingButton.pad

		local injectButton = function()

			local injectedButton = EEex_Menu_InjectTemplateInstance(existingMenuName, "EEex_Options_TEMPLATE_OpenButton", 0, 0, 0)
			local injectedButtonArea = injectedButton.area
			local injectedButtonBam  = injectedButton.bam
			local injectedButtonPad  = injectedButton.pad

			injectedButtonBam.resref   = existingButtonBam.resref
			injectedButtonBam.sequence = existingButtonBam.sequence

			injectedButtonPad.x = existingButtonPad.x
			injectedButtonPad.y = existingButtonPad.y
			injectedButtonPad.w = existingButtonPad.w
			injectedButtonPad.h = existingButtonPad.h

			return injectedButtonArea
		end

		local existingOnOpen = EEex_Menu_GetItemFunction(existingMenu.reference_onOpen)

		if mode == 0 then

			local injectedButtonArea = injectButton()

			EEex_Menu_SetItemFunction(existingMenu.reference_onOpen, function()
				if existingOnOpen ~= nil then existingOnOpen() end
				injectedButtonArea.x = existingButtonArea.x
				injectedButtonArea.y = existingButtonArea.y
				injectedButtonArea.w = existingButtonArea.w
				injectedButtonArea.h = existingButtonArea.h
			end)

		elseif mode == 1 then

			local logo = EEex_Options_Private_FindItemByBam(existingMenu, "BIGLOGO")
			if logo == nil then return false end

			local logoArea = logo.area
			local injectedButtonArea = injectButton()

			EEex_Menu_SetItemFunction(existingMenu.reference_onOpen, function()
				if existingOnOpen ~= nil then existingOnOpen() end
				local existingHeight = existingButtonArea.h
				injectedButtonArea.x = logoArea.x + (logoArea.w - existingButtonArea.w) / 2
				injectedButtonArea.y = logoArea.y + logoArea.h + 13
				injectedButtonArea.w = existingButtonArea.w
				injectedButtonArea.h = existingHeight
			end)

		elseif mode == 2 or mode == 3 or mode == 4 then

			local buttonGap = 5

			if mode == 3 or mode == 4 then

				local buttonShrinkAmount = 3
				local specialAdj = 0
				local optionsListItem

				if mode == 3 then
					specialAdj = 14
					optionsListItem = EEex_Options_Private_FindItemByListTable(existingMenu, OptionsButtons)
				elseif mode == 4 then
					optionsListItem = EEex_Options_Private_FindItemByName(existingMenu, "MenuOptionsArea")
				end

				if optionsListItem == nil then return false end
				local optionsList = optionsListItem.list

				local columns = optionsList.columns
				if columns == nil then return false end

				local columnItem = columns.items
				if columnItem == nil then return false end

				local rowHeight = optionsList.rowheight
				optionsList.rowheight = rowHeight - buttonShrinkAmount

				local buttonHeight

				repeat
					local columnItemArea = columnItem.area
					buttonHeight = columnItemArea.h
					columnItemArea.h = buttonHeight - buttonShrinkAmount
					columnItem.bam.scaletoclip = 1
					columnItem = columnItem.next
				until columnItem == nil

				buttonGap = rowHeight - buttonHeight

				local existingButtonArea = existingButton.area
				existingButtonArea.h = existingButtonArea.h - buttonShrinkAmount
				existingButtonArea.y = existingButtonArea.y - #OptionsButtons * buttonShrinkAmount + existingButtonArea.h + buttonGap - specialAdj
				existingButton.bam.scaletoclip = 1
			end

			local injectedButtonArea = injectButton()

			EEex_Menu_SetItemFunction(existingMenu.reference_onOpen, function()
				if existingOnOpen ~= nil then existingOnOpen() end
				local existingHeight = existingButtonArea.h
				injectedButtonArea.x = existingButtonArea.x
				injectedButtonArea.y = existingButtonArea.y - existingHeight - buttonGap
				injectedButtonArea.w = existingButtonArea.w
				injectedButtonArea.h = existingHeight
			end)
		end

		return true
	end

	-- Infinity UI++
	local modifyInfinityUI = function()

		local optionsBarMenu = EEex_Menu_Find("RG_START_OPTIONS_BAR")
		if optionsBarMenu == nil then return false end

		if type(rgString) ~= "function" then return false end

		local existingButton = EEex_Options_Private_FindItemByText(optionsBarMenu, rgString("RG_UI_SETTINGS"))
		if existingButton == nil then return false end

		local existingButtonArea = existingButton.area
		local existingButtonBam  = existingButton.bam
		local existingButtonPad  = existingButton.pad

		local injectedButton = EEex_Menu_InjectTemplateInstance("RG_START_OPTIONS_BAR", "EEex_Options_TEMPLATE_OpenButton", 0, 0, 0)
		local injectedButtonArea = injectedButton.area
		local injectedButtonBam  = injectedButton.bam
		local injectedButtonPad  = injectedButton.pad

		injectedButtonPad.x = existingButtonPad.x
		injectedButtonPad.y = existingButtonPad.y
		injectedButtonPad.w = existingButtonPad.w
		injectedButtonPad.h = existingButtonPad.h

		injectedButtonBam.resref = existingButtonBam.resref
		injectedButtonBam.sequence = existingButtonBam.sequence

		local textVariant = EEex_NewUD("uiVariant")
		textVariant.type = uiVariantType.UIVAR_FUNCTION
		textVariant.value.luaFunc = EEex_AddToLuaRegistry(function() return rgString("EEex Options") end)
		injectedButton.text.text = textVariant

		local existingOnOpen = EEex_Menu_GetItemFunction(optionsBarMenu.reference_onOpen)

		EEex_Menu_SetItemFunction(optionsBarMenu.reference_onOpen, function()
			if existingOnOpen ~= nil then existingOnOpen() end
			local existingHeight = existingButtonArea.h
			injectedButtonArea.x = existingButtonArea.x
			injectedButtonArea.y = existingButtonArea.y + existingHeight
			injectedButtonArea.w = existingButtonArea.w
			injectedButtonArea.h = existingHeight
		end)

		return true
	end

	-- Dragonspear UI++
	local modifyDragonspearUI = function()

		local escapeMenu = EEex_Menu_Find("ESC_MENU")
		if escapeMenu == nil then return false end

		local startOptionsMenu = EEex_Menu_Find("START_OPTIONS")
		if startOptionsMenu == nil then return false end

		if EEex_Options_Private_FindItemByName(escapeMenu, "RGESCLOGO") == nil then return end

		local logo = EEex_Options_Private_FindItemByBam(escapeMenu, "BIGLOGO")
		if logo == nil then return false end

		local startOptionsBackButton = EEex_Options_Private_FindItemByName(startOptionsMenu, "MenuButton5OP")
		if startOptionsBackButton == nil then return false end

		local logoArea = logo.area

		local injectedButton = EEex_Menu_InjectTemplateInstance("ESC_MENU", "EEex_Options_TEMPLATE_OpenButton", 0, 0, 0)
		local injectedButtonArea = injectedButton.area
		local injectedButtonBam  = injectedButton.bam

		local bamResrefVariant = EEex_NewUD("uiVariant")
		bamResrefVariant.type = uiVariantType.UIVAR_STRING
		bamResrefVariant.value.strVal:set("GUIBUTWT")
		injectedButtonBam.resref = bamResrefVariant

		local existingOnOpen = EEex_Menu_GetItemFunction(escapeMenu.reference_onOpen)

		EEex_Menu_SetItemFunction(escapeMenu.reference_onOpen, function()
			if existingOnOpen ~= nil then existingOnOpen() end
			injectedButtonArea.x = logoArea.x + (logoArea.w - 300) / 2
			injectedButtonArea.y = logoArea.y + logoArea.h
			injectedButtonArea.w = 300
			injectedButtonArea.h = 44
		end)

		injectCopyButton("START_OPTIONS", startOptionsBackButton, 4)
		return true
	end

	-- BG:EE (with/without SoD), BG2:EE, IWD:EE, EET (with/without EET_gui), LeUI-BG1, LeUI-SoD, LeUI-BG2, LeUI-IWD
	local modifyNormal = function()

		local escapeMenu = EEex_Menu_Find("ESC_MENU")
		if escapeMenu == nil then return false end

		local startOptionsMenu = EEex_Menu_Find("START_OPTIONS")
		if startOptionsMenu == nil then return false end

		local existingButton = EEex_Options_Private_FindItemByText(escapeMenu, t("RETURN_GAME_BUTTON"))
		if existingButton == nil then return false end

		if EEex_Options_Private_FindItemByListTable(startOptionsMenu, OptionsButtons) == nil then

			if EEex_Options_Private_FindItemByBam(startOptionsMenu, "BIGLOGO") ~= nil then
				-- BG2:EE, IWD:EE, EET (without EET_gui), LeUI-BG1, LeUI-SoD, LeUI-BG2, LeUI-IWD
				injectCopyButton("ESC_MENU",      existingButton, 2)
				injectCopyButton("START_OPTIONS", existingButton, 1)
			else
				-- BG:EE (without SoD)
				local startMainMenu = EEex_Menu_Find("START_MAIN")
				if startMainMenu == nil then return false end

				local continueButton = EEex_Options_Private_FindItemByText(startMainMenu, t("CONTINUE_BUTTON"))
				if continueButton == nil then return false end

				injectCopyButton("ESC_MENU",      existingButton, 2)
				injectCopyButton("START_OPTIONS", continueButton, 0)
			end
		else
			-- Dragonspear UI (BG:EE with SoD or EET with EET_gui)
			local backButton = EEex_Options_Private_FindItemByText(startOptionsMenu, t("BACK_BUTTON"))
			if backButton == nil then return false end

			injectCopyButton("ESC_MENU",      existingButton, 2)
			injectCopyButton("START_OPTIONS", backButton,     3)
		end

		return true
	end

	local modifyExisting = function()
		if modifyInfinityUI()    then return true end
		if modifyDragonspearUI() then return true end
		if modifyNormal()        then return true end
		return false
	end

	modifyExisting()
end

function EEex_Options_Open()
	if Infinity_IsMenuOnStack("EEex_Options") then return end
	EEex_Options_Private_MainInset:showBeforeLayout()
	EEex_Options_Private_Layout()
	EEex_Options_Private_MainInset:showAfterLayout()
	Infinity_PushMenu("EEex_Options")
end

function EEex_Options_Close()
	if not Infinity_IsMenuOnStack("EEex_Options") then return end
	Infinity_PopMenu("EEex_Options")
	EEex_Options_Private_KeybindCheckKillFocus()
	EEex_Options_Private_EditCheckKillFocus()
	EEex_Options_Private_MainInset:hide()
end

function EEex_Options_MarshalKeybind(modifierKeys, keys, fireType)

	local parts = {}
	local partsI = 1

	for _, key in ipairs(modifierKeys) do
		parts[partsI] = EEex_Key_GetName(key)
		partsI = partsI + 1
	end

	for _, key in ipairs(keys) do
		parts[partsI] = EEex_Key_GetName(key)
		partsI = partsI + 1
	end

	local sequenceStr = table.concat(parts, "+")

	if fireType == nil then
		return sequenceStr
	end

	return fireType and sequenceStr.."|Up" or sequenceStr.."|Down"
end

function EEex_Options_UnmarshalKeybind(str)

	local modifierKeys = {}
	local keys = {}
	result = { modifierKeys, keys }

	local modifierKeysI = 1
	local keysI = 1

	local typeSplit = EEex_Utility_Split(str, "|", false, true)

	if #typeSplit ~= 2 then
		return nil
	end

	local sequenceStr = typeSplit[1]
	local typeStr = typeSplit[2]

	for _, keyStr in ipairs(EEex_Utility_Split(sequenceStr, "+", false, true)) do

		local key = EEex_Key_GetFromName(keyStr)

		if key == 0 then
			return nil
		end

		if EEex_Options_Private_ModifierKeys[key] then
			modifierKeys[modifierKeysI] = key
			modifierKeysI = modifierKeysI + 1
		else
			keys[keysI] = key
			keysI = keysI + 1
		end
	end

	if typeStr == "Up" then
		result[3] = true
	elseif typeStr == "Down" then
		result[3] = false
	else
		return nil
	end

	return result
end

function EEex_Options_Register(option)
	EEex_Options_Private_IdToOption[option.id] = option
	return option
end

function EEex_Options_AddTab(label, displayEntriesProvider)

	EEex_GameState_AddInitializedListener(function()

		local menuName = "EEex_Options_Tab" .. EEex_Options_Private_TabInsertIndex

		EEex_Menu_Eval([[
			menu
			{
				name "]] .. menuName .. [["
				ignoreEsc
				label
				{
					area 0 0 0 0
				}
			}
		]])

		local displayEntries = type(displayEntriesProvider) == "function" and displayEntriesProvider() or displayEntriesProvider

		EEex_Options_Private_Tabs[EEex_Options_Private_TabInsertIndex] = {
			["label"] = label,
			["layout"] = EEex_Options_Private_LayoutOptionsPanel.new({
				["menuName"]       = menuName,
				["displayEntries"] = displayEntries,
			})
			:inset({ ["insetTop"] = 5, ["insetRight"] = 5, ["insetBottom"] = 5 }),
		}

		EEex_Options_Private_TabInsertIndex = EEex_Options_Private_TabInsertIndex + 1
		EEex_Utility_AlphanumericSortTable(EEex_Options_Private_Tabs, function(tab) return t(tab.label) end)
	end)
end

function EEex_Options_Get(id)
	return EEex_Options_Private_IdToOption[id]
end

function EEex_Options_Check(optionName, value)
	local option = EEex_Options_Get(optionName)
	if option == nil then return value == nil end
	return option:_get() == value
end
