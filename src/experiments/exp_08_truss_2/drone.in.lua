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

require("trussGenerator")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)
local nodes = (n_drone - 4) / 4 / 3 - 1
local gene = create_beams(nodes, 1.5)

-- called when a child lost its parent
--[[
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure_man)
end
--]]

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local base_height = api.parameters.droneDefaultStartHeight + 2
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = base_height
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = base_height + 3
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = base_height + 6
	end
	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)

	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
				create_navigation_node(vns),
			}}}
		)
	)
	api.debug.show_all = true
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
	local function find_marker()
		for i, ob in ipairs(vns.collectivesensor.totalObstaclesList) do
			return ob
		end
	end
return function()
	-- fail safe
	--[[
	if vns.scalemanager.scale["drone"] == 1 and
	   vns.api.actuator.flight_preparation.state == "navigation" then
		vns.Spreader.emergency_after_core(vns, vector3(0,0,0.5), vector3())
		return false, true
	end
	--]]

	if vns.parentR == nil then
		local marker = find_marker()
		if marker ~= nil then
			local dis = 1
			local target = marker.positionV3 + vector3(-dis, -dis, dis):rotate(marker.orientationQ)
			vns.setGoal(vns, target, marker.orientationQ)
		end
	end
	return false, true
end end