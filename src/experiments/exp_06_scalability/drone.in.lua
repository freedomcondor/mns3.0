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

local structure = generate_cube_morphology(n_drone)

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
	vns.setGene(vns, structure)

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
			local target = vns.brainkeeper.brain.positionV3 + vector3(0,0,5)
			vns.Spreader.emergency_after_core(vns, target:normalize() * 0.5, vector3())
		else
			vns.Spreader.emergency_after_core(vns, vector3(0,0,0.5), vector3())
		end
		return false, true
	end

	-- state
	-- init
	if state == "init" then
		if vns.parentR == nil and vns.api.stepCount > 100 then
			if vns.driver.all_arrive == true then
				switchAndSendNewState(vns, "forward")
			end
		end
	-- forward
	elseif state == "forward" then
		if vns.parentR == nil then
			local marker = find_marker(vns)
			if marker == nil then
				vns.Spreader.emergency_after_core(vns, vector3(0.1, 0, 0), vector3())
				return false, true
			end

			local swarm_size = vns.scalemanager.scale["drone"]
			local side_length = math.ceil(math.pow(swarm_size, 1.0/3))

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
		end
	end

end end