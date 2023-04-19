logger.register("Learner")
-- This module works with dynamic behavior tree
-- vns has to be global

local BT = require("DynamicBehaviorTree")

local Learner = {}

function Learner.create(vns)
	vns.learner = {
		knowledge = {}
	}
end

function Learner.step(vns, BTchildren)
	for idS, robotR in pairs(vns.getNeighbours(vns)) do for _, msgM in ipairs(vns.Msg.getAM(idS, "knowledge")) do
		vns.learner.knowledge[msgM.dataT.knowledgeID] = msgM.dataT.knowledgeNode
		Learner.spreadKnowledge(vns, msgM.dataT.knowledgeID, msgM.dataT.knowledgeNode, idS)
	end end
end

function Learner.spreadKnowledge(vns, knowledgeID, knowledgeNode, except)
	for sendToIDS, sendToRobotR in pairs(vns.getNeighbours(vns)) do
		if sendToIDS ~= except then
			vns.Msg.send(sendToIDS, "knowledge", {knowledgeID = knowledgeID, knowledgeNode = knowledgeNode})
		end
	end
end

function Learner.create_knowledge_node(vns, knowledgeID)
local knowledgeID = knowledgeID
return {type = "sequence", dynamic = true, knowledgeID = knowledgeID, children = {
	function(BTchildren)
		if vns.learner.knowledge[knowledgeID] ~= nil then
			BTchildren[2] = BT.create(load("return " .. vns.learner.knowledge[knowledgeID])())
		end
		return false, true
	end
}}
end

function Learner.create_learner_node(vns, option)
	-- option = {
	-- }
	return { type = "sequence", dynamic = true, children = {
		function(BTchildren)
			Learner.step(vns, BTchildren)
		end,
	}}
end

return Learner