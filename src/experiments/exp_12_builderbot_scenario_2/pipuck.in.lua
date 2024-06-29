if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")
Transform = require("Transform")
local RecruitLogger = require("RecruitLogger")

logger.enable()

local n_pipuck = 3

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

--local state
state = "wait_to_forward"
substate = nil
stateCount = 0
--local type_number_in_memory = 0
type_number_in_memory = 0

dangezone_block_backup = VNS.Parameters.dangerzone_block

line_block_type = tonumber(robot.params.line_block_type)
obstacle_block_type = tonumber(robot.params.obstacle_block_type)
reference_block_type = tonumber(robot.params.reference_block_type)

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

target_calcBaseValue = function(base, current, target)
	return (current - target):length()
end

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()

--	api.debug.show_all = true
	RecruitLogger:init(robot.id)
end

function reset()
	vns.reset(vns)
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure1)
	bt = BT.create(vns.create_vns_node(vns, {
		connector_recruit_only_necessary = gene.children,
		navigation_node_post_core = {type = "sequence", children = {
			vns.Learner.create_learner_node(vns),
			{type = "selector", children = {
				create_navigation_node(vns),
				vns.Learner.create_knowledge_node(vns, "push_node"),
			}}
		}}
	}))

	state = "wait_to_forward"

	setup_push_node(vns)
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, state, substate, "----------------------------")
	if vns.allocator.target ~= nil then
		logger("target.idN = ", vns.allocator.target.idN, "mission = ", vns.allocator.target.mission)
	end
	if vns.parentR ~= nil then
		logger("parent = ", vns.parentR.idS)
	end
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})

	vns.state = state
	if state == "consensus" then
		vns.state = state .. "_" .. type_number_in_memory
	end
	vns.logLoopFunctionInfo(vns)

	RecruitLogger:step(vns.Msg.waitToSend)

	for id, block in ipairs(vns.avoider.blocks) do
		vns.api.debug.drawCustomizeArrow("255,255,0", vector3(), vns.api.virtualFrame.V3_VtoR(block.positionV3),
		 0.01, 0.015, 1, true)
	end
end

function destroy()
	vns.destroy()
	api.destroy()

	RecruitLogger:destroy()
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

	local range = 0.7
	if state == "wait_to_forward" then
		if vns.parentR == nil then
			for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
				vns.setGoal(vns, vector3(), block.orientationQ)
				vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)
				break
			end end
			if stateCount > 50 and vns.driver.pipuck_arrive == true and vns.scalemanager.scale["pipuck"] == n_pipuck then
				switchAndSendNewState(vns, "forward")
			end
		end
	elseif state == "forward" then
		if vns.parentR == nil then
			for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
				vns.setGoal(vns, vector3(), block.orientationQ)
				vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)
				break
			end end

			if vns.scalemanager.scale["pipuck"] == n_pipuck then
				vns.Spreader.emergency_after_core(vns, vector3(0.01, 0, 0), vector3())
			end
		end
		local target = nil
		local mini_dis = math.huge
		-- iterate all type usual_block_type blocks that are far away from the center
		for id, block in pairs(vns.avoider.blocks) do if block.type == line_block_type and block.positionV3:length() < 0.25 then
			local there_is_a_robot_better_than_me = false
			for id, robot in pairs(vns.connector.seenRobots) do
				if robot.robotTypeS == "pipuck" and 
				   (robot.positionV3 - block.positionV3):length() < (block.positionV3):length() then
					there_is_a_robot_better_than_me = true
					break
				end
			end
			if there_is_a_robot_better_than_me == false and
			   block.positionV3:length() < mini_dis then
				mini_dis = block.positionV3:length()
				target = block
			end
		end end
		if target ~= nil then
			logger("target")
			logger(target)
			vns.Parameters.dangerzone_block = 0
			vns.setGoal(vns, target.positionV3, quaternion())
			vns.api.debug.drawArrow("0,255,255,0", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(target.positionV3), true)
			if target.positionV3:length() < 0.15 and
			   vns.scalemanager.scale["pipuck"] == n_pipuck then
				state = "wait_to_forward_2"
			end
		end
	elseif state == "wait_to_forward_2" then
		-- stop moving
		vns.setGoal(vns, vector3(), quaternion())
		vns.goal.transV3 = vector3()

		-- report up in position
		local number = 1
		-- receive in positioni number from children
		for idS, robotR in pairs(vns.childrenRT) do 
			local number_from_this_children = 0
			for _, msgM in ipairs(vns.Msg.getAM(idS, "in_position_to_push")) do
				number_from_this_children = msgM.dataT.number
				break
			end 
			number = number + number_from_this_children
		end
		-- report number to parent
		if vns.parentR ~= nil then
			vns.Msg.send(vns.parentR.idS, "in_position_to_push", {number = number})
		end

		print("Finally, I get number = ", number)

		if vns.parentR == nil and number == n_pipuck then
			switchAndSendNewState(vns, "forward_2")
		end
	elseif state == "forward_2" then
		if vns.goal.positionV3.x < -0.1 then
			vns.goal.positionV3.x = 0
		end
		if vns.parentR == nil then
			local left_right_speed = 0
			for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
				local from_block_to_me = Transform.AxCis0(block)
				local right_dis = from_block_to_me.positionV3.y
				local target_dis = 0.6
				left_right_speed = (target_dis - right_dis) * 0.03
				vns.setGoal(vns, vector3(), block.orientationQ)
				vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)
				break
			end end
			vns.Spreader.emergency_after_core(vns, vector3(0.01, left_right_speed, 0), vector3())

			for id, block in pairs(vns.avoider.blocks) do if block.type == obstacle_block_type and block.positionV3:length() < 0.5 then
				switchAndSendNewState(vns, "push_obstacle")
			end end
		end
	elseif state == "push_obstacle" then
		vns.Allocator.calcBaseValue = target_calcBaseValue
		if vns.allocator.target.mission == "pusher" then
			vns.Parameters.dangerzone_block = dangezone_block_backup
			state = "push"
			substate = "go_to_anchor"
		else
			state = "step_back"
		end
	elseif state == "step_back" then
		-- find nearest_block
		local nearest_block = nil
		local dis = math.huge
		for id, block in pairs(vns.avoider.blocks) do if block.type == line_block_type and block.positionV3:length() < dis then
			nearest_block = block
			dis = block.positionV3:length()
		end end
		if nearest_block ~= nil then
			local dir = vector3(nearest_block.positionV3):normalize()
			local anchor_point = nearest_block.positionV3 - dir * 0.3
			vns.setGoal(vns, anchor_point, quaternion())
			if anchor_point:length() < 0.1 then
				state = "wait_for_obstacle_clearance"
			end
		end
	elseif state == "wait_for_obstacle_clearance" then
		-- stop moving
		vns.setGoal(vns, vector3(), quaternion())
		vns.goal.transV3 = vector3()
		if vns.parentR == nil then
			-- find a reference
			local reference = nil
			for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
				reference = block
				vns.setGoal(vns, vector3(), block.orientationQ)
				break
			end end
			if reference ~= nil then
				local obstacle_existance = false
				for id, block in pairs(vns.avoider.blocks) do if block.type == obstacle_block_type then
					-- calc reference to block
					local reference_to_block = {}
					Transform.AxCisB(reference, block, reference_to_block)
					if reference_to_block.positionV3.y > 0.20 then
						obstacle_existance = true
						break
					end
				end end
				if obstacle_existance == false and vns.driver.pipuck_arrive == true and vns.scalemanager.scale["pipuck"] == n_pipuck then
					stateCount = stateCount + 1
				else
					stateCount = 0
				end
				if stateCount == 10 then
					switchAndSendNewState(vns, "forward")
				end
			end
		end
	elseif state == "push" then -- only pusher will enter this state
		return false, false
	end

	return false, true
