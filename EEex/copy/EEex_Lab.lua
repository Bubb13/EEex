--[[

Defines all labels used by EEex. Labels are a textual representation of a memory address;
all EEex functions should be defined in terms of labels, and not the raw memory addresses.
This enables most code in M__EEex.lua to be independent from the system environment. This file
needs to be updated in order to maintain compatibility with other games / versions / platforms.

EEex_WriteAssembly support =>
1. >label = Relative write to label
2. *label = Absolute write of label

EEex_Label(label) => Returns the memory address that is behind the label string.
                     If the given label is not defined, a Lua error will be thrown.
                     The side effects of an undefined label will, most likely,
                     result in a terminal program crash. If the program continues,
                     it has entered undefined behavior and WILL break at some point.

--]]

if not EEex_MinimalStartup then
	for _, labelEntry in ipairs({
		{"(CString)_operator+", 0x7791B0},
		{"aB_1", 0x927BD8},
		{"CAIAction::Decode", 0x4FCF90},
		{"CAIObjectType::ANYONE", 0x9372E8},
		{"CAIObjectType::Decode", 0x501750},
		{"CAIObjectType::operator=", 0x4FDA50},
		{"CAIScript::CAIScript", 0x503D10},
		{"CChitin::GetVersionString()_versionStringPush", 0x7902D7},
		{"CChitin::TIMER_UPDATES_PER_SECOND", 0x938778},
		{"CDerivedStats::GetAtOffset", 0x52CC40},
		{"CDerivedStats::GetSpellState", 0x52DF30},
		{"CDerivedStats::operator=", 0x52A3A0},
		{"CDerivedStats::Reload", 0x52E3A0},
		{"CGameAIBase::FireSpellPoint", 0x542FC0},
		{"CGameEffect::CGameEffect", 0x56AAB0},
		{"CGameEffect::CopyFromBase", 0x5A0180},
		{"CGameEffect::FireSpell", 0x5A73E0},
		{"CGameEffect::GetItemEffect", 0x5A7A30},
		{"CGameObjectArray::GetShare", 0x625C00},
		{"CGameSprite::AddKnownSpell", 0x6D9B40},
		{"CGameSprite::AddKnownSpellMage", 0x6D9DC0},
		{"CGameSprite::GetActiveStats", 0x4FE120},
		{"CGameSprite::GetKit", 0x53A7A0},
		{"CGameSprite::GetName", 0x6E7220},
		{"CGameSprite::GetQuickButtons", 0x6E7720},
		{"CGameSprite::MemorizeSpell", 0x6F1390},
		{"CGameSprite::ReadySpell", 0x6F6840},
		{"CGameSprite::RemoveKnownSpell", 0x6F7D40},
		{"CGameSprite::RemoveKnownSpellMage", 0x6F7E00},
		{"CGameSprite::RemoveKnownSpellPriest", 0x6F7E30},
		{"CGameSprite::SetCharacterToolTip", 0x6FFB80},
		{"CGameSprite::Shatter", 0x703FA0},
		{"CGameSprite::UnmemorizeSpellMage", 0x708370},
		{"CGameSprite::UnmemorizeSpellPriest", 0x7083D0},
		{"CGameSprite::`vftable'", 0x8A86D0},
		{"CGameSprite::~CGameSprite", 0x6D5D90},
		{"CInfButtonArray::SetState", 0x618160},
		{"CInfButtonArray::UpdateButtons", 0x619970},
		{"CInfGame::AddCharacterToAllies", 0x61DF10},
		{"CInfGame::GetCharacterId", 0x5028D0},
		{"CInfinity::DrawLine", 0x6463D0},
		{"CInfinity::DrawRectangle", 0x646530},
		{"CInfinity::RenderAOE", 0x649050},
		{"CObList::RemoveAll", 0x780E50},
		{"CObList::RemoveHead", 0x79A8C0},
		{"CPtrList::RemoveAt", 0x780E80},
		{"CResRef::GetResRefStr", 0x77B1A0},
		{"CResRef::IsValid", 0x77B250},
		{"CResRef::operator!=", 0x77AE20},
		{"CResRef::operator=", 0X77ABE0},
		{"CRuleTables::MapCharacterSpecializationToSchool", 0x6037D0},
		{"CString::~CString", 0x779050},
		{"CStringList::FindIndex", 0x613B40},
		{"dimmGetResObject", 0x77D9A0},
		{"g_pBaldurChitin", 0x93FDBC},
		{"g_pChitin", 0x93FDB8},
		{"operator_new", 0x85BEA7},
		{"_g_lua", 0x94010C},
		{"_lua_getglobal", 0x4B5C10},
		{"_lua_gettop", 0x4B50A0},
		{"_lua_pcallk", 0x4B63F0},
		{"_lua_pushlightuserdata", 0x4B5BF0},
		{"_lua_pushlstring", 0x4B59D0},
		{"_lua_pushnumber", 0x4B5960},
		{"_lua_pushstring", 0x4B5A40},
		{"_lua_rawgeti", 0x4B5D40},
		{"_lua_rawlen", 0x4B57B0},
		{"_lua_settop", 0x4B50C0},
		{"_lua_toboolean", 0x4B56D0},
		{"_lua_tolstring", 0x4B5710},
		{"_lua_tonumberx", 0x4B54D0},
		{"_lua_touserdata", 0x4B5840},
		{"_lua_type", 0x4B5240},
		{"_lua_typename", 0x4B5280},
		{"_memcpy", 0x85B050},
		{"_memset", 0x85B6A0},
		{"_p_malloc", 0x886FD0},
		{"_SDL_free", 0x7BF980},
		{"__ftol2_sse", 0x85C3C0},
		{"__imp__GetProcAddress", 0x8A0200},
		{"__imp__LoadLibraryA", 0x8A01D8},
		{"__mbscmp", 0x85B93B},
	})
	do
		local labelName = labelEntry[1]
		local labelValue = labelEntry[2]
		EEex_DefineAssemblyLabel(labelName, labelValue)
	end
else
	for _, labelEntry in ipairs({
		{"CChitin::GetVersionString()_versionStringPush", 0x7902D7},
		{"_lua_getglobal", 0x4B5C10},
		{"_lua_gettop", 0x4B50A0},
		{"_lua_pcallk", 0x4B63F0},
		{"_lua_pushlightuserdata", 0x4B5BF0},
		{"_lua_pushnumber", 0x4B5960},
		{"_lua_pushstring", 0x4B5A40},
		{"_lua_rawgeti", 0x4B5D40},
		{"_lua_rawlen", 0x4B57B0},
		{"_lua_settop", 0x4B50C0},
		{"_lua_tolstring", 0x4B5710},
		{"_lua_tonumberx", 0x4B54D0},
		{"_lua_touserdata", 0x4B5840},
		{"_memset", 0x85B6A0},
		{"_p_malloc", 0x886FD0},
		{"_SDL_free", 0x7BF980},
		{"__ftol2_sse", 0x85C3C0},
		{"__imp__GetProcAddress", 0x8A0200},
		{"__imp__LoadLibraryA", 0x8A01D8},
	})
	do
		local labelName = labelEntry[1]
		local labelValue = labelEntry[2]
		EEex_DefineAssemblyLabel(labelName, labelValue)
	end
end
