if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
	package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/builderbot-utils/?.lua"
	assert(loadfile(                "@CMAKE_SOURCE_DIR@/core/api/builderbot-utils/init.lua"))()
else
	package.path = package.path .. ";/home/root/builderbot-utils/?.lua"
	assert(loadfile("/home/root/builderbot-utils/init.lua"))()
end

logger = require("Logger")
logger.enable()
robot.logger:enable("nodes_aim_block")
robot.logger:enable("nodes_curved_approach_block")
robot.logger:set_verbosity(2)

local BT = require("BehaviorTree")
local bt

data = {blocks = {}, state = "pickup"}

function init()
	reset()
	robot.camera_system.enable()
end

function reset()
	bt = BT.create
	{type = "selector", children = {
		{type = "sequence", children = {
			function()
				print(data.state)
				if data.state == "pickup" then return false, true
				                          else return false, false
				end
			end,
			{type = "sequence*", children = {
				robot.nodes.create_approach_block_node(data, function() data.target = {id = 1, offset = vector3(0,0,0)} end, 0.22),
				robot.nodes.create_pick_up_block_node(data, 0.240), --0.165 for old motor hardware, new motor can use 20
				function() data.state = "place" end,
			}},
		}},
		{type = "sequence*", children = {
			robot.nodes.create_approach_block_node(data, function() data.target = {id = 1, offset = vector3(0,0,1)} end, 0.22),
			robot.nodes.create_place_block_node(data, 0.235),
			function() data.state = "pickup" end,
		}},
	}}
end

function step()
	robot.api.process_blocks(data.blocks)

	logger("--------------------")
	--logger("tags")
	--logger(robot.camera_system.tags)
	--logger("blocks")
	--logger(data.blocks)

	data.target = {id = #data.blocks}
	bt()
end

function destroy()
	robot.camera_system.disable()
end