if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

logger.enable("DroneConnector")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require("morphology")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure,
	}
}

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	--if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.idN = 0
	vns.setGene(vns, gene)

	bt = BT.create(vns.create_vns_node(vns, {connector_recruit_only_necessary = gene.children, connector_no_recruit = true}))
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

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end
