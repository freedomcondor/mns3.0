if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
require("morphologyGenerateCube")
require("morphologyGenerateChain")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)

local n_left_drone = 0
if n_drone == 27 then  n_left_drone = 8 end
if n_drone == 64 then  n_left_drone = 8 end
if n_drone == 125 then n_left_drone = 64 end
if n_drone == 216 then n_left_drone = 125 end
if n_drone == 512 then n_left_drone = 216 end

local n_right_drone = n_drone - n_left_drone
n_side       = math.ceil(n_drone ^ (1/3))
n_left_side  = math.ceil(n_left_drone ^ (1/3))
n_right_side = math.ceil(n_right_drone ^ (1/3))

local structure_full = generate_cube_morphology(n_drone, n_left_drone)
local structure_left = generate_cube_morphology(n_left_drone)
local structure_right = generate_cube_morphology(n_right_drone)

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_full,
		structure_left,
		structure_right,
	}
}

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure_left)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = 1
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = 3.0
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = 5.0
	end
	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure_full)

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
	vns.logLoopFunctionInfo(vns)

	if vns.goal.positionV3:length() < vns.Parameters.driver_stop_zone * 2 then
		api.debug.showMorphologyLines(vns, true)
	end
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
	state = "init"
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

	local function find_marker(vns, priority, priority_only)
		-- find marker
		local marker
		local marker_behind
		local dis = math.huge
		local dis_behind = -math.huge

		local priority_list = {}
		if priority ~= nil then
			for i, ob in ipairs(vns.collectivesensor.totalObstaclesList) do
				if ob.type == priority then
					table.insert(priority_list, ob)
				end
			end
		end
		if #priority_list == 0 and priority_only ~= true then
			priority_list = vns.collectivesensor.totalObstaclesList
		end

		for i, ob in ipairs(priority_list) do
				local dirVec = vector3(1,0,0):rotate(ob.orientationQ)
				local horizontal_shadow = ob.positionV3:dot(dirVec)
				if horizontal_shadow > 0 and horizontal_shadow < dis then
					marker = ob
					dis = horizontal_shadow
				end
				if horizontal_shadow <= 0 and horizontal_shadow > dis_behind then
					marker_behind = ob
					dis_behind = horizontal_shadow
				end
		end
		if marker == nil then marker = marker_behind end
		return marker
	end

	local obstacle_entrance = 1001
	local obstacle_left = 1002
	local obstacle_right = 1003

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

	-- find marker
	local marker = find_marker(vns)

	-- state
	-- init
	if state == "init" then
		if vns.parentR == nil and vns.api.stepCount > 100 then
			if vns.driver.all_arrive == true then
				switchAndSendNewState(vns, "forward")
			end
		end
	-- forward
	elseif state == "forward" and marker ~= nil and vns.parentR == nil then
		local swarm_size = vns.scalemanager.scale["drone"]
		local side_length = math.ceil(math.pow(swarm_size, 1.0/3))

		-- handle different condition
		if marker.type == obstacle_left or
		   marker.type == obstacle_right then
			switchAndSendNewState(vns, "split")	
			return false, true
		end

		local offset = vector3(-(side_length-1)*0.5 * 1.5, -(side_length-1)*0.5 * 1.5, 1)

		-- vertical speed
		local target_position = marker.positionV3 + offset:rotate(marker.orientationQ)
		local dirVec = vector3(1,0,0):rotate(marker.orientationQ)
		local vertical_position = target_position - target_position:dot(dirVec) * dirVec
		local vertical_speed = vertical_position * 0.1
		if vertical_speed:length() > 0.3 then
			vertical_speed = vertical_speed * (0.3 / vertical_speed:length())
		end

		-- horizontal speed
		-- move forward with speed, calculate into move_speed
		local move_speed = vector3(dirVec):rotate(marker.orientationQ) * 0.3

		-- move forward with vertical speed and move speed
		vns.setGoal(vns, vector3(0,0,0), marker.orientationQ)
		vns.Spreader.emergency_after_core(vns, vertical_speed + move_speed, vector3())

	elseif state == "split" then
		if vns.allocator.target.split == true then
			-- rebellion
			if vns.parentR ~= nil then
				vns.Msg.send(vns.parentR.idS, "dismiss")
				vns.deleteParent(vns)
			end
			vns.Connector.newVnsID(vns, 0.9, 200)
		end	

		if vns.parentR == nil then
			-- find marker again with priority
			local split_marker
			local offset
			local search_velocity = vector3(0.1, 0, 0)

			if vns.scalemanager.scale["drone"] == n_left_drone then
				split_marker = find_marker(vns, obstacle_left, true)
				vns.setMorphology(vns, structure_left)

				local side_length = (n_left_side - 1) * 1.5
				offset = vector3(-side_length, -side_length * 0.5, 0.5)
				search_velocity = vector3(0.0, 0.1, 0)
			end
			if vns.scalemanager.scale["drone"] == n_right_drone then
				split_marker = find_marker(vns, obstacle_right, true)
				vns.setMorphology(vns, structure_right)

				local side_length = (n_right_side - 1) * 1.5
				offset = vector3(-side_length, -side_length * 0.5, 0.5)
				search_velocity = vector3(0.0, -0.1, 0)
			end

			if split_marker ~= nil then
				vns.setGoal(vns, split_marker.positionV3 + offset:rotate(split_marker.orientationQ), split_marker.orientationQ)
			else
				vns.setGoal(vns, vector3(0,0,0), quaternion())
				vns.Spreader.emergency_after_core(vns, search_velocity, vector3())
			end
		end
	end

end end