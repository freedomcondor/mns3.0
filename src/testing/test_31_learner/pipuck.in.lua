if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require("morphology")

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	--if vns.idS == "builderbot21" then vns.idN = 1 end
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)
	bt = BT.create(vns.create_vns_node(vns, {
		navigation_node_post_core = {type = "sequence", children = {
			vns.Learner.create_learner_node(vns),
			--vns.Learner.create_knowledge_node(vns, "print_test"),
		}}
	}))

	if robot.id == "pipuck1" then
		vns.learner.knowledges["print_test"] = {hash = 1, rank = 1, node = [[
			function()
				print("test")
				return false, true
			end
		]]}
		vns.learner.knowledges["print_twice"] = {hash = 1, rank = 1, node = [[
		{type = "sequence", children = {
			vns.Learner.create_knowledge_node(vns, "print_test"),
			vns.Learner.create_knowledge_node(vns, "print_test2"),
		}}]]}
	end
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	if robot.id == "pipuck1" then
		vns.Learner.spreadKnowledge(vns, "print_test", vns.learner.knowledges["print_test"])
		vns.Learner.spreadKnowledge(vns, "print_twice", vns.learner.knowledges["print_twice"])
	end

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
end

function destroy()
	vns.destroy()
	api.destroy()
end
