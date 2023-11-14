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

require("screenGenerator")
require("manGenerator")
require("truckGenerator")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)
n_screen_side       = math.ceil(n_drone ^ (1/2))

local structure_screen = generate_screen_square(n_screen_side)

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

-- structure trucks
local structure_trucks = {}
local structure_trucks_n = 7
local wheel_degree_left = 0
local wheel_degree_right = 60
local wheel_degree_range = wheel_degree_right - wheel_degree_left
local wheel_degree_step = wheel_degree_range / (structure_trucks_n - 1)
for i = 1, structure_trucks_n do
	structure_trucks[i] = create_truck(wheel_degree_step * (i-1))
end

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_screen,
	}
}

for i = 1, structure_trucks_n do
	table.insert(gene.children, structure_trucks[i])
end
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

function api.debug.showMorphologyLines(vns, essential)
	if vns.allocator ~= nil and vns.allocator.target.drawLines ~= nil then
		local color = vns.allocator.target.drawLinesColor or "gray50"
		for i, vec in ipairs(vns.allocator.target.drawLines) do
			vns.api.debug.drawCustomizeArrow(color,
			                                 vector3(0,0,0),
			                                 vns.api.virtualFrame.V3_VtoR(vec),
			                                 0.10,
			                                 0.10,
			                                 1,
			                                 essential)
		end
	end
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	local number = tonumber(string.match(robot.id, "%d+"))
	local base_height = api.parameters.droneDefaultStartHeight + 65
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
	if vns.goal.positionV3:length() < LED_zone and vns.failed ~= true then
		api.debug.showMorphologyLines(vns, true)
		api.debug.showMorphologyLightShowLEDs(vns, true)
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

local takeOffStep = 2500
local reinforceID = 100
local reinforceGroupNumber = 30

function create_reinforcement_node(vns)
	local number = tonumber(string.match(robot.id, "%d+"))
return function()
	if number > reinforceID then
		if vns.api.stepCount < takeOffStep then
			robot.flight_system.ready = function() return false end
			vns.setMorphology(vns, structure_screen)
			return false, false
		elseif vns.api.stepCount == takeOffStep then
			robot.flight_system.ready = function() return true end
			return false, true
		elseif vns.api.stepCount > takeOffStep then
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
				vns.setMorphology(vns, structure_screen)
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
		if robot.flight_system.position.z > 2.0 then
			vns.api.setSpeed(0,0,-5, 0.4)
		else
			vns.api.setSpeed(0,0,0, 0.4)
		end
		return false, false
	end

	if vns.api.stepCount == 1000 and vns.allocator.target.failure == "failure_1" then
		vns.failed = true
	end

	if vns.api.stepCount == 1500 and vns.allocator.target.failure == "failure_1" then
		vns.failed = true
	end

	if vns.api.stepCount == 2000 and vns.allocator.target.failure == "failure_2" then
		vns.failed = true
	end

	return false, true
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