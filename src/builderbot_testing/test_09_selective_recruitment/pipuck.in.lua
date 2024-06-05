if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

logger.enable()

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure1 = require("morphology1")
local structure2 = require("morphology2")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		structure2,
	}
}

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure1)
	bt = BT.create(vns.create_vns_node(vns, {
		connector_recruit_only_necessary = {structure1, structure2},
	}))
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	--logger(robot.radios.wifi.recv)
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	logger("seenBlocks")
	logger(vns.avoider.blocks)

	if vns.parentR == nil then
		if #vns.avoider.blocks ~= 0 then
			vns.setMorphology(vns, structure2)
		else
			vns.setMorphology(vns, structure1)
		end
	end
end

function destroy()
	vns.destroy()
	api.destroy()
end
