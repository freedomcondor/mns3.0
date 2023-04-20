logger.register("Learner")
-- This module works with dynamic behavior tree
-- vns has to be global

local BT = require("DynamicBehaviorTree")

local Learner = {}

function Learner.create(vns)
	vns.learner = {
		knowledges = {}
		-- knowledges["rescue"] = {
		--     hash = 1
		--     rank = 1 -- the greater the better
		--     node = a string of the node, "function() .. end" or {type="sequence" children = {..}}
		--}
	}
end

function Learner.step(vns, BTchildren)
	for idS, robotR in pairs(vns.getNeighbours(vns)) do for _, msgM in ipairs(vns.Msg.getAM(idS, "knowledge")) do
		if vns.learner.knowledges[msgM.dataT.knowledgeID] == nil or 
		   (vns.learner.knowledges[msgM.dataT.knowledgeID].hash ~= msgM.dataT.knowledge.hash and
		    vns.learner.knowledges[msgM.dataT.knowledgeID].rank <  msgM.dataT.knowledge.rank
		   ) then
			vns.learner.knowledges[msgM.dataT.knowledgeID] = msgM.dataT.knowledge
		end
		Learner.spreadKnowledge(vns, msgM.dataT.knowledgeID, msgM.dataT.knowledge, idS)
	end end
end

function Learner.spreadKnowledge(vns, knowledgeID, knowledge, except)
	for sendToIDS, sendToRobotR in pairs(vns.getNeighbours(vns)) do
		if sendToIDS ~= except then
			vns.Msg.send(sendToIDS, "knowledge", {knowledgeID = knowledgeID, knowledge = knowledge})
		end
	end
end

function Learner.create_knowledge_node(vns, knowledgeID)
local knowledgeID = knowledgeID
local current_hash = nil
return {type = "sequence", dynamic = true, knowledgeID = knowledgeID, children = {
	function(BTchildren)
		if vns.learner.knowledges[knowledgeID] ~= nil and
		   vns.learner.knowledges[knowledgeID].hash ~= current_hash then
			BTchildren[2] = BT.create(load("return " .. vns.learner.knowledges[knowledgeID].node)())
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