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
	if vns.allocator.target ~= nil and vns.allocator.target.idN >= 1 then
		local goalAcc = Transform.createAccumulator()
		Transform.addAccumulator(goalAcc, vns.goal)

		local myGlobalTransform = {positionV3 = vns.allocator.target.globalPositionV3,
		                           orientationQ =vns.allocator.target.globalOrientationQ,
		                          } 
		
		for idS, robotR in pairs(vns.connector.seenRobots) do
			for _, msgM in ipairs(vns.Msg.getAM(idS, "truss")) do if msgM.dataT.vnsID == vns.idS then
				local yourTargetID = msgM.dataT.targetID
				local yourGlobalTransform = {positionV3 = vns.allocator.gene_index[yourTargetID].globalPositionV3,
				                             orientationQ = vns.allocator.gene_index[yourTargetID].globalOrientationQ,
				                            }
				local targetTransform = Transform.AxCisB(yourGlobalTransform, myGlobalTransform)
				local yourGoal = Transform.AxBisC(robotR, msgM.dataT.goal)
				local myGoal = Transform.AxBisC(yourGoal, targetTransform)

				if vns.goal.positionV3:length() < vns.Parameters.driver_arrive_zone then
					Transform.addAccumulator(goalAcc, myGoal)

					--[[
					local color = "255,255,0,0"
					vns.api.debug.drawArrow(color,
											vns.api.virtualFrame.V3_VtoR(vector3(0,0,0)),
											vns.api.virtualFrame.V3_VtoR(robotR.positionV3)
										   )
					--]]
				end
			end
		end end

		if vns.parentR ~= nil then
			Transform.averageAccumulator(goalAcc, vns.goal)
		end
	end

	-- Stabilizer hack ------------------------------------------------------
	-- stop moving is I'm referenced  TODO: combine with goal_overwrite
	if vns.stabilizer.referencing_me == true then
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()
		if vns.stabilizer.referencing_me_goal_overwrite ~= nil then
			if vns.stabilizer.referencing_me_goal_overwrite.positionV3 ~= nil then
				vns.goal.positionV3 = vns.stabilizer.referencing_me_goal_overwrite.positionV3
			end
			if vns.stabilizer.referencing_me_goal_overwrite.orientationQ ~= nil then
				vns.goal.orientationQ = vns.stabilizer.referencing_me_goal_overwrite.orientationQ
			end
			vns.stabilizer.referencing_me_goal_overwrite = nil
		end
	end
	-- end Stabilizer hack ------------------------------------------------------

	if vns.allocator.target ~= nil and
	   vns.allocator.target.idN >= 1 then
		if vns.goal.positionV3:length() < vns.Parameters.driver_arrive_zone then
			for idS, robotR in pairs(vns.connector.seenRobots) do
				if robotR.positionV3:length() < safe_zone then
					vns.Msg.send(idS, "truss", {targetID = vns.allocator.target.idN,
					                            goal = {positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
					                                    orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ)
					                                   },
					                            vnsID = vns.idS,
					                           }
					            )
				end
			end
		end
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
