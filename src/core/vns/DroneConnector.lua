--[[
--	Drone connector
--	the drone will always try to recruit seen pipucks
--]]
logger.register("DroneConnector")

require("DeepCopy")
local SensorUpdater = require("SensorUpdater")
local Transform = require("Transform")


local DroneConnector = {}

function DroneConnector.preStep(vns)
	vns.connector.seenRobots = {}
end

function DroneConnector.step(vns)
	-- add tags into seen Robots
	vns.api.droneAddSeenRobots(
		vns.api.droneDetectTags(),
		vns.connector.seenRobots
	)

	local seenObstacles = {}
	vns.api.droneAddObstacles(
		vns.api.droneDetectTags(),
		seenObstacles
	)

	-- report my sight to all seen pipucks, and drones in parent and children
	--[[
	if vns.parentR ~= nil and vns.parentR.robotTypeS == "drone" then
		vns.Msg.send(vns.parentR.idS, "reportSight", {mySight = vns.connector.seenRobots})
	end

	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.robotTypeS == "drone" then
			vns.Msg.send(idS, "reportSight", {mySight = vns.connector.seenRobots})
		end
	end

	for idS, robotR in pairs(vns.connector.seenRobots) do
		vns.Msg.send(idS, "reportSight", {mySight = vns.connector.seenRobots})
	end
	--]]

	-- broadcast my sight so other drones would see me
	local myRobotRT = DeepCopy(vns.connector.seenRobots)
	vns.Msg.send("ALLMSG", "reportSight", {mySight = myRobotRT, myObstacles = seenObstacles})

	-- receive sight report, generate quadcopters
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		-- Extend vision only if I can't see this drone
		if vns.connector.seenRobots[msgM.fromS] == nil then
			if msgM.dataT.mySight[vns.Msg.myIDS()] ~= nil then
				-- if I'm seen, add what it can see
				DroneConnector.calcQuadBySightR(msgM.fromS, msgM.dataT.mySight, vns.connector.seenRobots)
			else
				-- if I'm not in sight, find common robot and try to add it.
				vns.connector.seenRobots[msgM.fromS] = DroneConnector.calcQuadByCommonR(msgM.fromS, myRobotRT, msgM.dataT.mySight)
			end
		end
	end

	-- convert vns.connector.seenRobots from real frame into virtual frame
	local seenRobotinR = vns.connector.seenRobots
	vns.connector.seenRobots = {}
	for idS, robotR in pairs(seenRobotinR) do
		vns.connector.seenRobots[idS] = {
			idS = idS,
			robotTypeS = robotR.robotTypeS,
			positionV3 = vns.api.virtualFrame.V3_RtoV(robotR.positionV3),
			orientationQ = vns.api.virtualFrame.Q_RtoV(robotR.orientationQ),
		}
	end

	-- convert seenObstacles from real frame into virtual frame seenObstaclesInVirtualFrame
	local seenObstaclesInVirtualFrame = {}
	for i, v in ipairs(seenObstacles) do
		seenObstaclesInVirtualFrame[i] = {
			type = v.type,
			robotTypeS = v.robotTypeS,
			positionV3 = vns.api.virtualFrame.V3_RtoV(v.positionV3),
			orientationQ = vns.api.virtualFrame.Q_RtoV(v.orientationQ),
			locationInRealFrame = {
				positionV3 = vector3(v.positionV3),
				orientationQ = quaternion(v.orientationQ),
			}
		}
	end

	SensorUpdater.updateObstaclesByRealFrame(vns, seenObstaclesInVirtualFrame, vns.avoider.obstacles)

	--[[ draw obstacles
	if vns.parentR == nil then
	for i, ob in ipairs(vns.avoider.obstacles) do
		local color = "green"
		if ob.unseen_count ~= vns.api.parameters.obstacle_unseen_count then color = "red" end
		vns.api.debug.drawArrow(color, 
		                        vns.api.virtualFrame.V3_VtoR(vector3(0,0,0)), 
		                        vns.api.virtualFrame.V3_VtoR(vector3(ob.positionV3))
		                       )
		vns.api.debug.drawArrow(color, 
		                        vns.api.virtualFrame.V3_VtoR(vector3(ob.positionV3)),
		                        vns.api.virtualFrame.V3_VtoR(vector3(ob.positionV3) + vector3(0.1,0,0):rotate(ob.orientationQ))
		                       )
	end
	end
	--]]
end

function DroneConnector.calcQuadByCommonR(idS, myVehiclesTR, yourVehiclesTR)
	local quadR = nil
	local n = 0
	local totalAcc = Transform.createAccumulator()
	for _, robotR in pairs(yourVehiclesTR) do
		if myVehiclesTR[robotR.idS] ~= nil then
			local myRobotR = myVehiclesTR[robotR.idS]
			local positionV3 = 
			    myRobotR.positionV3 +
			    vector3(-robotR.positionV3):rotate(
			        --robotR.orientationQ:inverse() * myRobotR.orientationQ
			        myRobotR.orientationQ * robotR.orientationQ:inverse() 
			    )
			local orientationQ = myRobotR.orientationQ * robotR.orientationQ:inverse()

			Transform.addAccumulator(totalAcc, {positionV3 = positionV3, orientationQ = orientationQ})
			n = n + 1
		end
	end
	if n >= 1 then
		local average = Transform.averageAccumulator(totalAcc)
		quadR = {
			idS = idS,
			positionV3 = average.positionV3,
			orientationQ = average.orientationQ,
			robotTypeS = "drone",
		}
	end
	return quadR
end

function DroneConnector.calcQuadBySightR(idS, yourVehiclesTR, seenRobots)
	-- I'm seen in this report sight, add this drone into seenRobots
	local common = yourVehiclesTR[vns.Msg.myIDS()]
	local quad = {
		idS = idS,
		positionV3 = 
			vector3(-common.positionV3):rotate(
			common.orientationQ:inverse()),
		orientationQ = 
			common.orientationQ:inverse(),
		robotTypeS = "drone",
	}

	seenRobots[quad.idS] = quad

	-- add other robots to seenRobots
	for idS, R in pairs(yourVehiclesTR) do
		if idS ~= vns.Msg.myIDS() and seenRobots[idS] == nil then
			seenRobots[idS] = {
				idS = idS,
				positionV3 = quad.positionV3 + 
							 vector3(R.positionV3):rotate(quad.orientationQ),
				orientationQ = quad.orientationQ * R.orientationQ,
				robotTypeS = R.robotTypeS,
			}
		end
	end
end

function DroneConnector.create_droneconnector_node(vns)
	return function()
		vns.DroneConnector.step(vns)
		return false, true
	end
end

return DroneConnector
