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

require("morphology")
local structure = create_node(
	tonumber(robot.params.droneN),
	tonumber(robot.params.disL)
)

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

	api.parameters.droneDefaultStartHeight = 0

	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)

	--if vns.idS == "drone1" then vns.idN = 1 end
	number = tonumber(string.match(robot.id, "%d+"))
	vns.idN = 1 - (number-1) / tonumber(robot.params.droneN)

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
	api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {color="blue", offset=vector3(), margin=0})
	api.debug.showParent(vns, {color="255,255,0", offset=vector3(), margin=0})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
return function()
	if vns.parentR == nil and vns.api.stepCount > 150 then
		vns.setGoal(vns, vector3(), quaternion())
		vns.Spreader.emergency_after_core(vns, vector3(0.8, 0, 0), vector3())
	end

	if vns.parentR == nil then
		vns.api.debug.drawArrow("red", vector3(0,0,0), vector3(0,0,-100), true)
	end

	return false, true
end end