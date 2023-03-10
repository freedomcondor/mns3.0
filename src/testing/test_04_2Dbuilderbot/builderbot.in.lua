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
robot.vns_api = api
local BT = require("BehaviorTree")

----- data
local bt
data = api.builderbot_utils_data -- for data editor

local rules = {
	selection_method = 'nearest_win',
	list = {
		-- pickup a type 0 (black) block
		-- turn the block type 4 (blue) when picking up it
		{
			rule_type = 'pickup',
			structure = {
				{
					index = vector3(0, 0, 0),
					type = 0
				},
			},
			target = {
				reference_index = vector3(0, 0, 0),
				offset_from_reference = vector3(0, 0, 0),
				type = 4,
			},
		},
		-- place a block in front of a type 1 (pink) block
		-- turn the block type 1 (pink) when placing it
		{
			rule_type = 'place',
			structure = {
				{
					index = vector3(0, 0, 0),
					type = 1,
				},
			},
			target = {
				reference_index = vector3(0, 0, 0),
				offset_from_reference = vector3(1, 0, 0),
				type = 1
			},
		},
	}, -- end of rule.list
 } -- end of rules

function init()
	--api.linkRobotInterface(VNS)
	api.init() 
	robot.logger:set_verbosity(2)
	api.debug.show_all = true

	reset()
end

function reset()
	bt = BT.create
	{
		type = "sequence*",
		children = {
			robot.nodes.create_pick_up_behavior_node(data, rules),
			robot.nodes.create_place_behavior_node(data, rules),
		}
	 }
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()

	bt()

	api.postStep()
	api.debug.showVirtualFrame()
end

function destroy()
	api.destroy()
end
