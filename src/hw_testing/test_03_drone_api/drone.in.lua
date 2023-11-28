logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")

logger.enable("droneAPI")

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	reset()
	--api.debug.show_all = true
end

function reset()
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()

	api.setSpeed(0.05, 0, 0, 3 * math.pi/180)

	api.postStep()
end

function destroy()
	api.destroy()
end