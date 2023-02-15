local DebugMessage = {}
DebugMessage.mt = {}
setmetatable(DebugMessage, DebugMessage.mt)

function DebugMessage.log_print(a, ...)
	print(a, ...)
end

-- call DebugMessage(...)
function DebugMessage.mt:__call(a, ...)
	local info = debug.getinfo(2)
	local src = info.short_src
	local moduleName = DebugMessage.modules[src]
	if moduleName == nil then moduleName = "nil" end
	if DebugMessage.switches[moduleName] == true then
		--log_print("DebugMSG:\t" .. moduleName .. ":" .. info.currentline .. "\t", ...)
		if type(a) == "table" then
			DebugMessage.ShowTable(a, ...)
		else
			DebugMessage.log_print("DebugMSG:\t", a, ...)
		end
	end
end

DebugMessage.modules = {}
DebugMessage.switches = {}
DebugMessage.switches["nil"] = false
DebugMessage.filelog = nil

function DebugMessage.enableFileLog(fileName)
	function DebugMessage.create_file_log_print(fileName)
		if fileName == nil then
			if robot ~= nil then
				fileName = robot.id .. ".filelog"
				if robot.params.hardware == true or robot.params.hardware == "true" then
					fileName = "/home/root/" .. fileName
				end
			else
				fileName = "noRobot" .. ".filelog"
			end
		end
		local file = io.open(fileName, "w")
		return function(a, ...)
			file:write(tostring(a))
			arg = {...}
			for i, v in ipairs(arg) do
				file:write(" " .. tostring(v))
			end
			file:write("\n")
		end
	end

	DebugMessage.log_print = DebugMessage.create_file_log_print(fileName)
end

function DebugMessage.enableErrorStreamLog()
	function DebugMessage.create_error_stream_log_print()
		return function(a, ...)
			io.stderr:write(tostring(a))
			arg = {...}
			for i, v in ipairs(arg) do
				io.stderr:write(" " .. tostring(v))
			end
			io.stderr:write("\n")
		end
	end

	DebugMessage.log_print = DebugMessage.create_error_stream_log_print()
end

function DebugMessage.closeFileLog()
	if DebugMessage.filelog ~= nil then
		DebugMessage.filelog:close()
	end
end

function DebugMessage.register(moduleName)
	local info = debug.getinfo(2)
	local src = info.short_src
	DebugMessage.modules[src] = moduleName
	DebugMessage.switches[moduleName] = true
end

function DebugMessage.disable(moduleName)
	if moduleName == nil then
		for i, v in pairs(DebugMessage.switches) do
			DebugMessage.switches[i] = false
			DebugMessage.switches["nil"] = false
		end
	else
		DebugMessage.switches[moduleName] = false
	end
end

function DebugMessage.enable(moduleName)
	if moduleName == nil then
		for i, v in pairs(DebugMessage.switches) do
			DebugMessage.switches[i] = true
			DebugMessage.switches["nil"] = true
		end
	else
		DebugMessage.switches[moduleName] = true
	end
end

function DebugMessage.ShowTable(table, number, skipindex)
	-- number means how many indents when log_printing
	if number == nil then number = 0 end
	if type(table) ~= "table" then return nil end

	for i, v in pairs(table) do
		local str = "DebugMSG:\t\t"
		for j = 1, number do
			str = str .. "\t"
		end

		str = str .. tostring(i) .. "\t"

		if i == skipindex then
			DebugMessage.log_print(str .. "SKIPPED")
		else
			if type(v) == "table" then
				DebugMessage.log_print(str)
				DebugMessage.ShowTable(v, number + 1, skipindex)
			else
				str = str .. tostring(v)
				DebugMessage.log_print(str)
			end
		end
	end
end

return DebugMessage
