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

local DeepCopy = require("DeepCopy")
require("man")
--require("jet")
require("truck")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)
--local gene = create_arm(1.5, 1.5*1.5, vector3(), quaternion(), 30, 15)
--local gene = create_shoulder(vector3(), quaternion())
local man1 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -15,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 25,
}

local man2 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -12,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 30,
}

local man3 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -10,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 35,
}

local man4 = create_body{
	right_shoulder_Z = 145,
	right_shoulder_Y = -8,
	right_fore_arm_Z = 15,
	right_fore_arm_Y = 40,
}

local man5 = DeepCopy(man3)
local man6 = DeepCopy(man2)

--local jet = create_jet()
local truck1 = create_truck(10)
local truck2 = create_truck(20)
local truck3 = create_truck(30)
local truck4 = create_truck(40)
local truck5 = create_truck(50)
local truck6 = create_truck(60)

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		man1,
		man2,
		man3,
		man4,
		man5,
		man6,
--		jet,
		truck1,
		truck2,
		truck3,
		truck4,
		truck5,
		truck6,
	}
}

-- called when a child lost its parent
---[[
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, truck1)
end
--]]

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local base_height = api.parameters.droneDefaultStartHeight + 10
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = base_height + 6
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = base_height + 3
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = base_height + 0
	end
	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end

	--if vns.idS == "drone1" then vns.api.virtualFrame.logicOrientationQ = quaternion(-math.pi/12, vector3(0,1,0)) end

	vns.setGene(vns, gene)
--	vns.setMorphology(vns, man1)
--	vns.setMorphology(vns, jet)
	vns.setMorphology(vns, truck1)

	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
				create_navigation_node(vns),
			}}}
		)
	)
	--api.debug.show_all = true
end

function step()
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})

	if vns.goal.positionV3:length() < vns.Parameters.driver_arrive_zone * 4 then
		api.debug.showMorphologyLines(vns, true)
	end

	--[[
	if vns.goal.positionV3:length() < vns.Parameters.driver_arrive_zone * 4 then
		local r = 0.15
		api.debug.drawRing("255, 255, 255", vector3(0,0,0), r, true)
		api.debug.drawRing("255, 255, 255", vector3(0,0,0.1), r, true)
		api.debug.drawRing("255, 255, 255", vector3(0,0,0.2), r, true)
	end
	--]]

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

	local function find_marker()
		for i, ob in ipairs(vns.collectivesensor.totalObstaclesList) do
			return ob
		end
	end
return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state)
	end end
	-- fail safe
	--[[
	if vns.scalemanager.scale["drone"] == 1 and
	   vns.api.actuator.flight_preparation.state == "navigation" then
		vns.Spreader.emergency_after_core(vns, vector3(0,0,0.5), vector3())
		return false, true
	end
	--]]

	--[[ marker follower
	if vns.parentR == nil then
		local marker = find_marker()
		if marker ~= nil then
			local dis = 1
			local target = marker.positionV3 + vector3(-dis, -dis, dis):rotate(marker.orientationQ)
			vns.setGoal(vns, target, marker.orientationQ)
		end
	end
	--]]

	if state == "init" then
		if api.stepCount > 300 then
--			waitNextState = "man1"
--			waitNextState = "jet"
			waitNextState = "truck1"
			switchAndSendNewState(vns, "wait")
		end
	elseif state == "wait" then
		if vns.parentR == nil and stateCount > 30 then
			if vns.driver.all_arrive == true then
				logger("--- NewState: ", waitNextState)
				switchAndSendNewState(vns, waitNextState)
			end
		end
	elseif state == "truck1" and vns.parentR == nil then
		vns.setMorphology(vns, truck2)
		waitNextState = "truck2"
		switchAndSendNewState(vns, "wait")
	elseif state == "truck2" and vns.parentR == nil then
		vns.setMorphology(vns, truck3)
		waitNextState = "truck3"
		switchAndSendNewState(vns, "wait")
	elseif state == "truck3" and vns.parentR == nil then
		vns.setMorphology(vns, truck4)
		waitNextState = "truck4"
		switchAndSendNewState(vns, "wait")
	elseif state == "truck4" and vns.parentR == nil then
		vns.setMorphology(vns, truck5)
		waitNextState = "truck5"
		switchAndSendNewState(vns, "wait")
	elseif state == "truck5" and vns.parentR == nil then
		vns.setMorphology(vns, truck6)
		waitNextState = "truck6"
		switchAndSendNewState(vns, "wait")
	elseif state == "truck6" and vns.parentR == nil then
		vns.setMorphology(vns, man1)
		waitNextState = "man1"
		switchAndSendNewState(vns, "wait")

	elseif state == "man1" and vns.parentR == nil then
		vns.setMorphology(vns, man2)
		waitNextState = "man2"
		switchAndSendNewState(vns, "wait")
	elseif state == "man2" and vns.parentR == nil then
		vns.setMorphology(vns, man3)
		waitNextState = "man3"
		switchAndSendNewState(vns, "wait")
	elseif state == "man3" and vns.parentR == nil then
		vns.setMorphology(vns, man4)
		waitNextState = "man4"
		switchAndSendNewState(vns, "wait")
	elseif state == "man4" and vns.parentR == nil then
		vns.setMorphology(vns, man5)
		waitNextState = "man5"
		switchAndSendNewState(vns, "wait")
	elseif state == "man5" and vns.parentR == nil then
		vns.setMorphology(vns, man6)
		waitNextState = "man6"
		switchAndSendNewState(vns, "wait")
	elseif state == "man6" and vns.parentR == nil then
		vns.setMorphology(vns, man1)
		waitNextState = "man1"
		switchAndSendNewState(vns, "wait")
	end
	return false, true
end end