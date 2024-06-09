if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
	package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/builderbot-utils/?.lua"
	assert(loadfile(                "@CMAKE_SOURCE_DIR@/core/api/builderbot-utils/init.lua"))()
else
	package.path = package.path .. ";/home/root/builderbot-utils/?.lua"
	assert(loadfile("/home/root/builderbot-utils/init.lua"))()
	robot.radios = robot.simple_radios
end


--assert(loadfile("builderbot-utils/init.lua"))()

logger = require("Logger")
logger.register("main")
logger.enable()
pairs = require("AlphaPairs")

local api = require("builderbotAPI")
robot.vns_api = api
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

----- data
local bt
local structure1 = require("morphology1")
local structure2 = require("morphology2")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		structure2,
	}
}

data = api.builderbot_utils_data -- for data editor check

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("builderbot")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)

	--robot.lift_system.set_position(robot.api.constants.lift_system_upper_limit)

	bt = BT.create
	{type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns, {connector_recruit_only_necessary = {structure1, structure2}}),
		vns.Driver.create_driver_node(vns),
	}}
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	--logger(robot.radios.wifi.recv)
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})

	for id, robot in pairs(vns.connector.seenRobots) do
		vns.api.debug.drawArrow("blue", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(robot.positionV3), true)
	end

	for id, block in pairs(vns.avoider.blocks) do
		vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)
	end
end

function destroy()
	api.destroy()
end
