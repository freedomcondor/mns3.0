-- IntersectionDetector ------------------------------
------------------------------------------------------
local IntersectionDetector = {}

--[[
	related data:
	vns.intersectiondetector.seenForeignRobots.parentPositionV3 and goalPositionV3
--]]

function IntersectionDetector.create(vns)
	vns.intersectionDetector = {}
	vns.intersectionDetector.seenForeignRobots = {}
	vns.intersectionDetector.intersectionList = {}
	IntersectionDetector.reset(vns)
end

function IntersectionDetector.reset(vns)
	vns.intersectionDetector.seenForeignRobots = {}
	vns.intersectionDetector.intersectionList = {}
end

function IntersectionDetector.preStep(vns)
	vns.intersectionDetector.seenForeignRobots = {}
end

function IntersectionDetector.step(vns)
	vns.connector.greenLight = nil

	-- stabilizer hack
	if vns.stabilizer.referencing_me == true then return end

	-- create foreign robot list
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if (vns.parentR == nil or vns.parentR.idS ~= idS) and
		   vns.childrenRT[idS] == nil then
			vns.intersectionDetector.seenForeignRobots[idS] = robotR
		end
	end
	-- receive goal and parent location from foreign robots
	for idS, robotR in pairs(vns.intersectionDetector.seenForeignRobots) do
		for _, msgM in ipairs(vns.Msg.getAM(idS, "IntersectionInformationReport")) do
			robotR.parentIdS = msgM.dataT.parentIdS
			robotR.parentPositionV3 = robotR.positionV3 + vector3(msgM.dataT.parentPositionV3):rotate(robotR.orientationQ)
			robotR.goalPositionV3 = robotR.positionV3 + vector3(msgM.dataT.goalPositionV3):rotate(robotR.orientationQ)
		end
	end

	-- check parent intersection
	for idS, robotR in pairs(vns.intersectionDetector.seenForeignRobots) do
		if vns.parentR ~= nil and robotR.parentIdS ~= nil and
		   vns.parentR.idS ~= robotR.parentIdS then
			-- check if we have parent intersection
			local A = vector3(vns.parentR.positionV3):cross(robotR.parentPositionV3)
			local B = vector3(vns.parentR.positionV3):cross(robotR.positionV3)

			local C = vector3(robotR.parentPositionV3 - robotR.positionV3):cross(vector3() - robotR.positionV3)
			local D = vector3(robotR.parentPositionV3 - robotR.positionV3):cross(vns.parentR.positionV3 - robotR.positionV3)

			if A:dot(B) < 0 and C:dot(D) < 0 then
				-- we have parent intersection
				-- check if our goal switch can be better
				if vns.goal.positionV3 ~= nil and robotR.goalPositionV3 ~= nil then
					local current_cost = vns.goal.positionV3:length()
					if (robotR.goalPositionV3 - robotR.positionV3):length() > current_cost then 
						current_cost = (robotR.goalPositionV3 - robotR.positionV3):length()
					end
					local new_cost = robotR.goalPositionV3:length()
					if (vns.goal.positionV3 - robotR.positionV3):length() > new_cost then
						new_cost = (vns.goal.positionV3 - robotR.positionV3):length()
					end

					local A = vector3(vns.goal.positionV3):cross(robotR.goalPositionV3)
					local B = vector3(vns.goal.positionV3):cross(robotR.positionV3)

					local C = vector3(robotR.goalPositionV3 - robotR.positionV3):cross(vector3() - robotR.positionV3)
					local D = vector3(robotR.goalPositionV3 - robotR.positionV3):cross(vns.goal.positionV3 - robotR.positionV3)
					if (A:dot(B) < 0 and C:dot(D) < 0) or 
					   (vns.scalemanager.depth == 1 and new_cost < current_cost) or
					   (vns.scalemanager.depth > 1 and new_cost + math.sqrt(2) - 1 < current_cost) then
						-- we have switch intersection
						vns.api.debug.drawRing("red", vector3(0,0,0.3), 0.1)
						vns.api.debug.drawRing("red", vector3(0,0,0.32), 0.1)
						vns.api.debug.drawRing("red", vector3(0,0,0.34), 0.1)

						if vns.intersectionDetector.intersectionList[idS] ~= nil then
							vns.intersectionDetector.intersectionList[idS].detect = true
							vns.intersectionDetector.intersectionList[idS].count = 1 + 
								vns.intersectionDetector.intersectionList[idS].count
							if vns.intersectionDetector.intersectionList[idS].count >= 15 then
								-- need to break some link
								if vns.parentR.positionV3:length() > (robotR.parentPositionV3 - robotR.positionV3):length() then
									if vns.connector.greenLight ~= nil then
										if robotR.positionV3:length() <
										   vns.intersectionDetector.seenForeignRobots[vns.connector.greenLight].positionV3:length() then
											vns.connector.greenLight = idS
										end
									else
										vns.connector.greenLight = idS
									end
								end
							end
						else
							vns.intersectionDetector.intersectionList[idS] = {detect = true, count = 0}
						end
					end
				end
			end
		end
	end

	if vns.connector.greenLight ~= nil then
		vns.connector.greenLight = vns.intersectionDetector.seenForeignRobots[vns.connector.greenLight].parentIdS
	end

	for idS, item in pairs(vns.intersectionDetector.intersectionList) do
		if item.detect ~= true then
			vns.intersectionDetector.intersectionList[idS] = nil
		end
		item.detect = nil 
	end

	-- send my parent and goal to foreign robots
	for idS, robotR in pairs(vns.intersectionDetector.seenForeignRobots) do
		local send_parentIdS = nil
		local send_parentPositionV3 = vector3()
		if vns.parentR ~= nil then 
			send_parentIdS = vns.parentR.idS
			send_parentPositionV3 = vns.parentR.positionV3 
		end
		local send_goalPositionV3 = vns.goal.positionV3 or vector3()
		vns.Msg.send(idS, "IntersectionInformationReport", {
			parentIdS = send_parentIdS,
			parentPositionV3 = vns.api.virtualFrame.V3_VtoR(send_parentPositionV3),
			goalPositionV3 = vns.api.virtualFrame.V3_VtoR(send_goalPositionV3),
		})
	end
end

------ behaviour tree ---------------------------------------
function IntersectionDetector.create_intersectiondetector_node(vns)
	return function()
		IntersectionDetector.step(vns)
		return false, true
	end
end

return IntersectionDetector