end end

function setup_push_node(vns)
	vns.learner.knowledges["push_node"] = {hash = 1, rank = 1, node = [[
	function()
		-- find a reference
		local reference = nil
		for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
			reference = block
		end end
		if reference ~= nil then
			vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(reference.positionV3), true)
			--logger("reference block position: = ", reference.positionV3)
			--logger("reference block direction : X = ", vector3(1,0,0):rotate(reference.orientationQ))
			--logger("reference block direction : Y = ", vector3(0,1,0):rotate(reference.orientationQ))
			--logger("reference block direction : Z = ", vector3(0,0,1):rotate(reference.orientationQ))

			-- find a target
			local target = nil
			local mini_dis = math.huge
			for id, block in pairs(vns.avoider.blocks) do if block.type == obstacle_block_type then
				-- calc reference to block
				local reference_to_block = {}
				Transform.AxCisB(reference, block, reference_to_block)
				local threshold = 0.2
				if substate == "start_push" then threshold = 0.1 end
				if reference_to_block.positionV3.y > threshold and block.positionV3:length() < mini_dis then
					mini_dis = block.positionV3:length()
					target = block
				end
			end end

			if target ~= nil then
				vns.api.debug.drawArrow("black", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(target.positionV3), true)
				--logger("target block position: = ", target.positionV3)
				--logger("target block direction : X = ", vector3(1,0,0):rotate(target.orientationQ))
				--logger("target block direction : Y = ", vector3(0,1,0):rotate(target.orientationQ))
				--logger("target block direction : Z = ", vector3(0,0,1):rotate(target.orientationQ))

				if substate == "go_to_anchor" then
					vns.Parameters.dangerzone_block = dangezone_block_backup

					local anchor_point = target.positionV3 + vector3(0,1,0):rotate(reference.orientationQ) * 0.3
					vns.api.debug.drawArrow("0,255,255,0", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(anchor_point), true)
					vns.setGoal(vns, anchor_point, quaternion())
					if anchor_point:length() < 0.1 then
						substate = "start_push"
					end
				elseif substate == "start_push" then
					vns.Parameters.dangerzone_block = 0

					local anchor_point = target.positionV3 - vector3(0,1,0):rotate(reference.orientationQ) * 0.5
					vns.api.debug.drawArrow("0,255,255,0", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(anchor_point), true)
					vns.setGoal(vns, anchor_point, quaternion())

					local offset = vector3(0,-1,0):rotate(reference.orientationQ) * 0.1
					if (target.positionV3 + offset):dot(reference.positionV3) < 0 then
						substate = "go_to_anchor"
					end
				end
			else
				vns.Parameters.dangerzone_block = dangezone_block_backup
			end
		else
			vns.setGoal(vns, vector3(), quaternion())
		end
	end
	]]}
end