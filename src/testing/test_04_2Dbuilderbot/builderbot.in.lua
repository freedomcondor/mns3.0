if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/builderbot-utils/?.lua"
	assert(loadfile(                "@CMAKE_CURRENT_BINARY_DIR@/simu_code/builderbot-utils/init.lua"))()
else
	package.path = package.path .. ";~/builderbot-utils/?.lua"
	assert(loadfile("~/builderbot-utils/init.lua"))()
end

--assert(loadfile("builderbot-utils/init.lua"))()

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")

local api = require("builderbotAPI")
data = api.builderbot_utils_data

function init()
	--api.linkRobotInterface(VNS)
	api.init() 

	api.debug.show_all = true
end

function reset()
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()

	api.move(vector3(0.1, 0, 0), vector3(0, 0, 0.2))

	api.postStep()
	api.debug.showVirtualFrame()
end

function destroy()
	api.destroy()
end
