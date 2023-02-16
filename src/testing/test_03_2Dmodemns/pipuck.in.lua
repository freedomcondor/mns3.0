if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()

	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	--[[
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
		}}
	--]]
	bt = BT.create(vns.create_vns_node(vns))
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	vns.goal.positionV3 = vector3(0.1, 0, 0.1)
	vns.goal.orientationQ = quaternion(math.pi/50, vector3(0, 0, 1))
	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = true})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
end

function destroy()
	vns.destroy()
	api.destroy()
end
