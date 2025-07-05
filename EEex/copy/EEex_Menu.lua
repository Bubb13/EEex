
-----------------------
-- General Functions --
-----------------------

function EEex_Menu_TranslateXYFromGame(gameX, gameY)

	local game = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame
	local curArea = game.m_gameAreas:get(game.m_visibleArea)
	local infinity = curArea.m_cInfinity

	local viewPort = infinity.rViewPort
	local viewportX = infinity.nNewX - viewPort.left
	local viewportY = infinity.nNewY - viewPort.top

	local realX = gameX - viewportX
	local realY = gameY - viewportY

	local screenWidth, screenHeight = Infinity_GetScreenSize()
	local uiX = math.floor(screenWidth * (realX / viewPort.right) + 0.5)
	local uiY = math.floor(screenHeight * (realY / viewPort.bottom) + 0.5)
	return uiX, uiY
end

function EEex_Menu_GetMousePos()
	local cMousePosition = EEex_EngineGlobal_CBaldurChitin.cMousePosition
	return cMousePosition.x, cMousePosition.y
end

function EEex_Menu_IsCursorWithinRect(x, y, width, height)
	local mouseX, mouseY = EEex_Menu_GetMousePos()
	return mouseX >= x and mouseX <= (x + width)
	   and mouseY >= y and mouseY <= (y + height)
end

function EEex_Menu_GetUIMenuArea(menu)

	if not menu then return end

	local screenW, screenH = Infinity_GetScreenSize()

	local ha = menu.ha
	local va = menu.va

	local w = menu.width
	local h = menu.height

	local returnX = 0
	local returnY = 0

	-- right
	if ha == 1 then
		returnX = screenW - w
	-- center
	elseif ha == 2 then
		-- The negative case is nonsensical, but that's how the assembly works.
		local windowW = screenW >= 0 and screenW or screenW + 1
		local menuW = w >= 0 and w or w + 1
		returnX = windowW / 2 - menuW / 2
	end

	-- bottom
	if va == 1 then
		returnY = screenH - h
	-- center
	elseif va == 2 then
		local windowH = screenH >= 0 and screenH or screenH + 1
		local menuH = h >= 0 and h or h + 1
		returnY = windowH / 2 - menuH / 2
	end

	return returnX + menu.offset.x, returnY + menu.offset.y, w, h
end
uiMenu.getArea = EEex_Menu_GetUIMenuArea

-- Returns the given menu's x, y, w, and h components - or nil if passed invalid menuName.
function EEex_Menu_GetArea(menuName)
	return EEex_Menu_GetUIMenuArea(EEex_Menu_Find(menuName))
end

function EEex_Menu_GetUIItemArea(item)
	local menuX, menuY, menuW, menuH = item.menu:getArea()
	local itemArea = item.area
	return menuX + itemArea.x, menuY + itemArea.y, itemArea.w, itemArea.h
end
uiItem.getArea = EEex_Menu_GetUIItemArea

function EEex_Menu_GetItem(menuItemName)
	local lightItem = nameToItem[menuItemName]
	if lightItem == nil then return end
	return EEex_PtrToUD(EEex_LightUDToPtr(lightItem), "uiItem")
end

function EEex_Menu_GetItemArea(menuItemName)
	local item = EEex_Menu_GetItem(menuItemName)
	if item == nil then return end
	return item:getArea()
end

function EEex_Menu_IsCursorWithin(menuName, menuItemName)
	local menuX, menuY, menuW, menuH = EEex_Menu_GetArea(menuName)
	local itemX, itemY, itemWidth, itemHeight = Infinity_GetArea(menuItemName)
	return EEex_Menu_IsCursorWithinRect(menuX + itemX, menuY + itemY, itemWidth, itemHeight)
end

function EEex_Menu_Find(menuName, panel, state)
	return EngineGlobals.findMenu(menuName, panel or 0, state or 0)
end

function EEex_Menu_GetItemFunction(funcRef)
	local regIndex = funcRef.value
	return regIndex ~= 0 and EEex_GetLuaRegistryIndex(regIndex) or nil
end

function EEex_Menu_SetItemFunction(funcRef, func)
	local regIndex = funcRef.value
	if regIndex == 0 then
		funcRef.value = EEex_AddToLuaRegistry(func)
	else
		EEex_SetLuaRegistryIndex(regIndex, func)
	end
end

function EEex_Menu_GetItemVariant(variant)
	if variant.type == uiVariantType.UIVAR_INT then
		return variant.value.intVal
	elseif variant.type == uiVariantType.UIVAR_FUNCTION then
		return EEex_GetLuaRegistryIndex(variant.value.luaFunc)
	elseif variant.type == uiVariantType.UIVAR_STRING then
		return variant.value.strVal
	elseif variant.type == uiVariantType.UIVAR_FLOAT then
		return variant.value.floatVal
	else
		EEex_Error("Unhandled Type")
	end
end
uiVariant.getValue = EEex_Menu_GetItemVariant

