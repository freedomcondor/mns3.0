if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

logger.enable("DroneConnector")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require("morphology")

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	--if vns.idS == "builderbot21" then vns.idN = 1 end
	if vns.idS == vns.Parameters.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, structure)
	--[[
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
		}}
	--]]
	bt = BT.create(vns.create_vns_node(vns))
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	--[[
	logger("seenRobots")
	logger(vns.connector.seenRobots)
	logger("parent")
	logger(vns.parentR)
	logger("children")
	logger(vns.childrenRT)
	--]]
end

function destroy()
	vns.destroy()
	api.destroy()
end
