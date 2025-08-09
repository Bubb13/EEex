
-------------
-- Hooking --
-------------

function EEex_ForceJump(address)
	local _, jmpDest, instructionLength, _ = EEex_GetJmpInfo(address)
	EEex_JITAt(address, {[[
		jmp short ]], jmpDest, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {instructionLength - 5}
	})
end

function EEex_HookAfterCall(address, assemblyT)
	EEex_HookCallInternal(address, {}, assemblyT, true)
end

function EEex_HookAfterCallWithLabels(address, labelPairs, assemblyT)
	EEex_HookCallInternal(address, labelPairs, assemblyT, true)
end

function EEex_HookAfterRestore(address, restoreDelay, restoreSize, returnDelay, assemblyT)
	EEex_HookAfterRestoreInternal(address, restoreDelay, restoreSize, returnDelay, {}, assemblyT)
end

function EEex_HookAfterRestoreInternal(address, restoreDelay, restoreSize, returnDelay, labelPairs, assemblyT)

	local restoreBytes = EEex_StoreBytesAssembly(address + restoreDelay, restoreSize)
	local returnAddress = address + returnDelay

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()

		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)

		local manualReturn = EEex_TryLabel("manual_return")
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"return", (not EEex_HookIntegrityWatchdog_Load or manualReturn) and returnAddress or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({
					restoreBytes,
					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[
					#IF ]], not manualReturn, [[ {
						#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {
							return:
							#MANUAL_HOOK_EXIT(0)
						}
						jmp ]], returnAddress, [[ #ENDL
					} ]]
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function EEex_HookAfterRestoreWithLabels(address, restoreDelay, restoreSize, returnDelay, labelPairs, assemblyT)
	EEex_HookAfterRestoreInternal(address, restoreDelay, restoreSize, returnDelay, labelPairs, assemblyT)
end

function EEex_HookBeforeAndAfterCall(address, beforeAssemblyT, afterAssemblyT)
	EEex_HookBeforeAndAfterCallInternal(address, {}, beforeAssemblyT, afterAssemblyT)
end

function EEex_HookBeforeAndAfterCallInternal(address, labelPairs, beforeAssemblyT, afterAssemblyT)

	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE8 then EEex_Error("Not disp32 call: "..EEex_ToHex(opcode)) end

	local afterCall = address + 5
	local target = afterCall + EEex_Read32(address + 1)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()

		if EEex_HookIntegrityWatchdog_Load then
			EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(address, 0, {EEex_HookIntegrityWatchdogRegister.RAX})
			EEex_HookIntegrityWatchdog_DefaultIgnoreStackForInstance(address, 0)
			EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(address, 1, {
				EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
				EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
			})
			EEex_HookIntegrityWatchdog_DefaultIgnoreStackForInstance(address, 1)
		end

		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"return", not EEex_HookIntegrityWatchdog_Load and afterCall or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({

					EEex_HookIntegrityWatchdog_HookEnter,
					beforeAssemblyT, [[
					call:
					#MANUAL_HOOK_EXIT(0)

					call ]], target, "#ENDL",

					EEex_HookIntegrityWatchdog_HookEnter,
					afterAssemblyT, [[
					#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {
						return:
					}
					#MANUAL_HOOK_EXIT(1)
					jmp ]], afterCall, "#ENDL",
				}))
			end
		)
	end)

	EEex_JITAt(address, {"jmp short "..hookAddress})
end

function EEex_HookBeforeAndAfterCallWithLabels(address, labelPairs, beforeAssemblyT, afterAssemblyT)
	EEex_HookBeforeAndAfterCallInternal(address, labelPairs, beforeAssemblyT, afterAssemblyT)
end

function EEex_HookBeforeCall(address, assemblyT)
	EEex_HookCallInternal(address, {}, assemblyT, false)
end

function EEex_HookBeforeCallWithLabels(address, labelPairs, assemblyT)
	EEex_HookCallInternal(address, labelPairs, assemblyT, false)
end

function EEex_HookBeforeConditionalJump(address, restoreSize, assemblyT)
	EEex_HookBeforeConditionalJumpInternal(address, restoreSize, {}, assemblyT)
end