function EEex_Menu_SetItemVariant(variantRefPtr, myVal)

	variant = variantRefPtr.reference
	if not variant then
		variant = EEex_PtrToUD(EEex_Malloc(uiVariant.sizeof), "uiVariant")
		variantRefPtr.reference = variant
	end

	local myValType = type(myVal)
	if myValType == "number" then
		if myVal == math.floor(myVal) then
			variant.type = uiVariantType.UIVAR_INT
			variant.value.intVal = myVal
		else
			variant.type = uiVariantType.UIVAR_FLOAT
			variant.value.floatVal = myVal
		end
	elseif myValType == "function" then
		if variant.type == uiVariantType.UIVAR_FUNCTION then
			EEex_SetLuaRegistryIndex(variant.value.luaFunc, myVal)
		else
			variant.type = uiVariantType.UIVAR_FUNCTION
			variant.value.luaFunc = EEex_AddToLuaRegistry(myVal)
		end
	elseif myValType == "string" then
		if variant.type == uiVariantType.UIVAR_STRING then
			variant.value.strVal:free()
		end
		variant.type = uiVariantType.UIVAR_STRING
		variant.value.strVal:set(myVal)
	else
		EEex_Error("Bad Type")
	end
end
uiVariant.setValue = EEex_Menu_SetItemVariant

function EEex_Menu_Private_LoadRes(res)
	EngineGlobals.saveMenuStack()
	EEex_MemsetUD(EngineGlobals.menuStack, 0x0, EngineGlobals.menuStack.sizeof)
	EngineGlobals.nextStackMenuIdx = 0
	local menuSrc = EngineGlobals.menuSrc
	local menuLength = EngineGlobals.menuLength
	EngineGlobals.uiLoadMenu(res)
	EngineGlobals.menuSrc = menuSrc
	EngineGlobals.menuLength = menuLength
	EngineGlobals.restoreMenuStack()
end

function EEex_Menu_LoadFile(resref)
	EEex_Menu_Private_LoadRes(EEex_Resource_Fetch(resref, "MENU"))
end

