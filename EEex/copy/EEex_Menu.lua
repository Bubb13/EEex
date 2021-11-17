
-----------------------
-- General Functions --
-----------------------

function EEex_Menu_Find(menuName, panel, state)
	return EngineGlobals.findMenu(menuName, panel or 0, state or 0)
end

function EEex_Menu_GetItemFunction(funcRefPtr, func)
	local regIndex = funcRefPtr:getValue()
	return regIndex ~= 0 and EEex_GetLuaRegistryIndex(regIndex) or nil
end

function EEex_Menu_SetItemFunction(funcRefPtr, func)
	local regIndex = funcRefPtr:getValue()
	if regIndex == 0 then
		funcRefPtr:setValue(EEex_AddToLuaRegistry(func))
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

function EEex_Menu_SetItemVariant(variantRefPtr, myVal)

	variant = variantRefPtr:getValue()
	if not variant then
		variant = EEex_PtrToUD(EEex_Malloc(uiVariant.sizeof), "uiVariant")
		variantRefPtr:setValue(variant)
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

function EEex_Menu_LoadFile(resref)
	EngineGlobals.saveMenuStack()
	EEex_MemsetUD(EngineGlobals.menuStack, 0x0, EngineGlobals.menuStack.sizeof)
	EngineGlobals.nextStackMenuIdx = 0
	local menuSrc = EngineGlobals.menuSrc
	local menuLength = EngineGlobals.menuLength
	EngineGlobals.uiLoadMenu(EEex_Resource_Fetch(resref, "MENU"))
	EngineGlobals.menuSrc = menuSrc
	EngineGlobals.menuLength = menuLength
	EngineGlobals.restoreMenuStack()
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

EEex_Menu_NativeMap = {}

function EEex_Menu_IsNative(menuName)
	return EEex_Menu_NativeMap[menuName] ~= nil
end

---------------
-- Listeners --
---------------

EEex_Menu_LuaBindingsInitializedListener = {}

-- Given listener function is called after the engine initializes its lua bindings, (C globals and functions).
-- Surprisingly, it does this well after it loads UI.MENU, making this listener required.
function EEex_Menu_AddLuaBindingsInitializedListener(listener)
	table.insert(EEex_Menu_LuaBindingsInitializedListener, listener)
end

EEex_Menu_MainFileLoadedListeners = {}

-- Given listener function is called after initial UI.MENU load and when an F5 UI reload is executed.
function EEex_Menu_AddMainFileLoadedListener(listener)
	table.insert(EEex_Menu_MainFileLoadedListeners, listener)
end

EEex_Menu_BeforeMainFileReloadedListeners = {}

-- Given listener function is called before an F5 UI reload is executed.
function EEex_Menu_AddBeforeMainFileReloadedListener()
	table.insert(EEex_Menu_BeforeMainFileReloadedListeners, listener)
end

EEex_Menu_AfterMainFileReloadedListeners = {}

-- Given listener function is called after an F5 UI reload is executed.
function EEex_Menu_AddAfterMainFileReloadedListener(listener)
	table.insert(EEex_Menu_AfterMainFileReloadedListeners, listener)
end

-----------
-- Hooks --
-----------

EEex_Menu_HookGlobal_TemplateMenuOverride = nil

function EEex_Menu_Hook_AfterLuaBindingsInitialized()
	for i, listener in ipairs(EEex_Menu_LuaBindingsInitializedListener) do
		listener()
	end
end

function EEex_Menu_Hook_CheckSaveMenuItem(uiItemPtr)
	local uiItem = EEex_PtrToUD(uiItemPtr, "uiItem")
	local menuName = uiItem.menu.name
	return EEex_Menu_IsNative(menuName)
end

function EEex_Menu_Hook_AfterMainFileLoaded()

	local numMenus = EngineGlobals.numMenus
	local menus = EngineGlobals.menus

	for i = 0, numMenus - 1 do
		local menu = menus:getReference(i)
		EEex_Menu_NativeMap[menu.name] = true
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
