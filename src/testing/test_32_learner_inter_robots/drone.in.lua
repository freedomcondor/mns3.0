if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
--local api = require("droneAPI")
api = require("droneAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

logger.disable()
logger.enable("main")
logger.enable("Learner")

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
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)
	bt = BT.create(vns.create_vns_node(vns, {
		navigation_node_post_core = {type = "sequence", children = {
			vns.Learner.create_learner_node(vns),
			vns.Learner.create_knowledge_node(vns, "search_and_rescue"),
		}}
	}))

	if robot.id == "drone1" then
		vns.learner.knowledge["search_and_rescue"] = [[
			{type = "selector", children = {
				{type = "sequence", children = {
					vns.Learner.create_knowledge_node(vns, "search"),
					vns.Learner.create_knowledge_node(vns, "rescue"),
				}},
				function() return false, true end -- always return true
			}}
		]]
		vns.learner.knowledge["search"] = [[
			function()
				if vns.avoider.obstacles[1] ~= nil then
					print("I see a block")
					data = {target = vns.avoider.obstacles[1]}
					return false, true
				else
					return false, false
				end
			end
		]]
	end
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

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
