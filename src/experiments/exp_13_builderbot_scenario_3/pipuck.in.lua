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

obstacle_block_type = tonumber(robot.params.obstacle_block_type)
reference_block_type = tonumber(robot.params.reference_block_type)

special_pipuck = robot.params.special_pipuck

--local state
state = "forward"
if robot.id == special_pipuck then
	state = "wait_to_help"
end
stateCount = 0


local structure = require("morphology")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure,
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
	vns.setMorphology(vns, structure)
	bt = BT.create(vns.create_vns_node(vns, {
		connector_recruit_only_necessary = gene.children,
		navigation_node_post_core = {type = "sequence", children = {
			vns.Learner.create_learner_node(vns),
			{type = "selector", children = {
				create_navigation_node(vns),
				vns.Learner.create_knowledge_node(vns, "move_forward"),
			}}
		}}
	}))

	if robot.id == special_pipuck then
		setup_special_move_node(vns)
	else
		setup_move_node(vns)
	end
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, state, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	if robot.id == special_pipuck then
		vns.Learner.spreadKnowledge(vns, "move_forward", vns.learner.knowledges["move_forward"])
	end

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false, margin = 0.01})

	vns.state = state
	vns.logLoopFunctionInfo(vns)

	RecruitLogger:step(vns.Msg.waitToSend)

	for id, block in ipairs(vns.avoider.blocks) do
		vns.api.debug.drawCustomizeArrow("255,255,0", vector3(), vns.api.virtualFrame.V3_VtoR(block.positionV3),
		 0.01, 0.015, 1, true)
	end
	if state == "send_help" then
		api.pipuckShowAllLEDs()
	end
end

function destroy()
	vns.destroy()
	api.destroy()

	RecruitLogger:destroy()
end

function sendChilrenNewState(vns, newState, newSubstate)
	for idS, childR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "switch_to_state", {state = newState, substate = newSubstate})
	end
end

function newState(vns, _newState, _newSubstate)
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

function create_navigation_node(vns)
return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state, msgM.dataT.substate)
	end end

	if state == "send_help" then
		vns.Msg.send("ALLMSG", "help")
	end

	-- brain check meet obstacle
	if vns.parentR == nil and robot.id ~= special_pipuck then
		if state == "forward" then
			-- check obstacle existence
			for id, block in ipairs(vns.avoider.blocks) do if block.type == obstacle_block_type then
				if block.positionV3.x < 0.2 then
					switchAndSendNewState(vns, "meet_obstacle")
				end
			end end
		elseif state == "meet_obstacle" then
			if stateCount > 100 then
				switchAndSendNewState(vns, "send_help")
			end
		end
		return false, false -- go to move_forward_node
	end

	-- speical pipuck check help call
	if robot.id == special_pipuck and vns.parentR == nil then
		if state == "wait_to_help" then
			for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "help")) do
				state = "helping"
			end
		elseif state == "helping" then
			-- find nearest pipuck
			local nearest_pipuck = nil
			local dis = math.huge
			for idS, robotR in pairs(vns.connector.seenRobots) do
				if robotR.robotTypeS == "pipuck" and robotR.positionV3:length() < dis then
					nearest_pipuck = robotR
					dis = robotR.positionV3:length()
				end
			end
			if nearest_pipuck ~= nil then
				local dir = vector3(nearest_pipuck.positionV3):normalize()
				vns.Spreader.emergency_after_core(vns, dir * 0.01, vector3())
			else
				vns.Spreader.emergency_after_core(vns, vector3(0.02, 0, 0), vector3())
			end
		end
	end

	return false, true   -- do not go to forward node
end end

function setup_move_node(vns)
	vns.learner.knowledges["move_forward"] = {hash = 1, rank = 1, node = [[
	function()
		local left_right_speed = 0
		for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then

			local from_block_to_me = Transform.AxCis0(block)
			local right_dis = from_block_to_me.positionV3.y
			local target_dis = 0.8
			left_right_speed = (target_dis - right_dis) * 0.03

			vns.setGoal(vns, vector3(), block.orientationQ)
			vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)
			break
		end end

		vns.Spreader.emergency_after_core(vns, vector3(0.01, left_right_speed, 0), vector3())

		return false, true
	end
	]]}
end

function setup_special_move_node(vns)
	vns.learner.knowledges["move_forward"] = {hash = 2, rank = 2, node = [[
	function()
		print("special move node", robot.id)
		-- align with reference
		for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
			vns.setGoal(vns, vector3(), block.orientationQ)
			vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)
			break
		end end

		-- check block
		local front_existence = false
		for id, block in ipairs(vns.avoider.blocks) do if block.type == obstacle_block_type then
			if block.positionV3.x > 0 and block.positionV3.y < 0.3 then
				front_existence = true
				break
			end
		end end

		if front_existence == true then
			switchAndSendNewState(vns, "move_right")
			vns.Spreader.emergency_after_core(vns, vector3(0, -0.020, 0), vector3())
		else
			switchAndSendNewState(vns, "forward_2")

			local left_right_speed = 0
			for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
				local from_block_to_me = Transform.AxCis0(block)
				local right_dis = from_block_to_me.positionV3.y
				local target_dis = 0.2
				left_right_speed = (target_dis - right_dis) * 0.03
				break
			end end
			vns.Spreader.emergency_after_core(vns, vector3(0.01, left_right_speed, 0), vector3())
		end

		return false, true
	end
	]]}
end