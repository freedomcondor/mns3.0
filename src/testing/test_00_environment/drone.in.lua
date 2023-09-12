if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end
logger = require("Logger")

pairs = require("AlphaPairs")

api = require("droneAPI")

logger.enable()

function init()
	for index, camera in pairs(robot.cameras_system) do
		camera.enable()
	end
	api.debug.show_all = true
end

function step()
	--if robot.id == "drone1" then
		robot.flight_system.set_target_pose(vector3(0,0,3), 0)
	--end

	--api.move(vector3(0,0,0), vector3(0.2, 0, 0.2))
	api.virtualFrame.moveInSpeed(vector3(0.1,0,0))
	api.virtualFrame.rotateInSpeed(vector3(0.1,0,0.1))
	api.debug.showVirtualFrame()

	logger(robot)
end

function reset()
end

function destroy()
	for index, camera in pairs(robot.cameras_system) do
		camera.disable()
	end
end
