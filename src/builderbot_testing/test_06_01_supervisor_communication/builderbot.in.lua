if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
	package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/builderbot-utils/?.lua"
	assert(loadfile(                "@CMAKE_SOURCE_DIR@/core/api/builderbot-utils/init.lua"))()
else
	package.path = package.path .. ";/home/root/builderbot-utils/?.lua"
	assert(loadfile("/home/root/builderbot-utils/init.lua"))()
	robot.radios = robot.simple_radios
end

logger = require("Logger")
logger.register("main")

function init()
end

function reset()
end

function step()
	logger(robot.id, robot.system.time, "-----------------------------")
	logger(robot.radios.wifi.recv)

	local msg = {}
	msg["ALLMSG"] = {
		fromS = robot.id,
		aaa = 1,
		bbb = "string",
		time = robot.system.time
	}

	robot.radios.wifi.send(msg)
end

function destroy()
end
