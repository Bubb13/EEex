
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

	EEex_EnableCodeProtection()

end
EEex_InstallSplHook()
