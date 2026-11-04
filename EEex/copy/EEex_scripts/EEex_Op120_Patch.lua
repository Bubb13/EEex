(function()

	-- This export exists only in the v2.7.3.0 build. Older engine versions
	-- retain their existing hooks and must not look up v2.7-only patterns.
	if not EEex_TryLabel("EEex::Op120_Hook_Swing") then
		return
	end

	local names = {
		"Op120-Swing", "Op120-AddEffect", "Op120-OnList", "Op120-OverrideWeaponType", "Op120-CopySelective",
		"Op120-FireArea", "Op120-FireColorSpray", "Op120-FireConeOfCold", "Op120-FireNewScorcher",
		"Op120-FireChain", "Op120-FireFall", "Op120-FireMulti", "Op120-AIUpdateBAM", "Op120-CaptureWeaponCall",
		"Op120-RangedImmunityCall", "Op120-MeleeImmunityCall",
		"Op120-ApplyCriticals", "Op120-RangedCriticalsCall", "EEex::Op120_ApplyCriticals", "EEex::Op120_Hook_ApplyCriticals",
		"EEex::Op120_Hook_Swing", "EEex::Op120_Hook_AddEffect", "EEex::Op120_Hook_CaptureWeapon",
		"EEex::Op120_Hook_RangedImmunity", "EEex::Op120_Original_Swing", "EEex::Op120_Original_AddEffect",
		"EEex::Op120_OnList", "EEex::Op120_OverrideWeaponType", "EEex::Op120_CopySelective",
		"EEex::Op120_MultiTargetFire", "EEex::Op120_FireMulti", "EEex::Op120_AIUpdateBAM",
	}
	local addresses = {}
	for _, name in ipairs(names) do
		-- Resolve the entire group before modifying code or native pointer slots.
		addresses[name] = EEex_Label(name)
	end
	local criticalsCall = addresses["Op120-RangedCriticalsCall"]
	if EEex_ReadU8(criticalsCall) ~= 0xE8
		or criticalsCall + 5 + EEex_Read32(criticalsCall + 1) ~= addresses["Op120-ApplyCriticals"]
	then
		EEex_Error("Opcode 120: unexpected ranged critical-hit call")
	end

	local captureCall = addresses["Op120-CaptureWeaponCall"]
	if EEex_ReadU8(captureCall) ~= 0xE8
		or captureCall + 5 + EEex_Read32(captureCall + 1) ~= addresses["Op120-OverrideWeaponType"]
	then
		EEex_Error("Opcode 120: unexpected weapon identification call")
	end

	-- Mix owns these sites. Independently derived v2.7 signatures must agree
	-- with its labels, so no second detour can accidentally overwrite Mix.
	for _, kind in ipairs({ "Ranged", "Melee" }) do
		local site = addresses["Op120-"..kind.."ImmunityCall"]
		if site ~= EEex_Label("Hook-CGameSprite::Swing()-CImmunitiesWeapon::OnList()-"..kind)
			or EEex_ReadU8(site) ~= 0xE8
			or site + 5 + EEex_Read32(site + 1) ~= addresses["Op120-OnList"]
		then
			EEex_Error("Opcode 120: unexpected "..kind.." immunity hook")
		end
	end

	for _, suffix in ipairs({ "OnList", "OverrideWeaponType", "CopySelective", "FireMulti", "AIUpdateBAM", "ApplyCriticals" }) do
		EEex_WritePtr(addresses["EEex::Op120_"..suffix], addresses["Op120-"..suffix])
	end
	for i, suffix in ipairs({ "Area", "ColorSpray", "ConeOfCold", "NewScorcher", "Chain", "Fall" }) do
		EEex_WritePtr(addresses["EEex::Op120_MultiTargetFire"] + (i - 1) * EEex_PtrSize, addresses["Op120-Fire"..suffix])
	end

	EEex_DisableCodeProtection()

	-- The audit verifies that each entry starts with one five-byte non-relative
	-- MOV, with no interior branch target. The preserved trampoline restores
	-- that MOV and jumps into the original function; native C++ wrappers own
	-- the complete Win64 argument/return ABI (including AddEffect's fifth arg).
	for _, suffix in ipairs({ "Swing", "AddEffect" }) do
		local originalLabel = "Op120-Original-"..suffix
		EEex_HookReplaceFunctionMaintainOriginal(addresses["Op120-"..suffix], 5, originalLabel, addresses["EEex::Op120_Hook_"..suffix])
		EEex_WritePtr(addresses["EEex::Op120_Original_"..suffix], EEex_Label(originalLabel))
	end

	-- An ABI-identical call replacement captures the fifth stack argument
	-- without hand-copying it in assembly, then invokes the native routine.
	EEex_ReplaceCall(captureCall, addresses["EEex::Op120_Hook_CaptureWeapon"])
	EEex_ReplaceCall(criticalsCall, addresses["EEex::Op120_Hook_ApplyCriticals"])
	EEex.Op120Installed = true

	EEex_EnableCodeProtection()

end)()
