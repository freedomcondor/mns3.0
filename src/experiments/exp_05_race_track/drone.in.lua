if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure_search = require("morphology_2")
local structure4 = require("morphology_4")
local structure8 = require("morphology_8")
local structure12 = require("morphology_12")
local structure12_rec = require("morphology_12_rec")
local structure12_tri = require("morphology_12_tri")
local structure20 = require("morphology_20")
local structure20_toSplit = require("morphology_20_toSplit")

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_search,
		structure4,
		structure8,
		structure12,
		structure12_rec,
		structure12_tri,
		structure20,
		structure20_toSplit,
	}
}

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure20)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = 5
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = 10.0
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = 15.0
	end
	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure20)

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

	local gate_cir_20 = 100
	local gate_rec_12 = 101
	local gate_tri_12 = 102
	local gate_cir_12 = 103
	local gate_rec_8  = 104

	return function()
		stateCount = stateCount + 1
		-- if I receive switch state cmd from parent
		if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
			switchAndSendNewState(vns, msgM.dataT.state)
		end end

		-- detect marker
		local marker = find_marker(vns)

		-- fail safe
		if vns.scalemanager.scale["drone"] == 1 and
		   vns.api.actuator.flight_preparation.state == "navigation" then
			vns.idN = 0
			vns.Spreader.emergency_after_core(vns, vector3(0,0,0.3), vector3())
			return false, true
		end

		-- state
		-- init
		if state == "init" then
			if stateCount == 100 then
				newState(vns, "forward")
			end
		-- forward
		elseif state == "forward" and marker ~= nil and vns.parentR == nil then
			local offset = vector3(0, 0, 3)

			-- handle different condition
			if marker.type == gate_cir_20 and vns.scalemanager.scale["drone"] > 12 then
				vns.setMorphology(vns, structure20)
			-- split
			elseif marker.type == gate_rec_12 and vns.scalemanager.scale["drone"] == 20 then
				vns.setMorphology(vns, structure20_toSplit)
				switchAndSendNewState(vns, "toSplit")	
				return false, true
			-- 12 rec, tri, cir
			elseif marker.type == gate_rec_12 and vns.scalemanager.scale["drone"] == 12 then
				vns.setMorphology(vns, structure12_rec)
				offset = vector3(0,0,3)
			elseif marker.type == gate_tri_12 and vns.scalemanager.scale["drone"] == 12 then
				vns.setMorphology(vns, structure12_tri)
				offset = vector3(0,0,2)
			elseif marker.type == gate_cir_12 and vns.scalemanager.scale["drone"] == 12 then
				vns.setMorphology(vns, structure12)
				offset = vector3(0,0,3)
			-- 8 rec
			elseif marker.type == gate_rec_8 and vns.scalemanager.scale["drone"] == 8 then
				vns.setMorphology(vns, structure8)
				offset = vector3(0,-0.7 * 5 / 1.5,3)
			end

			-- vertical speed
			local vertical_speed_max = 1.0
			local target_position = marker.positionV3 + offset:rotate(marker.orientationQ)
			local dirVec = vector3(1,0,0):rotate(marker.orientationQ)
			local vertical_position = target_position - target_position:dot(dirVec) * dirVec
			local vertical_speed = vertical_position * 0.1
			if vertical_speed:length() > vertical_speed_max then
				vertical_speed = vertical_speed * (vertical_speed_max / vertical_speed:length())
			end

			-- horizontal speed
			-- move forward with speed, calculate into move_speed
			local forward_speed_max = 1
			if vns.driver.all_arrive == false then forward_speed_max = 0.3; stateCount = 0 end
			-- who ever arrives the first will be the new brain
			if marker.type == gate_cir_20 and vns.scalemanager.scale["drone"] ~= 20 and stateCount then
				forward_speed_max = 0
				vns.Connector.newVnsID(vns, 1.1)
			end
			if marker.type == gate_rec_8 and vns.scalemanager.scale["drone"] == 8 then forward_speed_max = 0.8 end

			local forward_speed_scalar = stateCount / 50
			if forward_speed_scalar > 1 then forward_speed_scalar = 1 end
			local move_speed = vector3(1,0,0) * forward_speed_max * forward_speed_scalar
			-- move forward with vertical speed and move speed
			vns.setGoal(vns, vector3(0,0,0), marker.orientationQ)
			vns.Spreader.emergency_after_core(vns, vertical_speed + move_speed, vector3())

		-- split
		elseif state == "toSplit" and vns.parentR == nil then
			if stateCount == 50 then
				switchAndSendNewState(vns, "split")	
			end	
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
				local search_velocity = vector3(0.3, 0, 0)

				if vns.scalemanager.scale["drone"] == 12 then
					split_marker = find_marker(vns, gate_rec_12, true)
					vns.setMorphology(vns, structure12_rec)

					offset = vector3(-5, 0, 3)
					search_velocity = vector3(0.3, 0.3, 0)
				end
				if vns.scalemanager.scale["drone"] == 8 then
					split_marker = find_marker(vns, gate_rec_8, true)
					vns.setMorphology(vns, structure8)

					offset = vector3(-5,-2.5, 3)
					search_velocity = vector3(0.3, -0.3, 0)
				end

				if split_marker ~= nil then
					vns.setGoal(vns, split_marker.positionV3 + offset:rotate(split_marker.orientationQ), split_marker.orientationQ)
				else
					vns.setGoal(vns, vector3(0,0,0), quaternion())
					vns.Spreader.emergency_after_core(vns, search_velocity, vector3())
				end
			end

			if stateCount == 100 then
				switchAndSendNewState(vns, "forward")
			end
		end
	end
end