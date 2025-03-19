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
Transform = require("Transform")

line_block_type = tonumber(robot.params.line_block_type)
obstacle_block_type = tonumber(robot.params.obstacle_block_type)
reference_block_type = tonumber(robot.params.reference_block_type)

----- data
local bt
local structure1 = require("morphology1")
--local structure2 = require("morphology2")
--local structure3 = require("morphology3")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		--structure2,
		--structure3,
	}
}

data = api.builderbot_utils_data -- for data editor check
api.builderbot_utils_data.structures = {}

state = "pickup"
substate = "left"
pick_place_state = "pickup"
stateCount = 0

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

	robot.lift_system.set_position(robot.api.constants.lift_system_upper_limit)

	bt = BT.create
	{type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns, {connector_recruit_only_necessary = gene.children}),
		vns.Learner.create_learner_node(vns),
		create_navigation_node(vns),
		create_approach_and_driver_node(vns),
	}}

	setup_false_push_node(vns)

	vns.Parameters.dangerzone_pipuck = 0.40
	vns.Parameters.dangerzone_block = 0.40
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	--logger(robot.radios.wifi.recv)
	api.preStep()
	robot.api.process_structures(api.builderbot_utils_data.structures, api.builderbot_utils_data.blocks)
	vns.preStep(vns)

	bt()

	vns.Learner.spreadKnowledge(vns, "push_node", vns.learner.knowledges["push_node"])

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame(true)
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
	local function sendChilrenNewState(vns, newState, newSubstate)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState, substate = newSubstate})
		end
	end

	function newState(vns, _newState, _newSubstate)
		stateCount = 0
		state = _newState
		substate = _newSubstate
	end

	local function switchAndSendNewState(vns, _newState, _newSubstate)
		newState(vns, _newState, _newSubstate)
		sendChilrenNewState(vns, _newState, _newSubstate)
	end
return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state, msgM.dataT.substate)
	end end

	-- get reference block
	reference_block = nil
	local reference_block_acc = Transform.createAccumulator()
	-- spread reference block
	for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
		Transform.addAccumulator(reference_block_acc, block)
	end end
	if reference_block_acc.n ~= 0 then
		reference_block = Transform.averageAccumulator(reference_block_acc)
	end

	-- receive reference block
	if vns.parentR ~= nil and reference_block == nil then
		for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "downstream_reference")) do
			reference_block = {
				positionV3 = vns.parentR.positionV3 + vector3(msgM.dataT.reference_block.positionV3):rotate(vns.parentR.orientationQ),
				orientationQ = vns.parentR.orientationQ * msgM.dataT.reference_block.orientationQ,
			}
			break
		end 
	end

	if reference_block ~= nil then
		vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(reference_block.positionV3), true)
	end

	-- state machine
	if state == "push_obstacle" then
		newState(vns, "clearing_obstacle", "left")
	elseif state == "clearing_obstacle" then
		if substate == "left" and reference_block ~= nil then
			-- anchor point to the left
			local shadow = vector3(1,0,0):rotate(reference_block.orientationQ):dot(-reference_block.positionV3)
			local anchor_point = reference_block.positionV3 + vector3(1,0,0):rotate(reference_block.orientationQ) * shadow
			vns.setGoal(vns, anchor_point, vns.goal.orientationQ)
			vns.api.debug.drawArrow("255,255,0", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(anchor_point), true)
			if anchor_point:length() < 0.35 then
				substate = "right"
			end
			-- keep a distance to push line
			local push_line_block = nil
			local min_dis = math.huge
			for id, block in pairs(vns.avoider.blocks) do
				if block.type == line_block_type and block.positionV3:length() < min_dis then
					push_line_block = block
					min_dis = block.positionV3:length()
				end
			end
			if push_line_block ~= nil then
				local dirV3 = vector3(1,0,0):rotate(reference_block.orientationQ)
				local target = push_line_block.positionV3 + dirV3 * 0.5
				local target_shadow = target:dot(dirV3)
				local target_shadow_V3 = target:dot(dirV3) * dirV3
				vns.goal.transV3 = vns.goal.transV3 + target_shadow_V3 * 0.05
			end
		elseif substate == "right" and reference_block ~= nil then
			-- anchor point to the left
			local shadow = vector3(1,0,0):rotate(reference_block.orientationQ):dot(-reference_block.positionV3)
			local anchor_point = reference_block.positionV3 + vector3(1,0,0):rotate(reference_block.orientationQ) * shadow
			local anchor_point = anchor_point + vector3(0,1,0):rotate(reference_block.orientationQ) * 7
			vns.setGoal(vns, anchor_point, vns.goal.orientationQ)
			vns.api.debug.drawArrow("255,255,0", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(anchor_point), true)
			if anchor_point:length() < 0.35 then
				substate = "left"
			end
			-- keep a distance to push line
			local push_line_block = nil
			local min_dis = math.huge
			for id, block in pairs(vns.avoider.blocks) do
				if block.type == line_block_type and block.positionV3:length() < min_dis then
					push_line_block = block
					min_dis = block.positionV3:length()
				end
			end
			if push_line_block ~= nil then
				local dirV3 = vector3(1,0,0):rotate(reference_block.orientationQ)
				local target = push_line_block.positionV3 + dirV3 * 0.5
				local target_shadow = target:dot(dirV3)
				local target_shadow_V3 = target:dot(dirV3) * dirV3
				vns.goal.transV3 = vns.goal.transV3 + target_shadow_V3 * 0.05
			end
		end
	end

	return false, true
