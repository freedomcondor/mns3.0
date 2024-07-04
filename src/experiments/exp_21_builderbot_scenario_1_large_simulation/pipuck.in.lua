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

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

--local state
state = "consensus"
substate = nil
stateCount = 0
--local type_number_in_memory = 0
type_number_in_memory = 0

--dangezone_block_backup = VNS.Parameters.dangerzone_block
dangezone_block_backup = 0.30

center_block_type = tonumber(robot.params.center_block_type)
usual_block_type = tonumber(robot.params.usual_block_type)
pickup_block_type = tonumber(robot.params.pickup_block_type)

normal_pipuck_number = 8
special_pipuck = false
local robotType, number = string.match(robot.id, "(%a+)(%d+)")
if tonumber(number) > normal_pipuck_number then special_pipuck = true end

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

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()

	RecruitLogger:init(robot.id)
--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure1)
	bt = BT.create(vns.create_vns_node(vns, {
		connector_recruit_only_necessary = gene.children,
		navigation_node_pre_core = create_consensus_node(vns),
		navigation_node_post_core = {type = "sequence", children = {
			vns.Learner.create_learner_node(vns),
			{type = "selector", children = {
				create_navigation_node(vns),
				vns.Learner.create_knowledge_node(vns, "wait_to_push_node"),
				vns.Learner.create_knowledge_node(vns, "push_node"),
				--create_push_node(vns),
			}},
			--create_dismiss_node(vns),
		}}
	}))

	state = "consensus"

	if special_pipuck == true then
		setup_push_node(vns)
		setup_wait_to_push_node(vns)
	end
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, state, substate, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	if special_pipuck == true then
		vns.Learner.spreadKnowledge(vns, "push_node", vns.learner.knowledges["push_node"])
		vns.Learner.spreadKnowledge(vns, "wait_to_push_node", vns.learner.knowledges["wait_to_push_node"])
	end

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false}, true)

	vns.state = state
	if state == "consensus" then
		vns.state = state .. "_" .. type_number_in_memory
	end
	vns.logLoopFunctionInfo(vns)

	RecruitLogger:step(vns.Msg.waitToSend)

	--[[
	for id, block in ipairs(vns.avoider.blocks) do
		vns.api.debug.drawCustomizeArrow("255,255,0", vector3(), vns.api.virtualFrame.V3_VtoR(block.positionV3),
		 0.01, 0.015, 1, true)
	end
	--]]
end

function destroy()
	vns.destroy()
	api.destroy()

	RecruitLogger:destroy()
end

function create_dismiss_node(vns)
return function()
	if vns.parentR == nil then
		local targetPipuckScale = vns.allocator.target.scale["pipuck"] or 0
		local currentPipuckScale = vns.scalemanager.scale["pipuck"] or 0
		if currentPipuckScale > targetPipuckScale then
			for idS, robotR in pairs(vns.childrenRT) do
				if robotR.robotTypeS == "pipuck" and
				   robotR.scalemanager.scale:totalNumber() == 1 then
					vns.Msg.send(idS, "dismiss")
					vns.Connector.deleteChild(vns, idS)
				end
			end
		end

		local targetDroneScale = vns.allocator.target.scale["drone"] or 0
		local currentDroneScale = vns.scalemanager.scale["pipuck"] or 0
		if currentDroneScale > targetDroneScale then
			for idS, robotR in pairs(vns.childrenRT) do
				if robotR.robotTypeS == "drone" and
				   robotR.scalemanager.scale:totalNumber() == 1 then
					vns.Msg.send(idS, "dismiss")
					vns.Connector.deleteChild(vns, idS)
				end
			end
		end
	end
	return false, true
end
end

function create_consensus_node(vns)
local types_index = {}
return function()
	if state ~= "consensus" then return false, true end
	local range = 1.0
	-- check neighbour blocks
	for id, block in pairs(vns.avoider.blocks) do
		if block.positionV3:length() < range then
			--vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)

			-- check type exist
			if types_index[block.type] == nil then
				types_index[block.type] = true
			end
		end
	end

	-- receive consensus
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "consensus")) do
		for id, value in pairs(msgM.dataT.types_index) do
			types_index[id] = value
		end
	end

	local type_number = 0
	for i, v in pairs(types_index) do
		type_number = type_number + 1
	end

	type_number_in_memory = type_number

	-- draw type_number
	for i = 1, type_number do
		vns.api.debug.drawRing("black", vector3(0,0,0.15 + 0.06 * i), 0.04, true)
	end

	logger("type_number = ", type_number)

	-- send to neighbour pipucks
	for id, robot in pairs(vns.connector.seenRobots) do
		if robot.positionV3:length() < range then
			--vns.api.debug.drawArrow("black", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(robot.positionV3), true)

			vns.Msg.send(id, "consensus", {types_index = types_index})
		end
	end
	
	return false, true
