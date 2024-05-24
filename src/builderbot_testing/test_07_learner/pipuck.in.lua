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
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, structure)
	--[[
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
		}}
	--]]
	bt = BT.create(vns.create_vns_node(vns, {
		navigation_node_post_core = {type = "sequence", children = {
			vns.Learner.create_learner_node(vns),
			--vns.Learner.create_knowledge_node(vns, "print_test"),
		}}
	}))

	if robot.id == "pipuck2" then
		vns.learner.knowledges["move_forward"] = {hash = 1, rank = 1, node = [[
			function()
				vns.Spreader.emergency_after_core(vns, vector3(0.02,0,0), vector3())
				return false, true
			end
		]]}
	end
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	logger(robot.radios.wifi.recv)
	api.preStep()
	vns.preStep(vns)

	bt()

	if robot.id == "pipuck2" then
		vns.Learner.spreadKnowledge(vns, "move_forward", vns.learner.knowledges["move_forward"])
	end

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	logger("seenRobots--------")
	logger(vns.connector.seenRobots)
	logger("connector---------")
	logger(vns.connector)
	logger("parent------------")
	logger(vns.parentR)
	logger("children----------")
	logger(vns.childrenRT)
	logger("goal--------------")
	logger(vns.goal)
end

function destroy()
	vns.destroy()
	api.destroy()
end
