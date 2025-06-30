
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

------------
-- Public --
------------

function EEex_Options_Private_LayoutObject:inset(o)
	o.children = {self}
	return EEex_Options_Private_LayoutInset.new(o)
end

function EEex_Options_Private_LayoutObject:layout(left, top, right, bottom)
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

function EEex_Options_Private_LayoutObject:show()
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
		child:calculateLayout(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
		child:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
	end

	--print(string.format("[EEex_Options_Private_LayoutParent:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutParent:doLayout()
	for _, child in ipairs(self.children) do
		child:doLayout()
	end
end

function EEex_Options_Private_LayoutParent:show()
	for _, child in ipairs(self.children) do
		child:show()
	end
end

function EEex_Options_Private_LayoutParent:hide()
	for _, child in ipairs(self.children) do
		child:hide()
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

function EEex_Options_Private_LayoutVerticalTabArea:_calculateSidebarWidth()

	local maxWidth = 0

	for _, v in ipairs(self.tabs) do
		local width = EEex_Options_Private_GetTextWidthHeight(styles.normal.font, styles.normal.point, v.name)
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
	tabLayout:doLayout()
	tabLayout:show()
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

function EEex_Options_Private_LayoutVerticalTabArea:show(left, top, right, bottom)
	_G[self.tabsSelectionVarName] = 0
end

function EEex_Options_Private_LayoutVerticalTabArea:hide()
	self:closeCurrentTab()
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutVerticalTabArea ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

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

	for _, child in ipairs(self.children) do
		child:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
	end

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
	self._layoutRight  = right
	self._layoutBottom = newLayoutBottom
	self:_calculateDerivedLayout()

	for _, child in ipairs(self.children) do
		child:_onParentLayoutCalculated(self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom)
	end

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
	self:calculateLayout(left, top, right, bottom, false)
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutInset:calculateLayout(left, top, right, bottom, shrinkToChildrenOverride)

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = right
	self._layoutBottom = bottom

	local innerLeft   = self._layoutLeft   + self.insetLeft
	local innerTop    = self._layoutTop    + self.insetTop
	local innerRight  = self._layoutRight  - self.insetRight
	local innerBottom = self._layoutBottom - self.insetBottom

	local effectiveShrinkToChildren = shrinkToChildrenOverride == nil and self.shrinkToChildren or shrinkToChildrenOverride

	if effectiveShrinkToChildren then

		local maxChildRight = 0
		local maxChildBottom = 0

		for _, child in ipairs(self.children) do
			child:calculateLayout(innerLeft, innerTop, innerRight, innerBottom)
			local childRight = child:getLayoutRight()
			local childBottom = child:getLayoutBottom()
			if childRight > maxChildRight then maxChildRight = childRight end
			if childBottom > maxChildBottom then maxChildBottom = childBottom end
		end

		if maxChildRight < self._layoutRight then
			self._layoutRight = maxChildRight + self.insetRight
			innerRight  = self._layoutRight - self.insetRight
		end

		if maxChildBottom < self._layoutBottom then
			self._layoutBottom = maxChildBottom + self.insetBottom
			innerBottom = self._layoutBottom - self.insetBottom
		end
	else
		for _, child in ipairs(self.children) do
			child:calculateLayout(innerLeft, innerTop, innerRight, innerBottom)
		end
	end

	self:_calculateDerivedLayout()

	for _, child in ipairs(self.children) do
		child:_onParentLayoutCalculated(innerLeft, innerTop, innerRight, innerBottom)
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
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutFixed:calculateLayout(left, top, right, bottom)

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + (self.width or 0)
	self._layoutBottom = self._layoutTop  + (self.height or 0)
	self:_calculateDerivedLayout()

	--print(string.format("[EEex_Options_Private_LayoutFixed:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutFixed:_onParentLayoutCalculated(left, top, right, bottom)
	if self.width == nil then self._layoutRight = right end
	if self.height == nil then self._layoutBottom = right end
	self:_calculateDerivedLayout()
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
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutTemplate:calculateLayout(left, top, right, bottom)

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + (self.width or 0)
	self._layoutBottom = self._layoutTop  + (self.height or 0)
	self:_calculateDerivedLayout()

	--print(string.format("[EEex_Options_Private_LayoutTemplate:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutTemplate:_onParentLayoutCalculated(left, top, right, bottom)
	if self.width == nil then self._layoutRight = right end
	if self.height == nil then self._layoutBottom = right end
	self:_calculateDerivedLayout()
end

function EEex_Options_Private_LayoutTemplate:doLayout()
	EEex_Options_Private_CreateInstance(self.menuName, self.templateName, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_LayoutTemplate  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

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
	--   self.width
	--   self.height
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
	--   self.width
	--   self.height
	if self.width  == nil then self.width  = 32 end
	if self.height == nil then self.height = 32 end
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutToggle, "_init", self)

	if self.option == nil then EEex_Error("option required") end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutToggle:doLayout()
	EEex_Options_Private_CreateToggle(self.menuName, self.option, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
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
	if self.menuName == nil then EEex_Error("menuName required") end
	if self.font     == nil then EEex_Error("font required")     end
	if self.point    == nil then EEex_Error("point required")    end
	if self.option   == nil then EEex_Error("option required")   end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutEdit:calculateLayout(left, top, right, bottom)
	local editWidth, editHeight = EEex_Options_Private_GetMaxTextBounds(self.font, self.point, self.option.type.maxCharacters)
	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + editWidth
	self._layoutBottom = self._layoutTop  + editHeight
	self:_calculateDerivedLayout()
end

function EEex_Options_Private_LayoutEdit:doLayout()
	EEex_Options_Private_CreateEdit(self.menuName, self.option, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight)
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
	if self.horizontalAlign == nil then self.horizontalAlign = EEex_Options_Private_LayoutText_HorizontalAlign.LEFT end
	if self.verticalAlign   == nil then self.verticalAlign   = EEex_Options_Private_LayoutText_VerticalAlign.TOP    end
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutText:calculateLayout(left, top, right, bottom)

	local width, height = EEex_Options_Private_GetTextWidthHeight(self.font, self.point, self.text)

	self._layoutLeft   = left
	self._layoutTop    = top
	self._layoutRight  = self._layoutLeft + width
	self._layoutBottom = self._layoutTop  + height
	self:_calculateDerivedLayout()

	--print(string.format("[EEex_Options_Private_LayoutText:calculateLayout] (%d,%d,%d,%d) (%d,%d)",
	--	self._layoutLeft, self._layoutTop, self._layoutRight, self._layoutBottom, self._layoutWidth, self._layoutHeight))
end

function EEex_Options_Private_LayoutText:_onParentLayoutCalculated(left, top, right, bottom)
	if self.horizontalAlign ~= EEex_Options_Private_LayoutText_HorizontalAlign.LEFT then self._layoutRight  = right  end
	if self.verticalAlign   ~= EEex_Options_Private_LayoutText_VerticalAlign.TOP    then self._layoutBottom = bottom end
	self:_calculateDerivedLayout()
end

function EEex_Options_Private_LayoutText:doLayout()
	EEex_Options_Private_CreateText(self.menuName, self.text, self._layoutLeft, self._layoutTop, self._layoutWidth, self._layoutHeight, {
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

	if self.menuName    == nil then EEex_Error("menuName required") end
	if self.options     == nil then EEex_Error("options required")  end
	if self.columnGap   == nil then self.columnGap   = 20           end
	if self.layerIndent == nil then self.layerIndent = 20           end
	if self.rowGap      == nil then self.rowGap      = 5            end
	if self.widgetGap   == nil then self.widgetGap   = 10           end

	self:_mapOptions()
	self:_buildLayout()
end

function EEex_Options_Private_LayoutOptionsPanel:_mapOptions()

	local handleGroup
	handleGroup = function(group, parentName)

		for _, option in ipairs(group) do

			local optionName = string.format("%s%s", parentName, option.id)
			EEex_Options_Private_OptionsMap[optionName] = option

			local optionType = option.type
			if optionType ~= nil then
				optionType:_onMap(option, optionName)
			end

			if option.subOptions then
				handleGroup(option.subOptions, string.format("%s.", optionName))
			end
		end
	end

	for _, columnGroup in ipairs(self.options) do
		handleGroup(columnGroup, "")
	end
end

function EEex_Options_Private_LayoutOptionsPanel:_buildLayout()

	local normalStyle = styles.normal
	local normalFont  = normalStyle.font
	local normalPoint = normalStyle.point

	local maxRowIndex = 0

	for columnGroupIndex, columnGroup in ipairs(self.options) do

		local rowIndex = 1

		local handleGroup
		handleGroup = function(group, layer)

			for _, option in ipairs(group) do

				if rowIndex > maxRowIndex then
					maxRowIndex = rowIndex
				end

				local xOffset = layer * self.layerIndent

				local optionLabel = EEex_Options_Private_LayoutText.new({
					["menuName"] = self.menuName,
					["font"]     = normalFont,
					["point"]    = normalPoint,
					["text"]     = option.name,
				})
				:inset({ ["insetLeft"] = xOffset })

				local labelColumnIndex  = columnGroupIndex * 2 - 1
				local widgetColumnIndex = labelColumnIndex + 1

				if columnGroupIndex ~= 1 then
					self:setColumnPad(labelColumnIndex, self.columnGap)
				end

				self:setCell(labelColumnIndex, rowIndex, optionLabel, EEex_Options_Private_LayoutGrid_Align.CENTER_LEFT)
				self:setColumnPad(widgetColumnIndex, self.widgetGap)

				local optionType = option.type
				local widgetLayout = optionType ~= nil and optionType:_buildLayout(option, self.menuName) or nil
				if widgetLayout ~= nil then
					self:setCell(widgetColumnIndex, rowIndex, widgetLayout, EEex_Options_Private_LayoutGrid_Align.CENTER_LEFT)
				end

				rowIndex = rowIndex + 1

				if option.subOptions then
					handleGroup(option.subOptions, layer + 1)
				end
			end
		end
		handleGroup(columnGroup, 0)
	end

	for rowIndex = 2, maxRowIndex do
		self:setRowPad(rowIndex, self.rowGap)
	end
end

function EEex_Options_Private_LayoutOptionsPanel:_onShow()

	local handleGroup
	handleGroup = function(group)

		for _, option in ipairs(group) do

			if not option.deferTo then
				option.old = option:get()
			end

			local optionType = option.type
			if optionType ~= nil then
				optionType:_onShow(option)
			end

			if option.subOptions then
				handleGroup(option.subOptions)
			end
		end
	end

	for _, columnGroup in ipairs(self.options) do
		handleGroup(columnGroup)
	end
end

function EEex_Options_Private_LayoutOptionsPanel:_writeNewValues()

	local handleGroup
	handleGroup = function(group)

		for _, option in ipairs(group) do

			if not option.deferTo then
				option:write()
				if option.onChange and option:get() ~= option.old then
					option:onChange()
				end
			end

			if option.subOptions then
				handleGroup(option.subOptions)
			end
		end
	end

	for _, columnGroup in ipairs(self.options) do
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
	local option = instanceData.option
	local optionType = option.type

	if optionType.number then
		if letter_pressed ~= "-" and tonumber(letter_pressed) == nil then
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

function EEex_Options_Private_ToggleAction(option)

	local optionType = option.type
	local newToggleState = not optionType.toggleState

	if not newToggleState and optionType.disallowToggleOff then
		return
	end

	optionType.toggleState = newToggleState

	local forceOthers = optionType.forceOthers

	if forceOthers then

		for _, forceEntry in ipairs(forceOthers[optionType.toggleState] or {}) do

			local forceOption = EEex_Options_Private_OptionsMap[forceEntry[1]]
			local forceOptionType = forceOption.type
			local newForceToggleState = forceEntry[2]

			if type(newForceToggleState) == "function" then
				newForceToggleState = newForceToggleState()
			end

			if newForceToggleState ~= nil then

				forceOptionType.toggleState = newForceToggleState

				if newForceToggleState or not forceOptionType.disallowToggleOff then
					local mainForceOption = forceOption.deferTo and EEex_Options_Private_OptionsMap[forceOption.deferTo] or forceOption
					local newForceVal = newForceToggleState and forceOptionType.toggleValue or 0
					mainForceOption:set(newForceVal)
				end
			end
		end
	end

	local mainOption = option.deferTo and EEex_Options_Private_OptionsMap[option.deferTo] or option
	local newVal = newToggleState and optionType.toggleValue or 0
	mainOption:set(newVal)
end

function EEex_Options_Private_TEMPLATE_Toggle_Action()

	local option = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Toggle"][instanceId].option

	local doToggle = function()
		EEex_Options_Private_ToggleAction(option)
	end

	local toggleWarning = option.type.toggleWarning
	if toggleWarning == nil or not toggleWarning(doToggle) then
		doToggle()
	end
end

function EEex_Options_Private_TEMPLATE_Toggle_Frame()
	local optionType = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Toggle"][instanceId].option.type
	return optionType.toggleState and 2 or 0
end

------------
-- Public --
------------

function EEex_Options_Private_LayoutOptionsPanel:doLayout()
	EEex_Menu_DestroyAllTemplates(self.menuName)
	EEex_Utility_CallSuper(EEex_Options_Private_LayoutOptionsPanel, "doLayout", self)
end

function EEex_Options_Private_LayoutOptionsPanel:show()
	self:_onShow()
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
	if self.id       == nil then EEex_Error("id required")       end
	if self.name     == nil then EEex_Error("name required")     end
	if self.default  == nil then EEex_Error("default required")  end
	if self.accessor == nil then EEex_Error("accessor required") end
	-- Optional
	--   self.storage
end

------------
-- Public --
------------

function EEex_Options_Option:getDefault()
	return self.default
end

function EEex_Options_Option:get()
	return self.accessor:get(self)
end

function EEex_Options_Option:set(newValue)
	return self.accessor:set(self, newValue ~= nil and newValue or self.default)
end

function EEex_Options_Option:read()
	local storage = self.storage
	if storage == nil then return end
	return storage:read(self)
end

function EEex_Options_Option:write()
	local storage = self.storage
	if storage == nil then return end
	return storage:write(self)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Option  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_GlobalAccessor  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_GlobalAccessor = {}
EEex_Options_GlobalAccessor.__index = EEex_Options_GlobalAccessor
--setmetatable(EEex_Options_GlobalAccessor, )
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

function EEex_Options_GlobalAccessor:get(option, newValue)
	return _G[self.name]
end

function EEex_Options_GlobalAccessor:set(option, newValue)
	_G[self.name] = newValue
	return newValue
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_GlobalAccessor  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_ClampedAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_ClampedAccessor = {}
EEex_Options_ClampedAccessor.__index = EEex_Options_ClampedAccessor
--setmetatable(EEex_Options_ClampedAccessor, )
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
	if self.accessor == nil then EEex_Error("accessor required") end
	-- Optional
	--   self.min
	--   self.max
end

------------
-- Public --
------------

function EEex_Options_ClampedAccessor:get(option)
	return self.accessor:get()
end

function EEex_Options_ClampedAccessor:set(option, newValue)

	local min = self.min
	if min ~= nil and newValue < min then
		newValue = min
	end

	local max = self.max
	if max ~= nil and newValue > max then
		newValue = max
	end

	return self.accessor:set(option, newValue)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_ClampedAccessor ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_Private_INIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_Private_INIStorage = {}
EEex_Options_Private_INIStorage.__index = EEex_Options_Private_INIStorage
--setmetatable(EEex_Options_Private_INIStorage, )
--print("EEex_Options_Private_INIStorage: "..tostring(EEex_Options_Private_INIStorage))

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_Private_INIStorage:_init()
	EEex_Utility_CallSuper(EEex_Options_Private_INIStorage, "_init", self)
	if self.section == nil then EEex_Error("section required") end
	if self.key     == nil then EEex_Error("key required")     end
end

------------
-- Public --
------------

function EEex_Options_Private_INIStorage:write(option)
	Infinity_SetINIValue(self.section, self.key, option:get())
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_Private_INIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_IntegerINIStorage ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_IntegerINIStorage = {}
EEex_Options_IntegerINIStorage.__index = EEex_Options_IntegerINIStorage
setmetatable(EEex_Options_IntegerINIStorage, EEex_Options_Private_INIStorage)
--print("EEex_Options_IntegerINIStorage: "..tostring(EEex_Options_IntegerINIStorage))

--////////////
--// Static //
--////////////

EEex_Options_IntegerINIStorage.new = function(o)
	if o == nil then o = {} end
	setmetatable(o, EEex_Options_IntegerINIStorage)
	o:_init()
	return o
end

--//////////////
--// Instance //
--//////////////

------------
-- Public --
------------

function EEex_Options_IntegerINIStorage:read(option)
	option:set(Infinity_GetINIValue(self.section, self.key, option:getDefault()))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_IntegerINIStorage ==
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
	option:set(Infinity_GetINIString(self.section, self.key, option:getDefault()))
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_StringINIStorage  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_OptionType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_OptionType = {}
EEex_Options_OptionType.__index = EEex_Options_OptionType
--setmetatable(EEex_Options_OptionType, )
--print("EEex_Options_OptionType: "..tostring(EEex_Options_OptionType))

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_OptionType:_onMap(option, optionName)
	-- Empty stub
end

function EEex_Options_OptionType:_buildLayout(option, menuName)
	-- Empty stub
end

function EEex_Options_OptionType:_onShow(option)
	-- Empty stub
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_OptionType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_ToggleType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_ToggleType = {}
EEex_Options_ToggleType.__index = EEex_Options_ToggleType
setmetatable(EEex_Options_ToggleType, EEex_Options_OptionType)
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

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_ToggleType:_init()
	EEex_Utility_CallSuper(EEex_Options_ToggleType, "_init", self)
	if self.disallowToggleOff == nil then self.disallowToggleOff = false end
	if self.forceOthers       == nil then self.forceOthers       = {}    end
	if self.toggleValue       == nil then self.toggleValue       = 1     end
	-- Optional
	--   self.toggleState
	--   self.toggleWarning
end

function EEex_Options_ToggleType:_buildLayout(option, menuName)
	return EEex_Options_Private_LayoutToggle.new({
		["menuName"] = menuName,
		["option"]   = option,
	})
end

function EEex_Options_ToggleType:_onShow(option)
	local optionType = option.type
	local mainOption = option.deferTo and EEex_Options_Private_OptionsMap[option.deferTo] or option
	optionType.toggleState = mainOption:get() == optionType.toggleValue
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_ToggleType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- START EEex_Options_EditType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

EEex_Options_EditType = {}
EEex_Options_EditType.__index = EEex_Options_EditType
setmetatable(EEex_Options_EditType, EEex_Options_OptionType)
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

--//////////////
--// Instance //
--//////////////

-------------
-- Private --
-------------

function EEex_Options_EditType:_init()
	EEex_Utility_CallSuper(EEex_Options_EditType, "_init", self)
	if self.maxCharacters == nil then EEex_Error("maxCharacters required") end
	if self.number        == nil then self.number = false                  end
	-- Derived
	--   self._editVar
end

function EEex_Options_EditType:_onMap(option, optionName)
	self._editVar = "EEex_Options_Private_"..optionName:gsub("%.", "_").."_EditVar"
end

function EEex_Options_EditType:_buildLayout(option, menuName)
	local normalStyle = styles.normal
	return EEex_Options_Private_LayoutEdit.new({
		["menuName"] = menuName,
		["font"]     = normalStyle.font,
		["point"]    = normalStyle.point,
		["option"]   = option,
	})
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==
-- END EEex_Options_EditType  ==
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-==

--===========
-- Globals ==
--===========

EEex_Options_Private_CapturedEdit            = nil -- uiItem
EEex_Options_Private_MainInset               = nil -- EEex_Options_Private_LayoutInset
EEex_Options_Private_MainVerticalTabArea     = nil -- EEex_Options_Private_LayoutVerticalTabArea
EEex_Options_Private_OptionsMap              = {}
EEex_Options_Private_TabInsertIndex          = 1
EEex_Options_Private_Tabs                    = {}
EEex_Options_Private_TemplateInstancesByName = {}

--===========
-- Utility ==
--===========

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

function EEex_Options_Private_CreateEdit(menuName, option, x, y, w, h)

	local optionType = option.type

	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_Edit", x, y, w, h)
	instanceData.option = option

	local editUD = instanceData.uiItem.edit
	editUD.var:pointTo(EEex_WriteStringCache(optionType._editVar))
	if optionType.maxCharacters then editUD.maxchars = optionType.maxCharacters + 1 end

	_G[optionType._editVar] = tostring(option:get())
end

function EEex_Options_Private_CreateSeparator(menuName, color, x, y, w, h)
	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_Separator", x, y, w, h)
	instanceData.color = color or 0x406F6F70
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
end

function EEex_Options_Private_CreateToggle(menuName, option, x, y, w, h)
	local instanceData = EEex_Options_Private_CreateInstance(menuName, "EEex_Options_TEMPLATE_Toggle", x, y, w, h)
	instanceData.option = option
end

--=============
-- Functions ==
--=============

function EEex_Options_Private_ReadOptions()
	for _, option in pairs(EEex_Options_Private_OptionsMap) do
		if not option.deferTo then
			EEex_Utility_CallIfExists(option.read, option)
		end
	end
end

function EEex_Options_Private_SetEditOption(option)

	local optionType = option.type
	local strVal = _G[optionType._editVar]

	if optionType.number then
		local setVal = option:set(tonumber(strVal))
		strVal = tostring(setVal)
	else
		strVal = strVal:gsub("^%s+", "")
		strVal = strVal:gsub("%s+$", "")
		option:set(strVal)
	end

	_G[optionType._editVar] = strVal
end

function EEex_Options_Private_CheckSetCapturedEditValue()
	if EEex_Options_Private_CapturedEdit == nil then return end
	local instanceData = EEex_Options_Private_TemplateInstancesByName["EEex_Options_TEMPLATE_Edit"][EEex_Options_Private_CapturedEdit.instanceId]
	EEex_Options_Private_SetEditOption(instanceData.option)
end

function EEex_Options_Private_CheckEditUnfocused()

	local captured = EngineGlobals.capture.item
	local editCaptured = false

	if captured ~= nil and captured.templateName:get() == "EEex_Options_TEMPLATE_Edit" then
		if EEex_Options_Private_CapturedEdit ~= nil and EEex_UDEqual(EEex_Options_Private_CapturedEdit, captured) then
			-- Same edit instance as last time
			return
		end
		editCaptured = true
	end

	EEex_Options_Private_CheckSetCapturedEditValue()
	EEex_Options_Private_CapturedEdit = editCaptured and captured or nil
end

function EEex_Options_Private_Tick()
	EEex_Options_Private_CheckEditUnfocused()
	return true
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
			EEex_Options_Private_LayoutText.new({
				["menuName"]        = "EEex_Options",
				["font"]            = styles.normal.font,
				["point"]           = 16,
				["horizontalAlign"] = EEex_Options_Private_LayoutText_HorizontalAlign.CENTER,
				["text"]            = "EEex Options",
			}),
			EEex_Options_Private_LayoutFixed.new({ ["height"] = 7 }),
			EEex_Options_Private_LayoutSeparator.new({ ["menuName"] = "EEex_Options", ["height"] = 2 }),
			EEex_Options_Private_MainVerticalTabArea,
		},
	})
	:inset({ ["insetLeft"] = 10, ["insetTop"] = 10, ["insetRight"] = 10, ["insetBottom"] = 10 })
end

function EEex_Options_Private_TopRightAlign(itemName, x, y)
	local _, _, w, h = Infinity_GetArea(itemName)
	Infinity_SetArea(itemName, x - w, y, nil, nil)
end

function EEex_Options_Private_Layout()

	-- Reset top level instances
	EEex_Menu_DestroyAllTemplates("EEex_Options")

	local screenWidth, screenHeight = Infinity_GetScreenSize()

	-- Calculate the layout
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

	-- Move the exit button
	EEex_Options_Private_TopRightAlign("EEex_Options_Exit", screenWidth, 0)
end

function EEex_Options_Open()
	if Infinity_IsMenuOnStack("EEex_Options") then return end
	EEex_Options_Private_Layout()
	EEex_Options_Private_MainInset:show()
	Infinity_PushMenu("EEex_Options")
end

function EEex_Options_Close()
	if not Infinity_IsMenuOnStack("EEex_Options") then return end
	Infinity_PopMenu("EEex_Options")
	EEex_Options_Private_CheckSetCapturedEditValue()
	EEex_Options_Private_CapturedEdit = nil
	EEex_Options_Private_MainInset:hide()
end

function EEex_Options_AddTab(text, options)

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

	EEex_Options_Private_Tabs[EEex_Options_Private_TabInsertIndex] = {
		["name"] = text,
		["layout"] = EEex_Options_Private_LayoutOptionsPanel.new({
			["menuName"] = menuName,
			["options"] = options,
		})
		:inset({ ["insetTop"] = 5, ["insetRight"] = 5, ["insetBottom"] = 5 }),
	}

	EEex_Options_Private_TabInsertIndex = EEex_Options_Private_TabInsertIndex + 1
	EEex_Utility_AlphanumericSortTable(EEex_Options_Private_Tabs, function(t) return t.name end)
end

--=============
-- Listeners ==
--=============

EEex_Menu_AddMainFileLoadedListener(function()
	EEex_Menu_LoadFile("X-Option")
end)

EEex_Key_AddPressedListener(function(key)
	if key == EEex_Key_GetFromName("\\") then
		EEex_Options_Open()
	end
end)

EEex_Menu_AddWindowSizeChangedListener(function()
	if not Infinity_IsMenuOnStack("EEex_Options") then return end
	EEex_Options_Private_Layout()
end)

-- Hardcoded call from EEex_GameState.lua
function EEex_Options_OnAfterGameStateInitialized()
	EEex_Options_Private_BuildLayout()
	EEex_Options_Private_ReadOptions()
end
