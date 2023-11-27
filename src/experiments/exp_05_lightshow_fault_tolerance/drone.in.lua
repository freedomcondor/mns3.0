if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
Transform = require("Transform")

require("morphologyGenerateCube")
require("manGenerator")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)

local mainGroupNumber = 306

local structure_reinforcement_cube = generate_cube_morphology(87)

-- structure mans
local structure_mans = {}
local structure_mans_n = 4
local right_shoulder_Y_left = -20
local right_shoulder_Y_right = -5
local right_shoulder_Y_range = right_shoulder_Y_right - right_shoulder_Y_left
local right_shoulder_Y_step = right_shoulder_Y_range / (structure_mans_n - 1)
for i = 1, structure_mans_n do
	structure_mans[i] = create_body{
		right_shoulder_Z = 145,
		right_shoulder_Y = right_shoulder_Y_left + right_shoulder_Y_step * (i-1),
		right_fore_arm_Z = 15,
		right_fore_arm_Y = 25,
	}
end

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_reinforcement_cube,
	}
}

for i = 1, structure_mans_n do
	table.insert(gene.children, structure_mans[i])
end

-- overwrite default function
-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	if vns.allocator.target.second_brain == true then
		vns.Connector.newVnsID(vns, 1.5)
	end
	vns.Allocator.setMorphology(vns, structure_mans[1])
end

function api.debug.showMorphologyLines(vns, color)
	if vns.allocator ~= nil and vns.allocator.target.drawLines ~= nil then
		--local color = vns.allocator.target.drawLinesColor or "gray50"
		for i, vec in ipairs(vns.allocator.target.drawLines) do
			vns.api.debug.drawCustomizeArrow(color,
			                                 vector3(0,0,0),
			                                 vns.api.virtualFrame.V3_VtoR(vec),
			                                 0.10,
			                                 0.10,
			                                 1,
			                                 true)
		end
	end
end

function api.debug.showMorphologyLightShowLEDs(vns, color)
	api.debug.drawCustomizeRing(color, vector3(0,0,0.2), 0.25, 0.03, 0.03, 1, true)
	api.debug.drawHalo(color,
	                   vector3(0,0,0.2),
	                   0.125,           -- sphere radius
	                   0.7 + 0.125,     -- halo radius
	                   0.1,             -- max transparency
	                   true)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	local number = tonumber(string.match(robot.id, "%d+"))
	local base_height = api.parameters.droneDefaultStartHeight + 60
	if number > mainGroupNumber then
		base_height = base_height + 10
	end
	if number % 5 == 1 then
		api.parameters.droneDefaultStartHeight = base_height
	elseif number % 5 == 2 then
		api.parameters.droneDefaultStartHeight = base_height - 6
	elseif number % 5 == 3 then
		api.parameters.droneDefaultStartHeight = base_height - 12
	elseif number % 5 == 4 then
		api.parameters.droneDefaultStartHeight = base_height - 18
	elseif number % 5 == 0 then
		api.parameters.droneDefaultStartHeight = base_height - 24
	end
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 2 end
	if vns.idS == "drone" .. tostring(mainGroupNumber + 1) then vns.idN = 1.3 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure_mans[1])

	bt = BT.create(
		vns.create_vns_node(vns,
			{
				navigation_node_pre_core = {type = "sequence", children = {
					create_reinforcement_node(vns),
					create_failure_node(vns),
				}},
				navigation_node_post_core = {type = "selector", children = {
					create_reinforcement_navigation_node(vns),
					{type = "sequence", children = {
						vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
						create_navigation_node(vns),
						create_signal_node(vns),
					}},
				}},
			}
		)
	)

	lastTime = startTime
end