function EEex_HookBeforeConditionalJumpInternal(address, restoreSize, labelPairs, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()
		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"jmp_success", not EEex_HookIntegrityWatchdog_Load and jmpDest or nil},
			{"jmp_fail", (not EEex_HookIntegrityWatchdog_Load and restoreSize <= 0) and jmpFailDest or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({

					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[

					#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {

						return: #ENDL ]],
						jmpMnemonic, [[ jmp_success

						jmp_fail:
						#MANUAL_HOOK_EXIT(0) ]],
						restoreBytes, [[
						jmp ]], jmpFailDest, [[ #ENDL

						jmp_success:
						#MANUAL_HOOK_EXIT(0)
						jmp ]], jmpDest, [[ #ENDL
					}

					#IF ]], not EEex_HookIntegrityWatchdog_Load, [[ {

						return: #ENDL ]],
						jmpMnemonic, " ", jmpDest, [[ #ENDL

						#IF ]], restoreSize > 0, [[ {
							jmp_fail: #ENDL ]],
							restoreBytes, [[
						}

						jmp ]], jmpFailDest, [[ #ENDL
					} ]],
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookBeforeConditionalJumpWithLabels(address, restoreSize, labelPairs, assemblyT)
	EEex_HookBeforeConditionalJumpInternal(address, restoreSize, labelPairs, assemblyT)
end

function EEex_HookBeforeRestore(address, restoreDelay, restoreSize, returnDelay, assemblyT)
	EEex_HookBeforeRestoreInternal(address, restoreDelay, restoreSize, returnDelay, {}, assemblyT)
end

function EEex_HookBeforeRestoreInternal(address, restoreDelay, restoreSize, returnDelay, labelPairs, assemblyT)

	local restoreBytes = EEex_StoreBytesAssembly(address + restoreDelay, restoreSize)
	local returnAddress = address + returnDelay

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()

		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)

		local manualHookIntegrityExit = EEex_TryLabel("manual_hook_integrity_exit")
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address}},
			function()
				return EEex_JITNear(EEex_FlattenTable({
					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[
					return:
					#IF ]], not manualHookIntegrityExit, [[ {
						#MANUAL_HOOK_EXIT(0)
					} ]],
					restoreBytes, [[
					jmp ]], returnAddress, "#ENDL"
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function EEex_HookBeforeRestoreWithLabels(address, restoreDelay, restoreSize, returnDelay, labelPairs, assemblyT)
	EEex_HookBeforeRestoreInternal(address, restoreDelay, restoreSize, returnDelay, labelPairs, assemblyT)
end

function EEex_HookBetweenRestore(address, restoreDelay1, restoreSize1, restoreDelay2, restoreSize2, returnDelay, assemblyT)
	EEex_HookBetweenRestoreInternal(address, restoreDelay1, restoreSize1, restoreDelay2, restoreSize2, returnDelay, {}, assemblyT)
end

function EEex_HookBetweenRestoreInternal(address, restoreDelay1, restoreSize1, restoreDelay2, restoreSize2, returnDelay, labelPairs, assemblyT)

	local restoreBytes1 = EEex_StoreBytesAssembly(address + restoreDelay1, restoreSize1)
	local restoreBytes2 = EEex_StoreBytesAssembly(address + restoreDelay2, restoreSize2)
	local returnAddress = address + returnDelay

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()
		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address}},
			function()
				return EEex_JITNear(EEex_FlattenTable({
					restoreBytes1,
					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[
					return:
					#MANUAL_HOOK_EXIT(0) ]],
					restoreBytes2, [[
					jmp ]], returnAddress, "#ENDL"
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function EEex_HookBetweenRestoreWithLabels(address, restoreDelay1, restoreSize1, restoreDelay2, restoreSize2, returnDelay, labelPairs, assemblyT)
	EEex_HookBetweenRestoreInternal(address, restoreDelay1, restoreSize1, restoreDelay2, restoreSize2, returnDelay, labelPairs, assemblyT)
end

function EEex_HookCallInternal(address, labelPairs, assemblyT, after)

	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE8 then EEex_Error("Not disp32 call: "..EEex_ToHex(opcode)) end

	local afterCall = address + 5
	local target = afterCall + EEex_Read32(address + 1)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()

		if EEex_HookIntegrityWatchdog_Load then
			if not after then
				EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {EEex_HookIntegrityWatchdogRegister.RAX})
			else
				EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {
					EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
					EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
				})
			end
			EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		end

		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"return_skip", (not EEex_HookIntegrityWatchdog_Load and not after) and afterCall or nil},
			{"return", (not EEex_HookIntegrityWatchdog_Load and after) and afterCall or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable(
					not after
					and {
						EEex_HookIntegrityWatchdog_HookEnter,
						assemblyT, [[
						return:
						#MANUAL_HOOK_EXIT(0)
						call ]], target, [[ #ENDL
						jmp ]], afterCall, [[ #ENDL

						#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {
							return_skip:
							#MANUAL_HOOK_EXIT(0)
							jmp ]], afterCall, [[ #ENDL
						}
					]]}
					or {[[
						call ]], target, "#ENDL",
						EEex_HookIntegrityWatchdog_HookEnter,
						assemblyT, [[
						#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {
							return:
							#MANUAL_HOOK_EXIT(0)
						}
						jmp ]], afterCall, [[ #ENDL
					]]}
				))
			end
		)
	end)

	EEex_JITAt(address, {"jmp short "..hookAddress})
