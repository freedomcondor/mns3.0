-- BrainKeeper ---------------------------------------
------------------------------------------------------

local BrainKeeper = {}

--[[
--	vns.brainkeeper.brain = {positionV3, orientationQ}
--]]

function BrainKeeper.create(vns)
	vns.brainkeeper = {countdown = 0}
end

function BrainKeeper.reset(vns)
	vns.brainkeeper = {countdown = 0}
end

function BrainKeeper.deleteParent(vns)
end

function BrainKeeper.preStep(vns)
end

function BrainKeeper.step(vns)
	-- receive brain location from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "brain_location")) do
		vns.brainkeeper.brain = {
			positionV3 = vns.parentR.positionV3 +
			             vector3(msgM.dataT.positionV3):rotate(vns.parentR.orientationQ),
			orientationQ = vns.parentR.orientationQ * msgM.dataT.orientationQ,
		}
		vns.brainkeeper.grandParentID = msgM.dataT.grandParentID
		vns.brainkeeper.countdown = vns.Parameters.brainkeeper_time
	end end

	local positionV3 = vector3()
	local orientationQ = vns.api.virtualFrame.Q_VtoR(quaternion())
	if vns.brainkeeper.brain ~= nil then
		positionV3 = vns.api.virtualFrame.V3_VtoR(vns.brainkeeper.brain.positionV3)
		orientationQ = vns.api.virtualFrame.Q_VtoR(vns.brainkeeper.brain.orientationQ)
	end

	local grandParentID = nil
	if vns.parentR ~= nil then grandParentID = vns.parentR.idS end

	for idS, robotR in pairs(vns.childrenRT) do 
		vns.Msg.send(idS, "brain_location", {
			positionV3 = positionV3, orientationQ = orientationQ, grandParentID = grandParentID,
		})
	end

	if vns.brainkeeper.countdown > 0 then
		vns.brainkeeper.countdown = vns.brainkeeper.countdown - 1
	end
	if vns.brainkeeper.countdown == 0 then
		vns.brainkeeper.brain = nil
		vns.brainkeeper.grandParentID = nil
	end
end

function BrainKeeper.create_brainkeeper_node(vns)
	return function()
		BrainKeeper.step(vns)
		return false, true
	end
end

return BrainKeeper