function step()
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	--api.debug.showVirtualFrame(true)
	--api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})

	--local LED_zone = vns.Parameters.driver_stop_zone * 10
	local LED_zone = vns.Parameters.driver_arrive_zone * 1.5
	-- show morphology lines
	--if vns.goal.positionV3:length() < LED_zone and vns.failed ~= true then
	--[[
	if vns.driver.all_arrive == true and
	   vns.failed ~= true and
	   vns.scalemanager.scale:totalNumber() > 3 then
		api.debug.showMorphologyLines(vns, true)
	end
	--]]

	local number = tonumber(string.match(robot.id, "%d+"))
	if vns.reinforcement == true then
		-- reinforcement team
		api.debug.showMorphologyLightShowLEDs(vns, "yellow")
	elseif vns.goal.positionV3:length() < LED_zone and
	       (vector3(1,0,0):rotate(vns.goal.orientationQ) - vector3(1,0,0)):length() < 0.1 and
	       vns.allocator.target.idN > 0 and
	       vns.failed ~= true and
	       vns.scalemanager.scale:totalNumber() > 5 then
		api.debug.showMorphologyLightShowLEDs(vns, "cyan")
		if vns.driver.all_arrive == true then
			api.debug.showMorphologyLines(vns, "cyan")
		end
	elseif vns.failed == true then
		api.debug.showMorphologyLightShowLEDs(vns, "red")
	else
		api.debug.showMorphologyLightShowLEDs(vns, "white")
	end

	if vns.parentR == nil then
		vns.api.virtualFrame.logicOrientationQ = quaternion()
	end

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end

local takeOffStep = 3000
local reinforceID = mainGroupNumber
local reinforceGroupNumber = 87

function create_reinforcement_node(vns)
	local number = tonumber(string.match(robot.id, "%d+"))
	if number > reinforceID then
		vns.reinforcement = true
	end
return function()
	if number > reinforceID then
		if vns.api.stepCount < takeOffStep then
			robot.flight_system.ready = function() return false end
			vns.setMorphology(vns, structure_reinforcement_cube)
			return false, false
		elseif vns.api.stepCount == takeOffStep then
			robot.flight_system.ready = function() return true end
			return false, true
		elseif vns.api.stepCount > takeOffStep then
			if vns.scalemanager.scale:totalNumber() > reinforceGroupNumber * 1.5 then
				vns.reinforcement = false
			end
			return false, true
		end

	else
		return false, true
	end
end end

function create_reinforcement_navigation_node(vns)
	local number = tonumber(string.match(robot.id, "%d+"))
	local state = "wait"
	return { type = "sequence", children = {
		function() if number > reinforceID then return false, true else return false, false end end,
		function()
			if vns.parentR == nil then
				vns.setMorphology(vns, structure_reinforcement_cube)
				if state == "wait" then
					if vns.scalemanager.scale:totalNumber() == reinforceGroupNumber and
					   vns.driver.all_arrive == true then
						state = "move"
					end
				elseif state == "move" then
					vns.Spreader.emergency_after_core(vns, vector3(-1,0,0), vector3())
				end
			end
		end,
	}}
end

function create_failure_node(vns)
vns.failed = false
return function()
	if vns.failed == true then
		if robot.flight_system.position.z > 5.0 then
			vns.api.setSpeed(0,0,-5, 0.4)
		else
			vns.api.setSpeed(0,0,-robot.flight_system.position.z, 0.0)
		end
		return false, false
	end

	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "send_signal")) do
		if msgM.dataT.signal == "failure_1" and vns.allocator.target.failure == "failure_1" then
			vns.failed = true
		elseif msgM.dataT.signal == "failure_2" and vns.allocator.target.failure == "failure_2" then
			vns.failed = true
		end
	end end

	return false, true
end end

function create_signal_node(vns)
	signal_state = "init"
	signal_stateCount = 0

	local function newState(vns, _newState)
		signal_stateCount = 0
		signal_state = _newState
	end

	local function sendChilrenNewSignal(vns, newSignal)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "send_signal", {signal = newSignal})
		end
	end

	local function switchAndSendNewSignal(vns, _newState)
		newState(vns, _newState)
		sendChilrenNewSignal(vns, _newState)
	end