end end

function create_navigation_node(vns)
	local function sendChilrenNewState(vns, newState, newSubstate)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState, substate = newSubstate})
		end
	end

	local function newState(vns, _newState, _newSubstate)
		stateCount = 0
		state = _newState
		if _newSubstate ~= "KEEP" then
			substate = _newSubstate
		end
	end

	function switchAndSendNewState(vns, _newState, _newSubstate)
		newState(vns, _newState, _newSubstate)
		sendChilrenNewState(vns, _newState, _newSubstate)
	end

return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state, msgM.dataT.substate)
	end end

	local range = 2.5
	local desired_distance = 1
	if state == "consensus" and vns.parentR == nil and special_pipuck ~= true then
		vns.Parameters.avoider_brain_exception = false
		vns.Parameters.dangerzone_block = 0.2

		-- check usual_block_type block to find direction
		local usual_block_type = nil
		for id, block in pairs(vns.avoider.blocks) do
			vns.setGoal(vns, vector3(), block.orientationQ)
		end

		vns.Spreader.emergency_after_core(vns, vector3(0.03, 0, 0), vector3())

		for id, robot in pairs(vns.connector.seenRobots) do if robot.robotTypeS == "pipuck" then
			-- check special pipuck
			local seen_special_pipuck = false
			local robotType, number = string.match(robot.idS, "(%a+)(%d+)")
			if tonumber(number) > normal_pipuck_number then seen_special_pipuck = true end
			-- flocking
			if seen_special_pipuck == false and robot.positionV3:length() < range then
				local dir = vector3(robot.positionV3):normalize()
				local speed = (robot.positionV3:length() - desired_distance) * 0.05
				--if speed > 0.03 then speed = 0.03 end
				local velocity = dir * speed
				vns.Spreader.emergency_after_core(vns, velocity, vector3())
				--vns.api.debug.drawArrow("blue", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(robot.positionV3), true)
			end
		end end

		-- state switch
		for id, robot in pairs(vns.connector.seenRobots) do
			if robot.robotTypeS == "builderbot" and robot.positionV3:length() < 1.0 then
				if type_number_in_memory == 2 then
					vns.setMorphology(vns, structure2)
				elseif type_number_in_memory == 3 then
					vns.setMorphology(vns, structure3)
				end
				--vns.Parameters.avoider_brain_exception = true
				vns.idN = vns.idN + 1
				switchAndSendNewState(vns, "start_mns")
			end
		end
	elseif state == "start_mns" and vns.parentR == nil then
		sendChilrenNewState(vns, "start_mns")
		if stateCount >= 100 and vns.driver.pipuck_arrive == true then
			switchAndSendNewState(vns, "start_push", "go_to_anchor")
		end

		--if stateCount >= 300 and vns.scalemanager.scale["pipuck"] < 12 then
		--	vns.setMorphology(vns, structure2_small)
		--end

		-- get center block and anchor myself
		local center = nil
		-- iterate all type center_block_type blocks
		for id, block in pairs(vns.avoider.blocks) do if block.type == center_block_type then
			center = block
		end end
		-- if I see center block
		if center ~= nil then
			--if vns.scalemanager.scale["pipuck"] == 8 then
			--	local ori = Transform.fromToQuaternion(vector3(-1, 0, 0), center.positionV3)
			--	vns.setGoal(vns, center.positionV3 + vector3(0,-0.65,0):rotate(center.orientationQ), ori)
			--else
				--local ori = Transform.fromToQuaternion(vector3(-1, 0, 0), center.positionV3)
				--vns.setGoal(vns, center.positionV3 + vector3(0,1.9,0):rotate(center.orientationQ), ori)
				vns.setGoal(vns, center.positionV3 + vector3(1.9, 0, 0):rotate(center.orientationQ), center.orientationQ)
			--end
		end
	elseif state == "start_push" then
		if vns.parentR == nil then
			switchAndSendNewState(vns, "start_push", "KEEP")
			-- get center block
			local center = nil
			-- iterate all type center_block_type blocks
			for id, block in pairs(vns.avoider.blocks) do if block.type == center_block_type then
				center = block
			end end
			if center ~= nil then
				--local ori = Transform.fromToQuaternion(vector3(-1, 0, 0), center.positionV3)
				--vns.setGoal(vns, center.positionV3 + vector3(0,1.9,0):rotate(center.orientationQ), ori)
				vns.setGoal(vns, center.positionV3 + vector3(1.9, 0, 0):rotate(center.orientationQ), center.orientationQ)
			end
		end
		return false, false
	end
	return false, true
