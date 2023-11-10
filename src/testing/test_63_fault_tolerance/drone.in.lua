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

require("manGenerator")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone) -- fix to 100 in this case, hard coded in run.py

local structure_man1 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -15,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 25,
}

local structure_man2 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -12,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 30,
}

local structure_man3 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -10,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 35,
}

local structure_man4 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -8,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 40,
}

local structure_man5 = DeepCopy(structure_man3)
local structure_man6 = DeepCopy(structure_man2)

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_man1,
		structure_man2,
		structure_man3,
		structure_man4,
		structure_man5,
		structure_man6,
	}
}
--]]

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure_man1)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local base_height = api.parameters.droneDefaultStartHeight + 50
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = base_height + 8
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = base_height + 4
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = base_height + 0
	end
	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 2 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure_man1)

	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				create_failure_node(vns),
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
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})

	local LED_zone = vns.Parameters.driver_stop_zone * 5
	-- show morphology lines
	if vns.goal.positionV3:length() < LED_zone then
		api.debug.showMorphologyLines(vns, true)
		api.debug.showMorphologyLightShowLEDs(vns, true)
	end

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
	state = "init"
	waitNextState = "init"
	stateCount = 0

	local function sendChilrenNewState(vns, newState)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState})
		end
	end

	local function newState(vns, _newState)
		stateCount = 0
		state = _newState
	end

	local function switchAndSendNewState(vns, _newState)
		newState(vns, _newState)
		sendChilrenNewState(vns, _newState)
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

return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state)
	end end

	-- fail safe
	if vns.scalemanager.scale["drone"] == 1 and
	   vns.api.actuator.flight_preparation.state == "navigation" then
		if vns.brainkeeper ~= nil and vns.brainkeeper.brain ~= nil then
			local target = vns.brainkeeper.brain.positionV3 + vector3(3,0,5)
			vns.Spreader.emergency_after_core(vns, target:normalize() * 0.1, vector3())
		else
			vns.Spreader.emergency_after_core(vns, vector3(0,0,0.1), vector3())
		end
		return false, true
	end

	-- brain failure --- second brain reset
	if vns.parentR == nil and
	   vns.scalemanager.scale["drone"] > n_drone / 2 and
	   vns.idN ~= lastidN then
		vns.Connector.newVnsID(vns, 1, 1)
		vns.api.virtualFrame.logicOrientationQ = quaternion()
	end
	lastidN = vns.idN

	-- state
	-- init
	if state == "init" then
		if api.stepCount > 200 then
			waitNextState = "man1"
			switchAndSendNewState(vns, "wait")
		end
	elseif state == "wait" then
		if vns.parentR == nil and stateCount > 30 then
			if vns.driver.all_arrive == true then
				switchAndSendNewState(vns, waitNextState)
			end
		end
	elseif state == "man1" and vns.parentR == nil then
		vns.setMorphology(vns, structure_man2)
		waitNextState = "man2"
		switchAndSendNewState(vns, "wait")
	elseif state == "man2" and vns.parentR == nil then
		vns.setMorphology(vns, structure_man3)
		waitNextState = "man3"
		switchAndSendNewState(vns, "wait")
	elseif state == "man3" and vns.parentR == nil then
		vns.setMorphology(vns, structure_man4)
		waitNextState = "man4"
		switchAndSendNewState(vns, "wait")
	elseif state == "man4" and vns.parentR == nil then
		vns.setMorphology(vns, structure_man5)
		waitNextState = "man5"
		switchAndSendNewState(vns, "wait")
	elseif state == "man5" and vns.parentR == nil then
		vns.setMorphology(vns, structure_man6)
		waitNextState = "man6"
		switchAndSendNewState(vns, "wait")
	elseif state == "man6" and vns.parentR == nil then
		vns.setMorphology(vns, structure_man1)
		waitNextState = "man1"
		switchAndSendNewState(vns, "wait")
	end
end end

function create_failure_node(vns)
local failure_flag = false
return function()
	return false, true
end end