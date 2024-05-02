-- TrussReferencer -----------------------------------------
------------------------------------------------------
logger.register("TrussReferencer")

local Transform = require("Transform")

local TrussReferencer = {}

function TrussReferencer.create(vns)
	vns.trussReferencer = {}
end

function TrussReferencer.reset(vns)
end

function TrussReferencer.preStep(vns)
end

function TrussReferencer.step(vns)
	local safe_zone = vns.Parameters.safezone_drone_drone

	-- receive truss information
	local max_weight = 0
	local min_weight = math.huge
	if vns.allocator.target ~= nil and vns.allocator.target.idN >= 1 then
		local goalAcc = Transform.createAccumulator()
		--Transform.addAccumulator(goalAcc, vns.goal) -- goal from parent, from allocator

		local myGlobalTransform = {positionV3 = vns.allocator.target.globalPositionV3,
		                           orientationQ =vns.allocator.target.globalOrientationQ,
		                          } 
		
		for idS, robotR in pairs(vns.connector.seenRobots) do
			for _, msgM in ipairs(vns.Msg.getAM(idS, "truss")) do if msgM.dataT.vnsID == vns.idS then
				if msgM.dataT.weight > max_weight then max_weight = msgM.dataT.weight end
				if msgM.dataT.weight < min_weight then min_weight = msgM.dataT.weight end
			end end
		end

		for idS, robotR in pairs(vns.connector.seenRobots) do
			for _, msgM in ipairs(vns.Msg.getAM(idS, "truss")) do if msgM.dataT.vnsID == vns.idS then
				local yourTargetID = msgM.dataT.targetID
				local yourGlobalTransform = {positionV3 = vns.allocator.gene_index[yourTargetID].globalPositionV3,
				                             orientationQ = vns.allocator.gene_index[yourTargetID].globalOrientationQ,
				                            }
				local targetTransform = Transform.AxCisB(yourGlobalTransform, myGlobalTransform)
				local yourGoal = Transform.AxBisC(robotR, msgM.dataT.goal)
				local myGoal = Transform.AxBisC(yourGoal, targetTransform)
				local weight = 2 ^ (msgM.dataT.weight - max_weight)

				--if vns.goal.positionV3:length() < vns.Parameters.driver_arrive_zone then
					Transform.addAccumulator(goalAcc, myGoal, weight)

					--[[
					local color = "255,255,0,0"
					vns.api.debug.drawArrow(color,
											vns.api.virtualFrame.V3_VtoR(vector3(0,0,0)),
											vns.api.virtualFrame.V3_VtoR(robotR.positionV3)
										   )
					--]]
				--end
			end
		end end

		if vns.parentR ~= nil then
			Transform.averageAccumulator(goalAcc, vns.goal)
		end
	end

	if vns.allocator.target ~= nil and
	   vns.allocator.target.idN >= 1 then
		--if vns.goal.positionV3:length() < vns.Parameters.driver_arrive_zone then
			local weight = max_weight - 1
			if vns.parentR == nil then
				weight = vns.scalemanager.scale:totalNumber()
			end
			for idS, robotR in pairs(vns.connector.seenRobots) do
				if robotR.positionV3:length() < safe_zone then
					vns.Msg.send(idS, "truss", {targetID = vns.allocator.target.idN,
					                            goal = {positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
					                                    orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ)
					                                   },
					                            vnsID = vns.idS,
					                            weight = weight,
					                           }
					            )
				end
			end
		--end
	end
end

------ behaviour tree ---------------------------------------
function TrussReferencer.create_trussreferencer_node(vns)
	return function()
		TrussReferencer.step(vns)
		return false, true
	end
end

return TrussReferencer