end end

function setup_wait_to_push_node(vns)
	vns.learner.knowledges["wait_to_push_node"] = {hash = 1, rank = 1, node = [[
	function()
		return false, false
	end
	]]}
end

--function create_push_node(vns)
--return

function setup_push_node(vns)
	vns.learner.knowledges["push_node"] = {hash = 1, rank = 1, node = [[
	function()
		-- get center block
		local center = nil
		-- iterate all type center_block_type blocks
		for id, block in pairs(vns.avoider.blocks) do if block.type == center_block_type then
			center = block
		end end
		-- if I see center block
		if center ~= nil then
			if vns.parentR == nil then
				--local dir = vector3(-center.positionV3):normalize()
				--local ori = Transform.fromToQuaternion(vector3(-1, 0, 0), center.positionV3)
				--vns.setGoal(vns, center.positionV3 + dir * 0.45, ori)
				return false, true
			end
			vns.api.debug.drawCustomizeArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(center.positionV3),
			                                 0.01, 0.015, 1, true)
			-- choose a target
			local mini_dis = math.huge
			local target = nil
			-- iterate all type usual_block_type blocks that are far away from the center
			local threshold = 0.35
			if substate == "push" then threshold = 0.30 end
			for id, block in pairs(vns.avoider.blocks) do 
				if block.type == usual_block_type and (block.positionV3 - center.positionV3):length() > threshold then
				local there_is_a_robot_better_than_me = false
				for id, robotR in pairs(vns.connector.seenRobotsInMemory) do
					if robotR.robotTypeS == "pipuck" and 
					   robotR.idS ~= vns.idS then  -- brain is not included
						local hisDis_myDis = (robotR.positionV3 - block.positionV3):length() - (block.positionV3):length()
						local threshold = 0.0
						if hisDis_myDis < -threshold then
							there_is_a_robot_better_than_me = true
							break
						end
					end
				end
				if there_is_a_robot_better_than_me == false and
				   block.positionV3:length() < mini_dis then
					mini_dis = block.positionV3:length()
					target = block
				end
			end end

			-- if I have a target block
			if target ~= nil then
				vns.api.debug.drawArrow("black", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(target.positionV3), true)

				if substate == "go_to_anchor" then
					local dir = (target.positionV3 - center.positionV3):normalize()
					if target.positionV3:dot(center.positionV3) < 0 then
						if vector3(target.positionV3):cross(center.positionV3).z > 0 then
							dir:rotate(quaternion(-math.pi/3, vector3(0,0,1)))
						else
							dir:rotate(quaternion( math.pi/3, vector3(0,0,1)))
						end
					end
					local anchor_point = target.positionV3 + dir * 0.3
					vns.Parameters.dangerzone_block = dangezone_block_backup 
					vns.setGoal(vns, anchor_point, quaternion())
					vns.api.debug.drawArrow("0,255,255,0", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(anchor_point), true)
					if anchor_point:length() < 0.10 then
						substate = "push"
					end
				elseif substate == "push" then
					vns.Parameters.dangerzone_block = 0
					vns.setGoal(vns, center.positionV3, quaternion())
					-- check if a new target is selected
					if old_target_position == nil then old_target_position = target.positionV3 end
					if target.positionV3:dot(center.positionV3) < 0 or
					   (target.positionV3 - old_target_position):length() > 0.10 then -- another target is selected
						substate = "go_to_anchor"
						vns.Parameters.dangerzone_block = dangezone_block_backup
					end
					old_target_position = target.positionV3
				end
			else
				substate = "go_to_anchor"
				vns.Parameters.dangerzone_block = dangezone_block_backup
			end
		end

		return false, true
	end
	]]}
end