end end

function create_approach_and_driver_node(vns)
	local function create_checking_node()
		return function() 
			-- find target type
			local target_type = nil
			local target_offset = nil
			if pick_place_state == "pickup" then
				target_type = obstacle_block_type
				target_offset = vector3(0,0,0)
			elseif pick_place_state == "place" then
				target_type = reference_block_type
				target_offset = vector3(0,0,1)
			end

			local find_flag = false
			print("target_type = ", target_type)
			for id, block in pairs(api.builderbot_utils_data.blocks) do
				if block.type == target_type and block.position_robot.z < 0.055 then
					print("got a hit ")
					-- check it is the only one in the structure
					local the_structure = nil
					for structure_id, structure in ipairs(api.builderbot_utils_data.structures) do
						for block_in_structure_id, block_in_structure in ipairs(structure) do
							if block_in_structure.id == block.id then the_structure = structure; break end
						end
						if the_structure ~= nil then break end
					end
					if #the_structure == 1 then
						find_flag = true
						data.target = {id = id, offset = target_offset}
						break
					else
						data.target = nil 
					end
				end
			end
			if find_flag == true then
				return false, true
			end
			return false, false
		end
	end
return
	{type = "selector*", children = {
		{type = "sequence", children = {
			{type = "negate", children = {create_checking_node()}},
			vns.Driver.create_driver_node(vns),
		}},
		{type = "sequence", children = {
			function() return false, pick_place_state == "pickup" end,
			{type = "sequence*", children = {
				robot.nodes.create_approach_block_node(data, create_checking_node(), 0.22),
				robot.nodes.create_pick_up_block_node(data, 0.220), --0.170 for old motor hardware
				function()
					pick_place_state = "place"
					robot.lift_system.set_position(robot.api.constants.lift_system_upper_limit)
					substate = "left"
					return false, true
				end,
			}},
		}},
		{type = "sequence", children = {
			function() return false, pick_place_state == "place" end,
			{type = "sequence*", children = {
				robot.nodes.create_approach_block_node(data, create_checking_node(), 0.24),
				robot.nodes.create_place_block_node(data, 0.24), --0.170 for old motor hardware
				robot.nodes.create_timer_node(2, function() robot.api.move.with_velocity(-0.02, -0.02) end),
				--robot.nodes.create_timer_node(5, function() robot.api.move.with_velocity( 0.02, -0.02) end),
				function()
					pick_place_state = "pickup"
					robot.lift_system.set_position(robot.api.constants.lift_system_upper_limit)
					return false, true
				end,
			}},
		}},
	}}
end