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
robot.logger:set_verbosity(2)

local BT = require("BehaviorTree")
local bt

local data = {blocks = {}}

function init()
	reset()
	robot.camera_system.enable()
end

function reset()
	bt = BT.create
	{
		type = "sequence",
		children = {
			robot.nodes.create_aim_block_node(data, {case = nil, forward_backup = nil}),
		}
	}
end

function step()
	robot.api.process_blocks(data.blocks)

	logger("--------------------")
	logger("tags")
	logger(robot.camera_system.tags)
	logger("blocks")
	logger(data.blocks)

	data.target = {id = #data.blocks}
	bt()
end

function destroy()
	robot.camera_system.disable()
end