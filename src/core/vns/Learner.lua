-- This module works with dynamic behavior tree
-- vns has to be global

local Learner = {}

function Learner.step(vns, BTchildren)

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