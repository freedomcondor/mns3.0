if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

Transform = require("Transform")

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
			vns.Learner.create_knowledge_node(vns, "execute_rescue"),
		}}
	}))

	if robot.id == "pipuck1" then
		vns.learner.knowledges["rescue"] = {hash = 1, rank = 1, node = string.format([[
			function()
				local childID = "%s"
				if vns.childrenRT[childID] ~= nil and
				   data.target ~= nil then
					vns.Msg.send(childID, "obstacle", {
						obstacle = {
							positionV3 = vns.api.virtualFrame.V3_VtoR(data.target.positionV3),
							orientationQ = vns.api.virtualFrame.Q_VtoR(data.target.orientationQ),
						}
					})
				end
				return false, true
			end
		]], robot.id)}

		vns.learner.knowledges["execute_rescue"] = {hash = 1, rank = 1, node = [[
			function()
				if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "obstacle")) do
					local target = {
						positionV3 = msgM.dataT.obstacle.positionV3,
						orientationQ = msgM.dataT.obstacle.orientationQ,
					}
					Transform.AxBisC(vns.parentR, target, target)

					vns.setGoal(vns, target.positionV3, target.orientationQ)
				end end
				return false, true
			end
		]]}
	end

	if robot.id == "pipuck2" then
		vns.learner.knowledges["rescue"] = {hash = 2, rank = 2, node = string.format([[
			function()
				local childID = "%s"
				if vns.childrenRT[childID] ~= nil and
				   data.target ~= nil then
					local transV3 = vector3(data.target.positionV3 - vns.childrenRT[childID].positionV3):normalize() * 0.01
					vns.Msg.send(childID, "obstacle_trans", {
						obstacle = {
							transV3 = vns.api.virtualFrame.V3_VtoR(transV3),
						}
					})
				end
				return false, true
			end
		]], robot.id)}

		vns.learner.knowledges["execute_rescue"] = {hash = 1, rank = 1, node = [[
			function()
				if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "obstacle_trans")) do
					local trans = msgM.dataT.obstacle.transV3
					trans:rotate(vns.parentR.orientationQ)

					vns.setGoal(vns, vector3(), quaternion())
					vns.goal.transV3 = trans
				end end
				return false, true
			end
		]]}
	end
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	if vns.learner.knowledges["rescue"] ~= nil then
		vns.Learner.spreadKnowledge(vns, "rescue", vns.learner.knowledges["rescue"])
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
