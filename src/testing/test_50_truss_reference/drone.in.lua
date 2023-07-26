if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
logger.enable("TrussReferencer")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require(robot.params.structure or "morphology_20")

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

	bt = BT.create(vns.create_vns_node(vns))
	api.debug.show_all = true
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
	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end