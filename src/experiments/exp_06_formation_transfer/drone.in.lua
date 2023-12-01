if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
-- overwrite driver with a customized driver that considers extra robots as arrived
VNS.Driver = require("CustomizedDriver")
VNS.Modules[16] = VNS.Driver
local BT = require("BehaviorTree")

require("morphologyGenerateSpineCube")
require("morphologyGenerateSpineSphere")

-- 343 drone
--local structure2 = generateSpineCenterBrainCube(4, 4, 4, vector3(), quaternion(), vector3(5,0,0), vector3(0,5,0), vector3(0,0,5))
--local structure1 = generateSpineCenterBrainSphere(21.5, vector3(), quaternion(), vector3(5,0,0), vector3(0, 5, 0), vector3(0, 0, 5))

-- 125 drone
local structure2 = generateSpineCenterBrainCube(3, 3, 3, vector3(), quaternion(), vector3(5,0,0), vector3(0,5,0), vector3(0,0,5))
local structure1 = generateSpineCenterBrainSphere(15, vector3(), quaternion(), vector3(5,0,0), vector3(0, 5, 0), vector3(0, 0, 5))

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		structure2,
	}
}

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local baseHeight = 30
	local distribute_scale = 4
	local layers = 5
	for i = 1, layers do
		if number % layers == (i % layers) then
			api.parameters.droneDefaultStartHeight = baseHeight + (i - 1) * distribute_scale
		end
	end

	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure1)


	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
				create_navigation_node(vns),
			}}}
		)
	)
end

function step()
	--logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	--api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	api.debug.showMorphologyLines(vns, true)
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
	local state = "init"
	local waitNextState = "init"
	local stateCount = 0

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
			waitNextState = 1
			switchAndSendNewState(vns, "wait")
		end
	elseif state == "wait" then
		if vns.parentR == nil and stateCount > 30 then
			if vns.driver.all_arrive == true then
				switchAndSendNewState(vns, waitNextState)
			end
		end
	elseif state == 1 then
		vns.setMorphology(vns, structure1)
			waitNextState = 2
		switchAndSendNewState(vns, "wait")
	elseif state == 2 then
		vns.setMorphology(vns, structure2)
			waitNextState = 1
		switchAndSendNewState(vns, "wait")
	end

	return false, true
end end