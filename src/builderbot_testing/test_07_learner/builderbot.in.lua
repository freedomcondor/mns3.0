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
local structure = require("morphology")

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
	vns.setGene(vns, structure)

	--robot.lift_system.set_position(robot.api.constants.lift_system_upper_limit)

	bt = BT.create
	{type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		-- learner
		vns.Learner.create_learner_node(vns),
		{type = "selector", children = {
			function()
				if data.state == "place" then
					return false, true
				else
					return false, false
				end
			end,
			vns.Learner.create_knowledge_node(vns, "move_forward"),
		}},
		-- if I see a block, pickup, otherwise follow mns driver
		{type = "selector*", children = {
			{type = "sequence", children = {
				function() 
					--return false, false
					if #api.builderbot_utils_data.blocks ~= 0 then
						return false, false
					end
					return false, true 
				end,
				vns.Driver.create_driver_node(vns),
			}},
			{type = "sequence*", children = {
				robot.nodes.create_approach_block_node(data, function() data.target = {id = 1, offset = vector3(0,0,0)} end, 0.20),
				robot.nodes.create_pick_up_block_node(data, 0.20), --0.170 for old motor hardware
				function() data.state = "place" end,
			}},
		}}
	}}
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	logger(robot.radios.wifi.recv)
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})

	logger("seenRobots--------")
	logger(vns.connector.seenRobots)
	logger("connector---------")
	logger(vns.connector)
	logger("parent------------")
	logger(vns.parentR)
	logger("children----------")
	logger(vns.childrenRT)
	logger("goal--------------")
	logger(vns.goal)
end

function destroy()
	api.destroy()
end
