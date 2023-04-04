if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end
logger = require("Logger")

pairs = require("AlphaPairs")

api = require("droneAPI")

logger.enable()

function init()
	api.init()
	api.debug.show_all = true

	if robot.id == "drone1" then
		api.parameters.droneDefaultStartHeight = 3
	end
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()

	--[[
	api.virtualFrame.moveInSpeed(vector3(0.1,0,0))
	api.virtualFrame.rotateInSpeed(vector3(0,0,0.1))
	--]]

	api.droneSetSpeed(0.1, 0, 0.0, 0.2)
	--api.move(vector3(0.1, 0, 0.1), vector3(0, 0, 0.2))

	api.postStep()
	api.debug.showVirtualFrame()
end

function reset()
end

function destroy()
	api.destroy()
end
