
---------------------------
-- Miscellaneous Changes --
---------------------------

(function()

	EEex_DisableCodeProtection()

	---------------------------------------------------------------------------------------
	-- Internal Opcode #12 from attacks has Parent Resource field filled with "EEEX_DAM" --
	-- Resource 2 is filled with weapon's resref                                         --
	-- Resource 3 is filled with launcher's resref                                       --
	---------------------------------------------------------------------------------------

	EEex_HookAfterCall(EEex_Label("CGameSprite::Damage()_InternalEffectHook"), {[[

		!push_all_registers

		!mov_edi_[ebp+byte] B8 ; pEffect ;

		; Set m_sourceRes to "EEEX_DAM" ;
		!mov_[edi+dword]_dword #90 #58454545 ; "EEEX" ;
		!mov_[edi+dword]_dword #94 #4D41445F ; "_DAM" ;

		; Set m_res2 to curWeaponIn's resref ;
		!mov_esi_[ebp+byte] 08 ; curWeaponIn ;
		!mov_eax_[esi+byte] 08
		!mov_[edi+byte]_eax 6C
		!mov_eax_[esi+byte] 0C
		!mov_[edi+byte]_eax 70

		; Set m_res3 to pLauncher's resref ;
		!mov_esi_[ebp+byte] 0C ; pLauncher ;
		!test_esi_esi
		!jz_dword >no_launcher

		!mov_eax_[esi+byte] 08
		!mov_[edi+byte]_eax 74
		!mov_eax_[esi+byte] 0C
		!mov_[edi+byte]_eax 78

		@no_launcher
		!pop_all_registers

	]]})

	EEex_EnableCodeProtection()

end)()
