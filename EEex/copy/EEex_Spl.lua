
function EEex_InstallSplHook()

	EEex_DisableCodeProtection()

	local fixEmptyStringNotSkipping = function(label)
		local address = EEex_Label(label)
		local jmpOffset = EEex_ReadByte(address + 1, 0)
		EEex_WriteByte(address + 1, jmpOffset + 18)
	end

	fixEmptyStringNotSkipping("CGameSprite::FeedBack()_DisableCastsHook")
	fixEmptyStringNotSkipping("CGameSprite::FeedBack()_DisableIsCastingHook")

	local getGenericNameOverride = EEex_WriteAssemblyAuto({[[
		!push_esi
		!mov_esi_ecx
		!push_dword *defines
		!lea_ecx_[esi+byte] 04
		!call >CResRef::operator_equequ
		!test_eax_eax
		!jne_dword >invalid
		!mov_ecx_[esi]
		!test_ecx_ecx
		!je_dword >invalid
		!call >CRes::Demand
		!mov_eax_[esi]
		!test_eax_eax
		!je_dword >invalid
		!mov_eax_[eax+byte] 28
		!test_[eax+byte]_dword 18 #80000000
		!je_dword >normal
		!mov_eax_[eax+byte] 0C
		!pop_esi
		!ret
		@normal
		!mov_eax_[eax+byte] 08
		!pop_esi
		!ret
		@invalid
		!or_eax_byte FF
		!pop_esi
		!ret
	]]})

	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook1"), {"!call", {getGenericNameOverride, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook2"), {"!call", {getGenericNameOverride, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook3"), {"!call", {getGenericNameOverride, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook4"), {"!call", {getGenericNameOverride, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook5"), {"!call", {getGenericNameOverride, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook6"), {"!call", {getGenericNameOverride, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook7"), {"!call", {getGenericNameOverride, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SpellFeedbackHook8"), {"!call", {getGenericNameOverride, 4, 4}})

	----------------------------------------------------------------------------
	-- Opcode #214 should respect spells with multiple casts / AoE indicators --
	-- + Add m_itemType = 6 (NoDec variant for player casting)                --
	----------------------------------------------------------------------------

	local checkCastCounterReset = function(address)
		local hook = EEex_WriteAssemblyAuto({[[
			!(word) !cmp_[edi+dword]_byte #3590 06
			!je_dword ]], {address + 0x7, 4, 4}, [[
			!mov_[edi+dword]_ax #3360
			!jmp_dword ]], {address + 0x7, 4, 4}, [[
		]]})
		EEex_WriteAssembly(address, {"!jmp_dword", {hook, 4, 4}, "!nop !nop"})
	end

	-- CGameSprite::ReadyOffInternalList() accepts m_itemType = 6
	local readyOffInternalJump = EEex_Label("CGameSprite::ReadyOffInternalList()_ItemTypeJump")
	local readyOffInternalJumpDest = readyOffInternalJump + EEex_ReadDword(readyOffInternalJump + 0x2) + 0x6
	local readyOffInternalHook = EEex_WriteAssemblyAuto({[[
		!je_dword ]], {readyOffInternalJumpDest, 4, 4}, [[
		!cmp_eax_byte 03
		!je_dword ]], {readyOffInternalJumpDest, 4, 4}, [[
		!jmp_dword ]], {readyOffInternalJump + 0x6, 4, 4},
	})
	EEex_WriteAssembly(readyOffInternalJump, {"!jmp_dword", {readyOffInternalHook, 4, 4}, "!nop"})
	checkCastCounterReset(readyOffInternalJumpDest + 0x9)

	-- Fix spells with multiple casts for m_itemType = 3 and m_itemType = 6
	local genOpcode214CastHook = function(offset1, offset2)

		return function()

			local actorID = EEex_GetActorIDSelected()
			local share = EEex_GetActorShare(actorID)

			local CGameSprite_m_lstTargetIds = share + offset1
			EEex_Call(EEex_Label("CObList::RemoveAll"), {}, CGameSprite_m_lstTargetIds, 0x0)

			local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
			local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
			local CInfGame_m_lstTargetIds = m_pObjectGame + offset2

			local m_pNodeHead = EEex_ReadDword(CInfGame_m_lstTargetIds + 0x4)
			while m_pNodeHead ~= 0x0 do
				local newTarget = EEex_Call(EEex_Label("CObList::RemoveHead"), {}, CInfGame_m_lstTargetIds, 0x0)
				EEex_Call(EEex_Label("CPtrList::AddTail"), {newTarget}, CGameSprite_m_lstTargetIds, 0x0)
				m_pNodeHead = EEex_ReadDword(CInfGame_m_lstTargetIds + 0x4)
			end
		end
	end

	local writeOpcode214CastHook = function(hookName, address)

		local opcode214CastHookNameAddress = EEex_Malloc(#hookName + 1, 35)
		EEex_WriteString(opcode214CastHookNameAddress, hookName)

		local opcode214CastJumpDest = address + EEex_ReadDword(address + 0x1) + 0x5
		local opcode214CastJumpHook = EEex_WriteAssemblyAuto({[[

			!push_dword ]], {opcode214CastHookNameAddress, 4}, [[
			!push_[dword] *_g_lua
			!call >_lua_getglobal
			!add_esp_byte 08
	
			!push_byte 00
			!push_byte 00
			!push_byte 00
			!push_byte 00
			!push_byte 00
			!push_[dword] *_g_lua
			!call >_lua_pcallk
			!add_esp_byte 18
	
			!jmp_dword ]], {opcode214CastJumpDest, 4, 4},
		})
		EEex_WriteAssembly(address, {"!jmp_dword", {opcode214CastJumpHook, 4, 4}})
	end
	B3Spell_Opcode214CastHook = genOpcode214CastHook(0x3998, 0x2520)
	writeOpcode214CastHook("B3Spell_Opcode214CastHook", EEex_Label("CInfGame::UseMagicOnObject()_Opcode214FixHook"))
	B3Spell_Opcode214CastHookGround = genOpcode214CastHook(0x39B4, 0x253C)
	writeOpcode214CastHook("B3Spell_Opcode214CastHookGround", EEex_Label("CInfGame::UseMagicOnGround()_Opcode214FixHook"))

	-- Display AoE for m_itemType = 3 and m_itemType = 6
	local writeOpcode214CastAOEHook = function(address, readOffsetFunc, jmpInstEnd)
		local opcode214CastJumpDest = address + readOffsetFunc(address) + jmpInstEnd
		local opcode214CastJumpHook = EEex_WriteAssemblyAuto({[[
			!(word) !mov_eax_[esi]
			!(word) !cmp_eax_byte 01
			!je_dword ]], {address + jmpInstEnd, 4, 4}, [[
			!(word) !cmp_eax_byte 03
			!je_dword ]], {address + jmpInstEnd, 4, 4}, [[
			!(word) !cmp_eax_byte 06
			!je_dword ]], {address + jmpInstEnd, 4, 4}, [[
			!jmp_dword ]], {opcode214CastJumpDest, 4, 4},
		})
		EEex_WriteAssembly(address, {"!jmp_dword", {opcode214CastJumpHook, 4, 4}})
	end
	writeOpcode214CastAOEHook(EEex_Label("CGameSprite::UpdateAOE()_Opcode214FixHook"), function(address) return EEex_ReadByte(address + 0x4, 0) end, 0x5)
	writeOpcode214CastAOEHook(EEex_Label("CGameSprite::GetAbilityProjectileType()_Opcode214FixHook"), function(address) return EEex_ReadDword(address + 0x2) end, 0x6)

	-- CInfGame::UseMagicOnGround and CInfGame::UseMagicOnObject accept m_itemType = 6
	local hookCastType = function(address)
		local jumpDest = address + EEex_ReadDword(address + 0x2) + 0x6
		local case3 = EEex_ReadDword(EEex_ReadDword(address + 0x9) + 0x4)
		local hook = EEex_WriteAssemblyAuto({[[
			!cmp_eax_byte 04
			!jne_dword ]], {jumpDest, 4, 4}, [[
			!jmp_dword ]], {case3, 4, 4}, [[
		]]})
		EEex_WriteAssembly(address, {"!ja_dword", {hook, 4, 4}})
		checkCastCounterReset(case3 + 0x9)
	end
	hookCastType(EEex_Label("CInfGame::UseMagicOnObject()_ItemTypeJump"))
	hookCastType(EEex_Label("CInfGame::UseMagicOnGround()_ItemTypeJump"))

	------------------
	-- MARKED_SPELL --
	------------------

	local markedSpellOffset = EEex_RegisterVolatileField("EEex_MarkedSpell", {
		["construct"] = function(address)
			EEex_WriteDword(address, EEex_ReadDword(EEex_Label("_afxPchNil")))
		end,
		["destruct"] = function(address)
			EEex_Call(EEex_Label("CString::~CString"), {}, address, 0x0)
		end,
		["get"] = function(address)
			return EEex_ReadString(EEex_ReadDword(address))
		end,
		["set"] = function(address, value)
			local stringMem = EEex_WriteStringAuto(value)
			EEex_Call(EEex_Label("CString::operator_equ(const_char*)"), {stringMem}, address, 0x0)
			EEex_Free(stringMem)
		end,
		["size"] = 0x4,
	})

	local decodeSpellPreserveThisHookAddress = EEex_Label("CGameAIBase::DecodeSpell")
	local decodeSpellPreserveThisHook = EEex_WriteAssemblyAuto({[[
		!push_ebp
		!mov_ebp_esp
		!sub_esp_byte 0C
		!mov_[ebp+byte]_ecx F4
		!jmp_dword ]], {decodeSpellPreserveThisHookAddress + 0x6, 4, 4},
	})
	EEex_WriteAssembly(decodeSpellPreserveThisHookAddress, {"!jmp_dword", {decodeSpellPreserveThisHook, 4, 4}, "!nop"})

	local decodeSpellHookAddress = EEex_Label("CGameAIBase::DecodeSpell()_SetResrefHook")
	local decodeSpellHook = EEex_WriteAssemblyAuto({[[

		!mov_eax_[ebp+byte] 08 ; spellId ;
		!test_eax_eax
		!jz_dword >marked_spell
		
		!call >CString::operator_equ(CString*)
		!jmp_dword ]], {decodeSpellHookAddress + 0x5, 4, 4}, [[

		@marked_spell
		!push_all_registers
		!push_ecx

		!mov_ecx_[ebp+byte] F4
		!call >EEex_AccessVolatileFields

		!pop_ecx
		!add_eax_dword ]], {markedSpellOffset, 4}, [[
		!push_eax
		!call >CString::operator_equ(CString*)

		!pop_all_registers
		!add_esp_byte 04
		!jmp_dword ]], {decodeSpellHookAddress + 0x5, 4, 4},

	})
	EEex_WriteAssembly(decodeSpellHookAddress, {"!jmp_dword", {decodeSpellHook, 4, 4}})

	EEex_EnableCodeProtection()

end
EEex_InstallSplHook()