end

function EEex_HookConditionalJump(address, restoreSize, failAssembly, successAssembly)
	EEex_HookConditionalJumpInternal(address, restoreSize, {}, failAssembly, successAssembly)
end

function EEex_HookConditionalJumpWithLabels(address, restoreSize, labelPairs, failAssembly, successAssembly)
	EEex_HookConditionalJumpInternal(address, restoreSize, labelPairs, failAssembly, successAssembly)
end

function EEex_HookConditionalJumpInternal(address, restoreSize, labelPairs, failAssembly, successAssembly)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()

		EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(address, 0, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStackForInstance(address, 0)
		EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(address, 1, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStackForInstance(address, 1)

		return EEex_RunWithAssemblyLabels({
			{"hook_address", address}},
			function()
				return EEex_JITNear(EEex_FlattenTable({
					EEex_HookIntegrityWatchdog_HookEnter,
					jmpMnemonic, " jmp_success_internal #ENDL",

					failAssembly, [[
					jmp_fail:
					#MANUAL_HOOK_EXIT(0) ]],
					restoreBytes, [[
					jmp ]], jmpFailDest, [[

					jmp_success_internal: #ENDL ]],
					successAssembly, [[
					jmp_success:
					#MANUAL_HOOK_EXIT(1)
					jmp ]], jmpDest
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookConditionalJumpOnFail(address, restoreSize, assemblyT)
	EEex_HookConditionalJumpOnFailInternal(address, restoreSize, {}, assemblyT)
end

function EEex_HookConditionalJumpOnFailInternal(address, restoreSize, labelPairs, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()
		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"jmp_success", not EEex_HookIntegrityWatchdog_Load and jmpDest or nil},
			{"jmp_fail", (not EEex_HookIntegrityWatchdog_Load and restoreSize <= 0) and jmpFailDest or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({

					jmpMnemonic, " ", jmpDest, "#ENDL",

					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[

					#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {

						jmp_fail:
						#MANUAL_HOOK_EXIT(0) ]],
						restoreBytes, [[
						jmp ]], jmpFailDest, [[ #ENDL

						jmp_success:
						#MANUAL_HOOK_EXIT(0)
						jmp ]], jmpDest, [[ #ENDL
					}

					#IF ]], not EEex_HookIntegrityWatchdog_Load, [[ {

						#IF ]], restoreSize > 0, [[ {
							jmp_fail: #ENDL ]],
							restoreBytes, [[
						}

						jmp ]], jmpFailDest, [[ #ENDL
					} ]],
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookConditionalJumpOnFailWithLabels(address, restoreSize, labelPairs, assemblyT)
	EEex_HookConditionalJumpOnFailInternal(address, restoreSize, labelPairs, assemblyT)
end

function EEex_HookConditionalJumpOnSuccess(address, restoreSize, assemblyT)
	EEex_HookConditionalJumpOnSuccessInternal(address, restoreSize, {}, assemblyT)
end

function EEex_HookConditionalJumpOnSuccessInternal(address, restoreSize, labelPairs, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()
		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"jmp_success", not EEex_HookIntegrityWatchdog_Load and jmpDest or nil},
			{"jmp_fail", (not EEex_HookIntegrityWatchdog_Load and restoreSize <= 0) and jmpFailDest or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({

					jmpMnemonic, " jmp_success_internal #ENDL",
					restoreBytes, [[
					jmp ]], jmpFailDest, [[ #ENDL

					#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {

						jmp_success_internal: #ENDL ]],
						EEex_HookIntegrityWatchdog_HookEnter,

						assemblyT, [[
						jmp_success:
						#MANUAL_HOOK_EXIT(0)
						jmp ]], jmpDest, [[ #ENDL

						jmp_fail:
						#MANUAL_HOOK_EXIT(0) ]],
						restoreBytes, [[
						jmp ]], jmpFailDest, [[ #ENDL
					}

					#IF ]], not EEex_HookIntegrityWatchdog_Load, [[ {

						jmp_success_internal: #ENDL ]],
						assemblyT, [[
						jmp ]], jmpDest, [[ #ENDL

						#IF ]], restoreSize > 0, [[ {
							jmp_fail: #ENDL ]],
							restoreBytes, [[
							jmp ]], jmpFailDest, [[ #ENDL
						}
					} ]],
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookConditionalJumpOnSuccessWithLabels(address, restoreSize, labelPairs, assemblyT)
	EEex_HookConditionalJumpOnSuccessInternal(address, restoreSize, labelPairs, assemblyT)
end

function EEex_HookNOPs(address, nopCount, assemblyT)
	EEex_HookNOPsInternal(address, nopCount, {}, assemblyT)
end

function EEex_HookNOPsInternal(address, nopCount, labelPairs, assemblyT)

	local returnAddress = address + 5 + nopCount

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()
		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"return", not EEex_HookIntegrityWatchdog_Load and returnAddress or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({
					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[
					#IF ]], EEex_HookIntegrityWatchdog_Load == true, [[ {
						return:
						#MANUAL_HOOK_EXIT(0)
					}
					jmp ]], returnAddress, "#ENDL"
				}))
			end
		)
	end)

	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {nopCount}
	})
end

function EEex_HookNOPsWithLabels(address, nopCount, labelPairs, assemblyT)
	EEex_HookNOPsInternal(address, nopCount, labelPairs, assemblyT)
end

function EEex_HookRelativeJump(address, assemblyT)
	EEex_HookRelativeJumpInternal(address, {}, assemblyT)
end

function EEex_HookRelativeJumpInternal(address, labelPairs, assemblyT)

	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE9 then EEex_Error("Not disp32 jmp: "..EEex_ToHex(opcode)) end

	local afterCall = address + 5
	local target = afterCall + EEex_Read32(address + 1)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()
		EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {})
		EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		local manualContinue = EEex_TryLabel("manual_continue")
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"original", manualContinue and target or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({
					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[
					#IF ]], not manualContinue, [[ {
						original:
						#MANUAL_HOOK_EXIT(0)
						jmp ]], target, [[
					}
				]]}))
			end
		)
	end)

	EEex_JITAt(address, {"jmp short "..hookAddress})
end

function EEex_HookRelativeJumpWithLabels(address, labelPairs, assemblyT)
	EEex_HookRelativeJumpInternal(address, labelPairs, assemblyT)
end

function EEex_HookRemoveCall(address, assemblyT)
	EEex_HookRemoveCallInternal(address, {}, assemblyT)
end

function EEex_HookRemoveCallInternal(address, labelPairs, assemblyT)

	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE8 then EEex_Error("Not disp32 call: "..EEex_ToHex(opcode)) end

	local afterCall = address + 5
	local target = afterCall + EEex_Read32(address + 1)

	local hookAddress = EEex_RunWithAssemblyLabels(labelPairs or {}, function()

		if EEex_HookIntegrityWatchdog_Load then
			EEex_HookIntegrityWatchdog_IgnoreRegisters(address, {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
				EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
				EEex_HookIntegrityWatchdogRegister.R11
			})
			EEex_HookIntegrityWatchdog_DefaultIgnoreStack(address)
		end

		local manualReturn = EEex_TryLabel("manual_return")
		return EEex_RunWithAssemblyLabels({
			{"hook_address", address},
			{"original", target},
			{"return", manualReturn and afterCall or nil}},
			function()
				return EEex_JITNear(EEex_FlattenTable({
					EEex_HookIntegrityWatchdog_HookEnter,
					assemblyT, [[
					#IF ]], not manualReturn, [[ {
						return:
						#MANUAL_HOOK_EXIT(0)
						jmp ]], afterCall, [[
					}
				]]}))
			end
		)
	end)

	EEex_JITAt(address, {"jmp short "..hookAddress})
end

function EEex_HookRemoveCallWithLabels(address, labelPairs, assemblyT)
	EEex_HookRemoveCallInternal(address, labelPairs, assemblyT)
end

function EEex_ReplaceCall(address, newTarget)
	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE8 then EEex_Error("Not disp32 call: "..EEex_ToHex(opcode)) end
	EEex_JITAt(address, {"call short ", EEex_JITNear({"jmp ", newTarget, "#ENDL"}), "#ENDL"})
end

function EEex_HookReplaceFunctionMaintainOriginal(address, restoreSize, originalLabel, newTarget)
	EEex_HookShimFunctionMaintainOriginal(address, restoreSize, originalLabel, {"jmp ", newTarget, "#ENDL"})
end

function EEex_HookShimFunctionMaintainOriginal(address, restoreSize, originalLabel, assembly)

	EEex_JITNearAsLabel(originalLabel, EEex_FlattenTable({
		EEex_StoreBytesAssembly(address, restoreSize),
		{"jmp ", address + restoreSize, "#ENDL"},
	}))

	EEex_JITAt(address, {[[
		jmp short ]], EEex_JITNear(assembly), [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5},
	})
end

---------------------
-- Hooking Utility --
---------------------

EEex_LuaCallReturnType = {
	["Boolean"] = 0,
	["Number"] = 1,
}

function EEex_GenLuaCall(funcName, meta)

	-- +-------------------------------------------------------+
	-- | [0x0] Shadow Space                                    |
	-- +-------------------------------------------------------+
	-- | [0x32] (localCallArgsTop)                             |
	-- |   pcallk's stack args                                 |
	-- |   stack args the caller requested                     |
	-- +-------------------------------------------------------+
	-- | [0x32 + numLocalCallArgBytes] (localArgsTop)          |
	-- |   saved rbx                                           |
	-- +-------------------------------------------------------+
	-- | [0x32 + numLocalCallArgBytes + 0x8]                   |
	-- |   saved return value                                  |
	-- +-------------------------------------------------------+
	-- | [0x32 + numLocalCallArgBytes + 0x10] (luaCallArgsTop) |
	-- |   saved Lua arg #1                                    |
	-- |   saved Lua arg #2                                    |
	-- |   ...                                                 |
	-- +-------------------------------------------------------+

	local numArgs = #((meta or {}).args or {})

	-- These are used to store pcallk's stack args, plus any stack args the caller requested
	local numLocalCallArgBytes = 16 + math.max(0, ((meta or {}).numStackArgs or 0) - 2) * 8

	-- qword:[localArgsTop]     - The saved rbx value, which I clobber to store lua_State* L
	-- qword:[localArgsTop + 8] - The saved return value (if any), I should probably only
	--                            store this when a return value is requested
	local numShadowLocalArgBytes = 16

	-- Total shadow space needed (not including the default-included 32 bytes)
	local numShadowExtraBytes = numLocalCallArgBytes + numShadowLocalArgBytes + numArgs * 8

	-- Top of GenLuaCall's special variables, (+32 to move over shadow space register storage)
	local localArgsTop = 32 + numLocalCallArgBytes

	-- Top of GenLuaCall's saved Lua function argument values
	local luaCallArgsTop = localArgsTop + numShadowLocalArgBytes

	local argsUserType = {}
	local argsCastFunction = {}

	local labelSuffix = (meta or {}).labelSuffix or ""

	local errorFunc
	local errorFuncLuaStackPopAmount
	if (meta or {}).errorFunction then
		errorFunc = meta.errorFunction.func
		errorFuncLuaStackPopAmount = errorFunc and (1 + (meta.errorFunction.precursorAmount or 0)) or 0
	else
		errorFunc = {[[
			mov rdx, ]], EEex_WriteStringCache("debug"), [[ ; name
			mov rcx, rbx                                    ; L
			#ALIGN
			call #L(Hardcoded_lua_getglobal)
			#ALIGN_END

			mov r8, ]], EEex_WriteStringCache("traceback"), [[ ; k
			mov rdx, -1                                        ; index
			mov rcx, rbx                                       ; L
			#ALIGN
			call #L(Hardcoded_lua_getfield)
			#ALIGN_END
		]]}
		errorFuncLuaStackPopAmount = 2
	end

	local pushArgTemplate = function(argI)

		local argStackOffset = luaCallArgsTop + argI * 8
		local userType = argsUserType[argI + 1]
		local userTypeType = type(userType)

		if userType == nil then

			return {[[
				mov rdx, qword ptr ss:[rsp+#$(1)] ]], {argStackOffset}, [[ ; n
				mov rcx, rbx                                               ; L
				#ALIGN
				call #L(Hardcoded_lua_pushinteger)
				#ALIGN_END
			]]}

		elseif userTypeType == "string" then

			if userType == "string" then
				return {[[
					mov rdx, qword ptr ss:[rsp+#$(1)] ]], {argStackOffset}, [[ ; n
					mov rcx, rbx                                               ; L
					#ALIGN
					call #L(Hardcoded_lua_pushstring)
					#ALIGN_END
				]]}
			elseif userType == "boolean" then
				return {[[
					mov rdx, qword ptr ss:[rsp+#$(1)] ]], {argStackOffset}, [[ ; n
					mov rcx, rbx                                               ; L
					#ALIGN
					call #L(Hardcoded_lua_pushboolean)
					#ALIGN_END
				]]}
			else
				local argCastFunction = argsCastFunction[argI + 1]
				if argCastFunction then

					return {[[

						mov rdx, ]], EEex_WriteStringCache(argCastFunction), [[ ; name
						mov rcx, rbx                                            ; L
						#ALIGN
						call #L(Hardcoded_lua_getglobal)
						#ALIGN_END

						mov r8, ]], EEex_WriteStringCache(userType), [[            ; type
						mov rdx, qword ptr ss:[rsp+#$(1)] ]], {argStackOffset}, [[ ; value
						mov rcx, rbx                                               ; L
						#ALIGN
						call #L(Hardcoded_tolua_pushusertype)
						#ALIGN_END

						mov qword ptr ss:[rsp+40], 0                   ; k
						mov qword ptr ss:[rsp+32], 0                   ; ctx
						mov r9, ]], errorFunc and -(4 + argI) or 0, [[ ; errfunc
						mov r8, 1                                      ; nresults
						mov rdx, 1                                     ; nargs
						mov rcx, rbx                                   ; L
						#ALIGN
						call #L(Hardcoded_lua_pcallk)
						#ALIGN_END

						mov rcx, rbx
						#ALIGN
						call #L(EEex_CheckCallError)
						#ALIGN_END

						test rax, rax
						jz EEex_GenLuaCall_arg#$(1)_cast_function_no_error#$(2) ]], {argI, labelSuffix}, [[ #ENDL

						; Clear function args, function, and error function (+ its precursors) off of Lua stack
						mov rdx, ]], -(2 + errorFuncLuaStackPopAmount + argI), [[ ; index
						mov rcx, rbx                                              ; L
						#ALIGN
						call #L(Hardcoded_lua_settop)
						#ALIGN_END
						jmp EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL

						EEex_GenLuaCall_arg#$(1)_cast_function_no_error#$(2): ]], {argI, labelSuffix}, [[ #ENDL
					]]}
				else
					return {[[
						mov r8, ]], EEex_WriteStringCache(userType), [[            ; type
						mov rdx, qword ptr ss:[rsp+#$(1)] ]], {argStackOffset}, [[ ; value
						mov rcx, rbx                                               ; L
						#ALIGN
						call #L(Hardcoded_tolua_pushusertype)
						#ALIGN_END
					]]}
				end
			end
		else
			EEex_Error("[EEex_GenLuaCall] Invalid arg usertype: "..userTypeType)
		end
	end

	local returnBooleanTemplate = {[[
		mov rdx, -1  ; index
		mov rcx, rbx ; L
		#ALIGN
		call #L(Hardcoded_lua_toboolean)
		#ALIGN_END
		mov qword ptr ss:[rsp+#$(1)], rax ]], {localArgsTop + 8}, [[ #ENDL
	]]}

	local returnNumberTemplate = {[[
		mov r8, 0    ; isnum
		mov rdx, -1  ; index
		mov rcx, rbx ; L
		#ALIGN
		call #L(Hardcoded_lua_tointegerx)
		#ALIGN_END
		mov qword ptr ss:[rsp+#$(1)], rax ]], {localArgsTop + 8}, [[ #ENDL
	]]}

	local genArgPushes1 = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = numArgs, 1, -1 do
			local argT, argUT, argCastFunction = args[i](luaCallArgsTop + (i - 1) * 8)
			toReturn[insertionIndex] = argT
			argsUserType[i] = argUT
			argsCastFunction[i] = argCastFunction
			insertionIndex = insertionIndex + 1
		end

		return EEex_FlattenTable(toReturn)
	end

	local genFunc = function()
		if funcName then
			if meta then
				if meta.functionChunk then EEex_Error("[EEex_GenLuaCall] funcName and meta.functionChunk are exclusive") end
				if meta.functionSrc then EEex_Error("[EEex_GenLuaCall] funcName and meta.functionSrc are exclusive") end
			end
			return {[[
				mov rdx, ]], EEex_WriteStringCache(funcName), [[ ; name
				mov rcx, rbx                                     ; L
				#ALIGN
				call #L(Hardcoded_lua_getglobal)
				#ALIGN_END
			]]}
		elseif meta then
			if meta.functionChunk then
				if numArgs > 0 then EEex_Error("[EEex_GenLuaCall] Lua chunks can't be passed arguments") end
				if meta.functionSrc then EEex_Error("[EEex_GenLuaCall] meta.functionChunk and meta.functionSrc are exclusive") end
				return EEex_FlattenTable({
					meta.functionChunk,
					{[[
						mov rcx, rbx ; L
						#ALIGN
						call #L(Hardcoded_luaL_loadstring)
						#ALIGN_END

						test rax, rax
						jz EEex_GenLuaCall_loadstring_no_error#$(1) ]], {labelSuffix}, [[ #ENDL

						#IF ]], errorFunc ~= nil, [[ {

							; Call error function with loadstring message
							mov qword ptr ss:[rsp+40], 0 ; k
							mov qword ptr ss:[rsp+32], 0 ; ctx
							mov r9, 0                    ; errfunc
							mov r8, 1                    ; nresults
							mov rdx, 1                   ; nargs
							mov rcx, rbx                 ; L
							#ALIGN
							call #L(Hardcoded_lua_pcallk)
							#ALIGN_END

							mov rcx, rbx
							#ALIGN
							call #L(EEex_CheckCallError)
							#ALIGN_END

							test rax, rax
							jnz EEex_GenLuaCall_error_in_error_handling#$(1) ]], {labelSuffix}, [[ #ENDL

							mov rcx, rbx
							#ALIGN
							call #L(EEex_PrintPopLuaString)
							#ALIGN_END

							EEex_GenLuaCall_error_in_error_handling#$(1): ]], {labelSuffix}, [[ #ENDL
							; Clear error function precursors off of Lua stack
							mov rdx, ]], -errorFuncLuaStackPopAmount, [[ #ENDL
							mov rcx, rbx
							#ALIGN
							call #L(Hardcoded_lua_settop)
							#ALIGN_END

							jmp EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
						}

						#IF ]], errorFunc == nil, [[ {
							mov rcx, rbx
							call #L(EEex_PrintPopLuaString)
							jmp EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
						}

						EEex_GenLuaCall_loadstring_no_error#$(1): ]], {labelSuffix}, [[ #ENDL
					]]},
				})
			elseif meta.functionSrc then
				if meta.functionChunk then EEex_Error("[EEex_GenLuaCall] meta.functionSrc and meta.functionChunk are exclusive") end
				return meta.functionSrc
			end
		end

		EEex_Error("[EEex_GenLuaCall] meta.functionChunk or meta.functionSrc must be defined when funcName = nil")
	end

	local genArgPushes2 = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = 0, numArgs - 1 do
			toReturn[insertionIndex] = pushArgTemplate(i)
			insertionIndex = insertionIndex + 1
		end

		return EEex_FlattenTable(toReturn)
	end

	local genReturnHandling = function()

		if not meta then return {} end
		local returnType = meta.returnType
		if not returnType then return {} end

		if returnType == EEex_LuaCallReturnType.Boolean then
			return returnBooleanTemplate
		elseif returnType == EEex_LuaCallReturnType.Number then
			return returnNumberTemplate
		else
			EEex_Error("[EEex_GenLuaCall] meta.returnType invalid")
		end
	end

	local numRet = (meta or {}).returnType and 1 or 0
	local toReturn = EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(#$(1)) ]], {numShadowExtraBytes}, [[ #ENDL
		]]},
		genArgPushes1(),
		(meta or {}).luaState or {[[
			mov qword ptr ss:[rsp+#$(1)], rbx ]], {localArgsTop}, [[ #ENDL
			mov rbx, #L(Hardcoded_InternalLuaState)
		]]},
		errorFunc or {},
		genFunc(),
		genArgPushes2(),
		{[[
			#ALIGN
			mov qword ptr ss:[rsp+8], 0                       ; k
			mov qword ptr ss:[rsp], 0                         ; ctx
			mov r9, ]], errorFunc and -(2 + numArgs) or 0, [[ ; errfunc
			mov r8, ]], numRet, [[                            ; nresults
			mov rdx, ]], numArgs, [[                          ; nargs
			mov rcx, rbx                                      ; L
			call #L(Hardcoded_lua_pcallk)
			#ALIGN_END

			#ALIGN
			mov rcx, rbx
			call #L(EEex_CheckCallError)
			#ALIGN_END

			test rax, rax

			#IF ]], errorFunc ~= nil, [[ {
				jz EEex_GenLuaCall_no_error#$(1) ]], {labelSuffix}, [[ #ENDL
				; Clear error function and its precursors off of Lua stack
				mov rdx, ]], -(1 + errorFuncLuaStackPopAmount), [[ ; index
				mov rcx, rbx                                       ; L
				#ALIGN
				call #L(Hardcoded_lua_settop)
				#ALIGN_END
				jmp EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
			}

			#IF ]], errorFunc == nil, [[ {
				jnz EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
			}

			EEex_GenLuaCall_no_error#$(1): ]], {labelSuffix}, [[ #ENDL
		]]},
		genReturnHandling(),
		{[[
			; Clear return values and error function (+ its precursors) off of Lua stack
			mov rdx, ]], -(1 + errorFuncLuaStackPopAmount + numRet), [[ ; index
			mov rcx, rbx                                                ; L
			#ALIGN
			call #L(Hardcoded_lua_settop)
			#ALIGN_END

			#IF ]], numRet > 0, [[ {
				mov rax, qword ptr ss:[rsp+#$(1)] ]], {localArgsTop + 8}, [[ #ENDL
			}

			jmp EEex_GenLuaCall_resume#$(1) ]], {labelSuffix}, [[ #ENDL

			EEex_GenLuaCall_call_error#$(1): ]], {labelSuffix}, [[ #ENDL
			mov rbx, qword ptr ss:[rsp+#$(1)] ]], {localArgsTop}, [[ #ENDL
			jmp call_error#$(1) ]], {labelSuffix}, [[ #ENDL

			EEex_GenLuaCall_resume#$(1): ]], {labelSuffix}, [[ #ENDL
			mov rbx, qword ptr ss:[rsp+#$(1)] ]], {localArgsTop}, [[ #ENDL
		]]},
	})

	return toReturn
end

function EEex_GetJmpInfo(address)

	local opcode = EEex_ReadU8(address)
	local hadWordPrefix = false
	local curAddress = address

	if opcode == 0x66 then
		hadWordPrefix = true
		curAddress = curAddress + 1
		opcode = EEex_ReadU8(curAddress)
	end

	local entry
	if opcode ~= 0x0F then
		entry = ({
			[0x70] = { "jo",     1                        },
			[0x71] = { "jno",    1                        },
			[0x72] = { "jb",     1                        },
			[0x73] = { "jnb",    1                        },
			[0x74] = { "jz",     1                        },
			[0x75] = { "jnz",    1                        },
			[0x76] = { "jbe",    1                        },
			[0x77] = { "ja",     1                        },
			[0x78] = { "js",     1                        },
			[0x79] = { "jns",    1                        },
			[0x7A] = { "jp",     1                        },
			[0x7B] = { "jnp",    1                        },
			[0x7C] = { "jl",     1                        },
			[0x7D] = { "jnl",    1                        },
			[0x7E] = { "jle",    1                        },
			[0x7F] = { "jg",     1                        },
			[0xE0] = { "loopnz", 1                        },
			[0xE1] = { "loopz",  1                        },
			[0xE2] = { "loop",   1                        },
			[0xE3] = { "jcxz",   1                        },
			[0xE8] = { "call",   hadWordPrefix and 2 or 4 },
			[0xE9] = { "jmp",    hadWordPrefix and 2 or 4 },
			[0xEB] = { "jmp",    1                        },
		})[opcode]
	else
		curAddress = curAddress + 1
		opcode = EEex_ReadU8(curAddress)
		local length = hadWordPrefix and 2 or 4
		entry = ({
			[0x80] = { "jo",  length },
			[0x81] = { "jno", length },
			[0x82] = { "jb",  length },
			[0x83] = { "jnb", length },
			[0x84] = { "jz",  length },
			[0x85] = { "jnz", length },
			[0x86] = { "jbe", length },
			[0x87] = { "ja",  length },
			[0x88] = { "js",  length },
			[0x89] = { "jns", length },
			[0x8A] = { "jp",  length },
			[0x8B] = { "jnp", length },
			[0x8C] = { "jl",  length },
			[0x8D] = { "jnl", length },
			[0x8E] = { "jle", length },
			[0x8F] = { "jg",  length },
		})[opcode]
	end

	local readLen = entry[2]
	local readFunc = ({
		[1] = EEex_Read8,
		[2] = EEex_Read16,
		[4] = EEex_Read32,
	})[readLen]

	curAddress = curAddress + 1
	local afterInst = curAddress + readLen
	return entry[1], afterInst + readFunc(curAddress), afterInst - address, afterInst
end

function EEex_StoreBytesAssembly(startAddress, size)
	if size <= 0 then return {} end
	local bytes = {".DB "}
	for i = startAddress, startAddress + size - 1 do
		table.insert(bytes, EEex_ReadU8(i))
		table.insert(bytes, ", ")
	end
	if size > 0 then
		table.remove(bytes)
		table.insert(bytes, "#ENDL")
	end
	return bytes
end

--------------------
-- Initialization --
--------------------

EEex_Once("EEex_Assembly_x86-64_Initialization", function()
	local dummyTable = {}
	EEex_HookIntegrityWatchdog_HookEnter = dummyTable
	EEex_HookIntegrityWatchdog_HookExit = function() return dummyTable end
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance = function() end
	EEex_HookIntegrityWatchdog_IgnoreRegisters = function() end
	EEex_HookIntegrityWatchdog_DefaultIgnoreStackForInstance = function() end
	EEex_HookIntegrityWatchdog_DefaultIgnoreStack = function() end
	EEex_HookIntegrityWatchdog_IgnoreStackSizesForInstance = function() end
	EEex_HookIntegrityWatchdog_IgnoreStackSizes = function() end
end)
