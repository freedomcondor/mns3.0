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
local structure8 = require("morphology_8")
local structure12 = require("morphology_12")
local structure12_rec = require("morphology_12_rec")
local structure12_tri = require("morphology_12_tri")
local structure20 = require("morphology_20")

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_search,
		structure8,
		structure12,
		structure12_rec,
		structure12_tri,
		structure20,
	}
}

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure12)
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
	vns.setMorphology(vns, structure12)

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
return function()
	if vns.parentR == nil then
		-- add vns.avoider.obstacles and vns.collectivesensor.receiveList together
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

		local tri_type = 100
		local cir_type = 101
		local rec_type = 102

		local tri_relative = vector3(0, 0, 0.7)
		local cir_relative = vector3(0, 0, 2.0)
		local rec_relative = vector3(0, 0, 0.7)

		local relative_position = tri_relative

		if marker ~= nil then
			if marker.type == tri_type then
				vns.setMorphology(vns, structure12_tri)
				relative_position = tri_relative
			elseif marker.type == cir_type then
				vns.setMorphology(vns, structure12)
				relative_position = cir_relative
			elseif marker.type == rec_type then
				vns.setMorphology(vns, structure12_rec)
				relative_position = rec_relative
			end
			--vns.setGoal(vns, marker.positionV3 + vector3(-0.7,-0.7,0.7):rotate(marker.orientationQ), marker.orientationQ)
			---[[
			local target_position = marker.positionV3 + relative_position:rotate(marker.orientationQ)
			local dirVec = vector3(1,0,0):rotate(marker.orientationQ)
			local vertical_position = target_position - target_position:dot(dirVec) * dirVec
			local vertical_speed = vertical_position:normalize() * 0.1
			local move_speed = vector3(dirVec):rotate(marker.orientationQ) * 0.2

			vns.setGoal(vns, vector3(0,0,0), marker.orientationQ)
			vns.Spreader.emergency_after_core(vns, vertical_speed + move_speed, vector3())
			--]]
		else
			if api.stepCount < 200 then
				vns.setGoal(vns, vector3(0,0,0), quaternion())
				vns.Spreader.emergency_after_core(vns, vector3(0.1, 0, 0.1), vector3())
			end
		end
	end

	return false, true
end end