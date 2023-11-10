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
local state = "init"
local count = 0
local flag = false

local gate_station_circle = 100
local gate_rec_8 = 101
local gate_circle_12 = 102
local gate_tri_12 = 103
local gate_rec_12 = 104

return function()
	if state == "init" then
		if vns.parentR == nil and vns.scalemanager.scale["drone"] == 4 then
			vns.setMorphology(vns, structure4)
		elseif vns.parentR == nil and vns.scalemanager.scale["drone"] == 8 then
			vns.setMorphology(vns, structure8)
		end

		count = count + 1
		if count == 100 then
			state = "forward"
			count = 0
		end

	elseif state == "forward" then
		--[[
		if vns.parentR == nil and vns.scalemanager.scale["drone"] == 4 then
			vns.setMorphology(vns, structure4)
		elseif vns.parentR == nil and vns.scalemanager.scale["drone"] == 8 then
			vns.setMorphology(vns, structure8)
		elseif vns.parentR == nil and vns.scalemanager.scale["drone"] == 12 then
			vns.setMorphology(vns, structure12)
		elseif vns.parentR == nil and vns.scalemanager.scale["drone"] == 20 then
			vns.setMorphology(vns, structure20)
		end
		--]]

		if vns.parentR == nil then
			-- find marker
			local marker
			local marker_behind
			local dis = math.huge
			local dis_behind = -math.huge
			for i, ob in ipairs(vns.collectivesensor.totalObstaclesList) do
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
	
			-- init at station -> stay
			if marker ~= nil and marker.type == gate_station_circle and vns.scalemanager.scale["drone"] == 4 or
			   marker ~= nil and marker.type == gate_station_circle and vns.scalemanager.scale["drone"] == 8 then
				local offset
				if vns.scalemanager.scale["drone"] == 4 then
					offset = vector3(-0.7, 0, 1.5)
					vns.setMorphology(vns, structure4)
				elseif vns.scalemanager.scale["drone"] == 8 then 
					offset = vector3(-0.7, -0.7, 0.7)
					vns.setMorphology(vns, structure8)
				end
				vns.setGoal(vns, marker.positionV3 + offset:rotate(marker.orientationQ), marker.orientationQ)
			-- or i'm the main group -> move forward
			elseif marker ~= nil then
				-- align with the gate, calculate into vertical speed
				local offset = vector3(-0.7, 0, 1.0)
				if vns.scalemanager.scale["drone"] == 4 then
					offset = vector3(-0.7, 0, 1.5)
					vns.setMorphology(vns, structure4)
				elseif vns.scalemanager.scale["drone"] == 8 then 
					offset = vector3(-0.7, -0.7, 0.7)
					vns.setMorphology(vns, structure8)
				elseif vns.scalemanager.scale["drone"] == 12 and marker.type == gate_rec_12 then 
					offset = vector3(-0.7, 0, 1.0)
					vns.setMorphology(vns, structure12_rec)
				elseif vns.scalemanager.scale["drone"] == 12 and marker.type == gate_tri_12 then 
					offset = vector3(-0.7, 0, 1.0)
					vns.setMorphology(vns, structure12_tri)
				elseif vns.scalemanager.scale["drone"] == 12 and marker.type == gate_circle_12 or
				       vns.scalemanager.scale["drone"] == 12 and marker.type == gate_station_circle then 
					offset = vector3(-0.7, 0, 1.0)
					vns.setMorphology(vns, structure12)
				elseif vns.scalemanager.scale["drone"] == 20 then 
					offset = vector3(-0.7, 0, 0.7)
					vns.setMorphology(vns, structure20)
				end

				local target_position = marker.positionV3 + offset:rotate(marker.orientationQ)
				local dirVec = vector3(1,0,0):rotate(marker.orientationQ)
				local vertical_position = target_position - target_position:dot(dirVec) * dirVec
				local vertical_speed = vertical_position:normalize() * 0.1

				-- move forward with speed, calculate into move_speed
				local speed = 0.5
				if vns.driver.all_arrive == false then speed = 0.1 end

				-- if I lost any one, stay
				if vns.scalemanager.scale["drone"] ~= 4 and 
				   vns.scalemanager.scale["drone"] ~= 8 and 
				   vns.scalemanager.scale["drone"] ~= 12 and 
				   vns.scalemanager.scale["drone"] ~= 20 then
					speed = 0
				end

				local move_speed = vector3(dirVec):rotate(marker.orientationQ) * speed
	
				-- move forward with vertical speed and move speed
				vns.setGoal(vns, vector3(0,0,0), marker.orientationQ)
				vns.Spreader.emergency_after_core(vns, vertical_speed + move_speed, vector3())
			else
				if vns.scalemanager.scale["drone"] == 4 then
					vns.setMorphology(vns, structure4)
				elseif vns.scalemanager.scale["drone"] == 8 then
					vns.setMorphology(vns, structure8)
				elseif vns.scalemanager.scale["drone"] == 12 then
					vns.setMorphology(vns, structure12)
				elseif vns.scalemanager.scale["drone"] == 20 then
					vns.setMorphology(vns, structure20)
				end
			end
		end
	end
end end