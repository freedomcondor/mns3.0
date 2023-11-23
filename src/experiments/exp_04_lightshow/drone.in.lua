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

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)

local structure_screen = generate_screen_square(18, 17)

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
		structure_screen,
	}
}

for i = 1, structure_mans_n do
	table.insert(gene.children, structure_mans[i])
end

-- overwrite default function
-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	--vns.Allocator.setMorphology(vns, structure_man)
	vns.Allocator.setMorphology(vns, structure_screen)
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
	api.debug.drawHalo(color, vector3(0,0,0.2), 0.25, 0.7, 0.1, true)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local base_height = api.parameters.droneDefaultStartHeight + 15
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = base_height
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = base_height + 6
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = base_height + 12
	end
	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure_screen)
	--vns.setMorphology(vns, structure_man1)

	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
				create_navigation_node(vns),
			}}}
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
	if vns.screenCountDown ~= nil then
		api.debug.showMorphologyLightShowLEDs(vns, vns.screenCountDown)
	elseif vns.goal.positionV3:length() < LED_zone and
	       (vector3(1,0,0):rotate(vns.goal.orientationQ) - vector3(1,0,0)):length() < 0.1 and
	       vns.allocator.target.idN > 0 and
	       vns.failed ~= true and
	       vns.scalemanager.scale:totalNumber() > 5 then
		api.debug.showMorphologyLightShowLEDs(vns, "cyan")
		if vns.driver.all_arrive == true then
			api.debug.showMorphologyLines(vns, "cyan")
		end
	else
		api.debug.showMorphologyLightShowLEDs(vns, "white")
	end

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
	local state = "init"
	local subState = 3
	local waitNextState = "init"
	local waitNextSubState = 3
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

	local function generate_map_index(map)
		local index = {}
		local rows = #map
		local cols = #map[rows]
		for j = 1, cols do
			for i = rows, 1, -1 do
				table.insert(index, map[i][j])
			end
		end
		return index
	end

	local map_3 = {
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0},
		{0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0},
		{0,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0},
		{0,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0},
		{0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0},
		{0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	}

	local map_2 = {
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0},
		{0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0},
		{0,0,0,1,1,0,0,0,0,0,0,1,1,1,0,0,0},
		{0,0,0,1,0,0,0,0,0,0,0,0,1,1,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0},
		{0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	}

	local map_1 = {
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0},
		{0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0},
		{0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	}

	local map_index = {}
	map_index[1] = generate_map_index(map_1)
	map_index[2] = generate_map_index(map_2)
	map_index[3] = generate_map_index(map_3)

	local rebellian = {
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	}
	rebellian_index = generate_map_index(rebellian)

return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state, msgM.dataT.subState)
	end end

	-- fail safe
	if vns.scalemanager.scale["drone"] == 1 and
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
			waitNextState = "countDown"
			waitNextSubState = 3
			switchAndSendNewState(vns, "wait")
		end
	elseif state == "wait" then
		if vns.parentR == nil and stateCount > 30 then
			if vns.driver.all_arrive == true then
				switchAndSendNewState(vns, waitNextState, waitNextSubState)
			end
		end
	-- count Down
	elseif state == "countDown" then
		-- parent log state
		if vns.parentR == nil then
			logger("--- count state : ", state, subState)
		end
		-- all robots, check index and turn on led
		local index = vns.allocator.target.idN
		local index_base = structure_screen.idN
		index = index - index_base + 1
		if map_index[subState][index] == 1 and
		   vns.scalemanager.scale:totalNumber() == n_drone then
			vns.allocator.target.lightShowLED = "red"
			vns.screenCountDown = "red"
		else
			vns.allocator.target.lightShowLED = nil
			vns.screenCountDown = nil
		end

		if vns.parentR == nil and stateCount > 30 then
			if subState == 1 then
				switchAndSendNewState(vns, "rebellian")
			else
				switchAndSendNewState(vns, "countDown", subState - 1)
			end
		end
	elseif state == "rebellian" then
		vns.screenCountDown = nil
		local index = vns.allocator.target.idN
		local index_base = structure_screen.idN
		index = index - index_base + 1
		if rebellian_index[index] == 1 then
			logger("--- I'm  ", robot.id, "I'm rebellian")
			if vns.parentR ~= nil then
				vns.Msg.send(vns.parentR.idS, "dismiss")
				vns.deleteParent(vns)
			end
			vns.Connector.newVnsID(vns, 2, 200)

			vns.allocator.mode_switch = "stationary"

			state = "rebellian_wait"
		end
	elseif state == "rebellian_wait" then
		if vns.parentR == nil then
			logger("--- I'm  ", robot.id, "I'm waiting ", vns.scalemanager.scale:totalNumber())
			if vns.scalemanager.scale:totalNumber() == n_drone then
				vns.allocator.mode_switch = "allocate"
				--vns.setMorphology(vns, structure_trucks[1])
				vns.setMorphology(vns, structure_mans[1])
				--waitNextState = "truck"
				waitNextState = "man_up"
				subState = 1
				switchAndSendNewState(vns, "wait")
			end
		end
	elseif state == "truck" and vns.parentR == nil then
		vns.setMorphology(vns, structure_trucks[subState])
		if subState == structure_trucks_n then
			waitNextState = "man_up"
			waitNextSubState = 1
		else
			waitNextSubState = subState + 1
		end
		switchAndSendNewState(vns, "wait")

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