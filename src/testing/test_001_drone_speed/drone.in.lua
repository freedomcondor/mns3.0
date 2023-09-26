if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

function init()
	api.init()
end

function reset()
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()

	api.droneSetSpeed(2, 0, -1, 0)

	api.postStep()
end

function destroy()
	api.destroy()
end