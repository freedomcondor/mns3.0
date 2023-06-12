if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
require("morphologyGenerateScreen")
require("morphologyGenerateCube")
require("morphologyGenerateMan")
Transform = require("Transform")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)
n_cube_side       = math.ceil(n_drone ^ (1/3))
n_screen_side       = math.ceil(n_drone ^ (1/2))

local structure_screen = generate_screen_square(n_screen_side)
local structure_cube = generate_cube(n_cube_side)

local structure_man = generate_man(
	quaternion(math.pi/6, vector3(0,0,1)),
	quaternion(math.pi/8, vector3(0,0,1)),
	quaternion(math.pi/8, vector3(0,1,0))
)

local structure_man_2 = generate_man(
	quaternion(-math.pi/6, vector3(0,0,1)),
	quaternion(-math.pi/8, vector3(0,0,1)),
	quaternion(-math.pi/8, vector3(0,1,0))
)

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		--structure_screen,
		--structure_cube,
		structure_man,
		structure_man_2,
	}
}
--]]

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure_man)
end

-- Analyze function -----
function getCurrentTime()
	local wallTimeS, wallTimeNS, CPUTimeS, CPUTimeNS = robot.radios.wifi.get_time()
	--return CPUTimeS + CPUTimeNS * 0.000000001
	return wallTimeS + wallTimeNS * 0.000000001
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local base_height = api.parameters.droneDefaultStartHeight + 8
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = base_height
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = base_height + 2
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = base_height + 4
	end
	--api.debug.show_all = true
end

local startTime = getCurrentTime()

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)
	--vns.setMorphology(vns, structure_screen)
	vns.setMorphology(vns, structure_man)

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
	local MeasureStepPeriod = 20
	if robot.id == "drone1" and api.stepCount % MeasureStepPeriod == 0 then
		local currentTime = getCurrentTime()
		logger(robot.id, api.stepCount, "----------------------------, runtime :", currentTime - startTime, "average : ", (currentTime - lastTime) / MeasureStepPeriod)
		lastTime = currentTime
	end
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})

	if vns.goal.positionV3:length() < vns.Parameters.driver_stop_zone * 2 then
		api.debug.showMorphologyLines(vns, true)
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

	local map_3 = {
		{0,0,0,0,0,0,0,0},
		{0,0,0,1,1,1,0,0},
		{0,0,1,0,0,0,1,0},
		{0,0,0,0,0,0,1,0},
		{0,0,0,0,1,1,0,0},
		{0,0,0,0,0,0,1,0},
		{0,0,1,0,0,0,1,0},
		{0,0,0,1,1,1,0,0},
	}

	local map_2 = {
		{0,0,0,0,0,0,0,0},
		{0,0,0,1,1,1,0,0},
		{0,0,1,0,0,0,1,0},
		{0,0,0,0,0,0,1,0},
		{0,0,0,0,0,1,0,0},
		{0,0,0,0,1,0,0,0},
		{0,0,0,1,0,0,0,0},
		{0,0,1,1,1,1,1,0},
	}

	local map_1 = {
		{0,0,0,0,0,0,0,0},
		{0,0,0,0,1,0,0,0},
		{0,0,0,1,1,0,0,0},
		{0,0,0,0,1,0,0,0},
		{0,0,0,0,1,0,0,0},
		{0,0,0,0,1,0,0,0},
		{0,0,0,0,1,0,0,0},
		{0,0,1,1,1,1,1,0},
	}

	local map_index = {}
	map_index[1] = generate_map_index(map_1)
	map_index[2] = generate_map_index(map_2)
	map_index[3] = generate_map_index(map_3)

return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state)
	end end

	-- fail safe
	if vns.scalemanager.scale["drone"] == 1 and
	   n_drone ~= 8 and
	   vns.api.actuator.flight_preparation.state == "navigation" then
		if vns.brainkeeper ~= nil and vns.brainkeeper.brain ~= nil then
			local target = vns.brainkeeper.brain.positionV3 + vector3(3,0,5)
			vns.Spreader.emergency_after_core(vns, target:normalize() * 0.1, vector3())
		else
			vns.Spreader.emergency_after_core(vns, vector3(0,0,0.1), vector3())
		end
		return false, true
	end

	-- state
	-- init
	if state == "init" then
		if api.stepCount > 100 then
			waitNextState = "man2"
			switchAndSendNewState(vns, "wait")
		end
	elseif state == "wait" then
		if vns.parentR == nil and stateCount > 30 then
			if vns.driver.all_arrive == true then
				logger("--- NewState: ", waitNextState)
				switchAndSendNewState(vns, waitNextState)
			end
		end
	-- count Down
	elseif state == 3 or state == 2 or state == 1 then
		local index = vns.allocator.target.idN
		local index_base = structure_screen.idN
		index = index - index_base + 1
		if map_index[state][index] == 1 then
			api.debug.drawRing("128, 0, 255", vector3(0,0,0), 0.3, true)
			api.debug.drawRing("128, 0, 255", vector3(0,0,0.2), 0.3, true)
		end

		if vns.parentR == nil and stateCount > 30 then
			if state == 1 then
				switchAndSendNewState(vns, "cube")
			else
				switchAndSendNewState(vns, state - 1)
			end
		end
	elseif state == "cube" and vns.parent == nil then
		vns.setMorphology(vns, structure_cube)

	-- man
	elseif state == "man" and vns.parent == nil then
		vns.setMorphology(vns, structure_man)
		waitNextState = "man2"
		switchAndSendNewState(vns, "wait")
	elseif state == "man2" and vns.parent == nil then
		vns.setMorphology(vns, structure_man_2)
		waitNextState = "man"
		switchAndSendNewState(vns, "wait")
	end

end end