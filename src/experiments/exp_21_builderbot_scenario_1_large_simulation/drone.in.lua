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

center_block_type = tonumber(robot.params.center_block_type)
usual_block_type = tonumber(robot.params.usual_block_type)
pickup_block_type = tonumber(robot.params.pickup_block_type)


local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		structure2,
		structure3,
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
	--[[
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
		}}
	--]]
	bt = BT.create(vns.create_vns_node(vns, {connector_recruit_only_necessary = gene.children, connector_no_recruit = true}))

	api.debug.recordSwitch = true
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false}, true)

	-- show type blocks
	local type1 = center_block_type
	local type2 = pickup_block_type
	for i, block in ipairs(vns.avoider.blocks) do
		if block.type == type1 then
			vns.api.debug.drawRing("red", vns.api.virtualFrame.V3_VtoR(block.positionV3), 0.1, true)
		elseif block.type == type2 then
			vns.api.debug.drawRing("green", vns.api.virtualFrame.V3_VtoR(block.positionV3), 0.1, true)
		end
	end

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end