return function ()
	signal_stateCount = signal_stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "send_signal")) do
		switchAndSendNewSignal(vns, msgM.dataT.signal)
	end end

	if vns.parentR == nil then
		print(signal_state, signal_stateCount)
		if signal_state == "init" and vns.api.stepCount > 300 and vns.driver.all_arrive == true then
			newState(vns, "waiting_for_failure_1_first")
		elseif signal_state == "waiting_for_failure_1_first" and signal_stateCount > 50 then
			sendChilrenNewSignal(vns, "failure_1")
			newState(vns, "failure_1_first_failed")

		elseif signal_state == "failure_1_first_failed" and signal_stateCount > 300 and vns.driver.all_arrive == true then
			newState(vns, "waiting_for_failure_1_second")
		elseif signal_state == "waiting_for_failure_1_second" and signal_stateCount > 50 then
			sendChilrenNewSignal(vns, "failure_1")
			newState(vns, "failure_1_second_failed")

		elseif signal_state == "failure_1_second_failed" and signal_stateCount > 300 and vns.driver.all_arrive == true then
			newState(vns, "waiting_for_failure_2")
		elseif signal_state == "waiting_for_failure_2" and signal_stateCount > 50 then
			sendChilrenNewSignal(vns, "failure_2")
			newState(vns, "failure_2_failed")
			vns.failed = true

		-- I'm new brain
		elseif signal_state == "failure_2" and signal_stateCount > 300 and vns.driver.all_arrive == true then
			switchAndSendNewSignal(vns, "waiting_for_reinforment")
			robot.debug.write("newBrain:" .. robot.id)
		elseif signal_state == "waiting_for_reinforment" and vns.scalemanager.scale:totalNumber() == mainGroupNumber then
			switchAndSendNewSignal(vns, "reinforment_get")

		elseif signal_state == "reinforment_get" and signal_stateCount > 300 and vns.driver.all_arrive == true then
			switchAndSendNewSignal(vns, "waiting_for_wind_non_brain")
			newState(vns, "waiting_for_wind")
		elseif signal_state == "waiting_for_wind" and signal_stateCount > 50 then
			robot.debug.write("wind")
			switchAndSendNewSignal(vns, "wind_signaled")
		end
	end
end end

function create_navigation_node(vns)
	local state = "init"
	local subState = 1
	local waitNextState = "man_up"
	local waitNextSubState = 1
	local stateCount = 0

	local function sendChilrenNewState(vns, newState, newSubState)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState, subState = newSubState})
		end
	end

	local function newState(vns, _newState, _newSubState)
		stateCount = 0
		state = _newState
		subState = _newSubState
	end

	local function switchAndSendNewState(vns, _newState, _newSubState)
		newState(vns, _newState, _newSubState)
		sendChilrenNewState(vns, _newState, _newSubState)
	end

return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state, msgM.dataT.subState)
	end end

	-- fail safe
	if vns.scalemanager.scale["drone"] == 1 and
	   n_drone ~= 8 and
	   vns.api.actuator.flight_preparation.state == "navigation" then
		if vns.brainkeeper ~= nil and vns.brainkeeper.brain ~= nil then
			local target = vns.brainkeeper.brain.positionV3 + vector3(3,0,5)
			vns.Spreader.emergency_after_core(vns, target:normalize() * 0.5, vector3())
		else
			vns.Spreader.emergency_after_core(vns, vector3(0,0,0.5), vector3())
		end
		return false, true
	end

	-- state
	-- init
	if state == "init" then
		if api.stepCount > 200 then
			waitNextState = "man_up"
			waitNextSubState = 1
			switchAndSendNewState(vns, "wait")
		end
	elseif state == "wait" then
		if vns.parentR == nil and stateCount > 30 then
			if vns.driver.all_arrive == true then
				switchAndSendNewState(vns, waitNextState, waitNextSubState)
			end
		end
	elseif state == "man_up" and vns.parentR == nil then
		vns.setMorphology(vns, structure_mans[subState])
		if subState == structure_mans_n then
			waitNextState = "man_down"
			waitNextSubState = structure_mans_n
		else
			waitNextSubState = subState + 1
		end
		switchAndSendNewState(vns, "wait")
	elseif state == "man_down" and vns.parentR == nil then
		vns.setMorphology(vns, structure_mans[subState])
		if subState == 1 then
			waitNextState = "man_up"
			waitNextSubState = 1
		else
			waitNextSubState = subState - 1
		end
		switchAndSendNewState(vns, "wait")
	end
end end