function EEex_Menu_Eval(str)

	local res
	EEex_RunWithStack(CResRef.sizeof, function(stackMem)
		local resrefUD = EEex_PtrToUD(stackMem, "CResRef")
		resrefUD:set("X-TEMP")
		res = EngineGlobals.dimmGetResObject(resrefUD, EEex_Resource_ExtToType("MENU"), true)
	end)

	EEex_RunWithString(str, function(strMem)
		EngineGlobals.dimmServiceFromMemory(res, EEex_PtrToUD(strMem, "VariableArray<char>"), #str + 1, false, true)
	end)

	EEex_Menu_Private_LoadRes(res)
	EngineGlobals.dimmDump(res)
end

-- Exactly the same as Infinity_InstanceAnimation(), but allows said instance to be "injected" into the menu specified.
function EEex_Menu_InjectTemplate(menuName, templateName, x, y, w, h)
	EEex_Menu_HookGlobal_TemplateMenuOverride = EEex_Menu_Find(menuName)
	Infinity_InstanceAnimation(templateName, nil, x, y, w, h, nil, nil)
	EEex_Menu_HookGlobal_TemplateMenuOverride = nil
end

-- Destroys an instance injected into a menu via EEex_InjectTemplate().
function EEex_Menu_DestroyInjectedTemplate(menuName, templateName, instanceId)
	EEex_Menu_HookGlobal_TemplateMenuOverride = EEex_Menu_Find(menuName)
	Infinity_DestroyAnimation(templateName, instanceId)
	EEex_Menu_HookGlobal_TemplateMenuOverride = nil
end

-- A saner Infinity_InstanceAnimation()
function EEex_Menu_InjectTemplateInstance(menuName, templateName, instanceId, x, y, w, h)
	return EEex.InjectTemplateInstance(menuName, templateName, instanceId, x, y, w, h)
end

function EEex_Menu_DestroyAllTemplates(menuName)
	EEex.DestroyAllTemplates(menuName)
end

function EEex_Menu_StoreTemplateInstance(menuName, templateName, instanceID, storeIntoName)
	local menu = EEex_Menu_Find(menuName)
	if not menu then return end
	local item = menu.items
	while item do
		if item.templateName:get() == templateName and item.instanceId == instanceID then
			nameToItem[storeIntoName] = EEex_UDToLightUD(item)
		end
		item = item.next
	end
end

function EEex_Menu_SetTemplateArea(menuName, templateName, instanceID, x, y, w, h)
	EEex_Menu_StoreTemplateInstance(menuName, templateName, instanceID, "EEex_Menu_StoredTemplate")
	Infinity_SetArea("EEex_Menu_StoredTemplate", x, y, w, h)
end

EEex_Menu_NativeMap = {}

function EEex_Menu_IsNative(menuName)
	return EEex_Menu_NativeMap[menuName] ~= nil
end

EEex_Menu_ScrollbarForced = {}

function EEex_Menu_SetForceScrollbarRender(itemName, value)
	EEex_Menu_ScrollbarForced[itemName] = value
end

---------------
-- Listeners --
---------------

EEex_Menu_MainFileLoadedListeners = {}

-- Given listener function is called after initial UI.MENU load and when an F5 UI reload is executed.
function EEex_Menu_AddMainFileLoadedListener(listener)
	table.insert(EEex_Menu_MainFileLoadedListeners, listener)
end

EEex_Menu_BeforeMainFileReloadedListeners = {}

-- Given listener function is called before an F5 UI reload is executed.
function EEex_Menu_AddBeforeMainFileReloadedListener(listener)
	table.insert(EEex_Menu_BeforeMainFileReloadedListeners, listener)
end

EEex_Menu_AfterMainFileReloadedListeners = {}

-- Given listener function is called after an F5 UI reload is executed.
function EEex_Menu_AddAfterMainFileReloadedListener(listener)
	table.insert(EEex_Menu_AfterMainFileReloadedListeners, listener)
end

EEex_Menu_BeforeListRendersItemListeners = {}

-- Given listener function is called before a list renders an item.
function EEex_Menu_AddBeforeListRendersItemListener(listName, listener)
	local listListeners = EEex_Utility_GetOrCreateTable(EEex_Menu_BeforeListRendersItemListeners, listName)
	table.insert(listListeners, listener)
end

EEex_Menu_BeforeUIItemRenderListeners = {}

function EEex_Menu_AddBeforeUIItemRenderListener(itemName, listener)
	EEex_Menu_BeforeUIItemRenderListeners[itemName] = listener
end

EEex_Menu_WindowSizeChangedListeners = {}

function EEex_Menu_AddWindowSizeChangedListener(listener)
	table.insert(EEex_Menu_WindowSizeChangedListeners, listener)
end

-----------
-- Hooks --
-----------

EEex_Menu_HookGlobal_TemplateMenuOverride = nil

-- Note: uiItem.menu is NOT valid in this function!
-- The parent function that contains this hook has temporarily rearranged
-- the menu array, making uiItem.menu reference the wrong menu.
function EEex_Menu_Hook_CheckSaveMenuItem(menu, item)
	return EEex_Menu_IsNative(menu.name:get())
end

function EEex_Menu_Hook_AfterMainFileLoaded()

	local numMenus = EngineGlobals.numMenus
	local menus = EngineGlobals.menus

	for i = 0, numMenus - 1 do
		local menu = menus:getReference(i)
		EEex_Menu_NativeMap[menu.name:get()] = true
	end

	for i, listener in ipairs(EEex_Menu_MainFileLoadedListeners) do
		listener()
	end
end

function EEex_Menu_Hook_BeforeMenuStackSave()
	for i, listener in ipairs(EEex_Menu_BeforeMainFileReloadedListeners) do
		listener()
	end
end

function EEex_Menu_Hook_AfterMenuStackRestore()
	for i, listener in ipairs(EEex_Menu_MainFileLoadedListeners) do
		listener()
	end
	for i, listener in ipairs(EEex_Menu_AfterMainFileReloadedListeners) do
		listener()
	end
end

function EEex_Menu_Hook_BeforeListRenderingItem(list, item, window, rClipBase, alpha, menu)
	local listName = list.name:get()
	if listName ~= "" then
		local listeners = EEex_Menu_BeforeListRendersItemListeners[listName]
		if listeners then
			for _, listener in ipairs(listeners) do
				listener(list, item, window, rClipBase, alpha, menu)
			end
		end
	end
end

function EEex_Menu_Hook_CheckForceScrollbarRender(item)
	local itemName = item.name:get()
	return itemName ~= "" and EEex_Menu_ScrollbarForced[itemName]
end

function EEex_Menu_Hook_OnBeforeUIItemRender(item)
	local listener = EEex_Menu_BeforeUIItemRenderListeners[item.name:get()]
	if listener then
		listener(item)
	end
end

function EEex_Menu_Hook_OnWindowSizeChanged()

	local sdlWindow = EngineGlobals.g_pBaldurChitin.cVideo.pCurrentMode.m_pWindow
	local sdlWindowFlags = EngineGlobals.SDL_GetWindowFlags(sdlWindow)

	-- Ignore size change caused by fullscreen window being minimized.
	-- This reports the non-fullscreen window size, which never actually
	-- goes into effect, as opening the window again reenters fullscreen.
	if EEex_IsMaskSet(sdlWindowFlags, SDL_WindowFlags.SDL_WINDOW_FULLSCREEN)
		and EEex_IsMaskSet(sdlWindowFlags, SDL_WindowFlags.SDL_WINDOW_MINIMIZED)
	then
		return
	end

	if EEex_Modules["B3Scale"] then
		B3Scale_DoSizeChange()
	end

	local width = CVidMode.SCREENWIDTH
	local height = CVidMode.SCREENHEIGHT

	for _, listener in ipairs(EEex_Menu_WindowSizeChangedListeners) do
		listener(width, height)
	end
end

function EEex_Menu_Hook_SaveInstanceId(item)
	instanceId = item.instanceId
end
