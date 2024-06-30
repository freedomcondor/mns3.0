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

line_block_type = tonumber(robot.params.line_block_type)
obstacle_block_type = tonumber(robot.params.obstacle_block_type)
reference_block_type = tonumber(robot.params.reference_block_type)

----- data
local bt
local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		structure2,
		structure3,
	}
}

data = api.builderbot_utils_data -- for data editor check
state = "pickup"

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
		vns.create_vns_core_node(vns, {connector_recruit_only_necessary = gene.children}),
		vns.Learner.create_learner_node(vns),
		create_navigation_node(vns),
		create_approach_and_driver_node(vns),
	}}

	setup_false_push_node(vns)
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	--logger(robot.radios.wifi.recv)
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.Learner.spreadKnowledge(vns, "push_node", vns.learner.knowledges["push_node"])

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	api.destroy()
end

function setup_false_push_node(vns)
	vns.learner.knowledges["push_node"] = {hash = 2, rank = 2, node = [[
	function()
		newState(vns, "step_back")
	end
	]]}
end

function create_navigation_node(vns)
return function()
	if vns.parentR ~= nil then
		local target_type = nil
		if state == "pickup" then
			target_type = center_block_type
		elseif state == "place" then
			target_type = pickup_block_type
		end
		-- find pickup block
		local target_block = nil
		for i, block in ipairs(vns.avoider.blocks) do
			if block.type == target_type then
				target_block = block
				break
			end
		end
		if target_block ~= nil then
			vns.setGoal(vns, target_block.positionV3, quaternion())
		end
	end
	return false, true
end end

function create_approach_and_driver_node(vns)
return
	{type = "selector*", children = {
		{type = "sequence", children = {
			function() 
				-- find target type
				local target_type = nil
				local target_offset = nil
				if state == "pickup" then
					target_type = obstacle_block_type
					target_offset = vector3(0,0,0)
				elseif state == "place" then
					target_type = reference_block_type
					target_offset = vector3(0,0,1)
				end

				local find_flag = false
				for id, block in pairs(api.builderbot_utils_data.blocks) do
					if block.type == target_type then
						find_flag = true
						data.target = {id = id, offset = target_offset}
						break
					end
				end
				if find_flag == true then
					return false, false
				end
				return false, true 
			end,
			vns.Driver.create_driver_node(vns),
		}},
		{type = "sequence", children = {
			function() return false, state == "pickup" end,
			{type = "sequence*", children = {
				robot.nodes.create_approach_block_node(data, function() return false, true end, 0.22),
				robot.nodes.create_pick_up_block_node(data, 0.240), --0.170 for old motor hardware
				function() state = "place" end,
			}},
		}},
		{type = "sequence", children = {
			function() return false, state == "place" end,
			{type = "sequence*", children = {
				robot.nodes.create_approach_block_node(data, function() return false, true end, 0.22),
				robot.nodes.create_place_block_node(data, 0.235), --0.170 for old motor hardware
				robot.nodes.create_timer_node(2, function() robot.api.move.with_velocity(-0.02, -0.02) return false, true end),
				function()
					state = "finish"
					setup_start_to_push_node(vns)
				end,
			}},
		}},
	}}
end