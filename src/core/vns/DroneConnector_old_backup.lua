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

	seenBlocks = {}
	vns.api.droneAddBlocks(
		vns.api.droneDetectTags(),
		seenBlocks
	)

	-- broadcast my sight so other drones would see me
	local myRobotRT = DeepCopy(vns.connector.seenRobots)
	vns.Msg.send("ALLMSG", "reportSight", {mySight = myRobotRT, myObstacles = seenObstacles, myBlocks = seenBlocks})

	-- Add seenThrough tag for direct seen robots
	for idS, robotR in pairs(vns.connector.seenRobots) do
		robotR.seenThrough = {"direct"}
	end

	--[[
	robotR.transformAcc = Transform.createAccumulator()
	robotR.transformAcc: = Transform.createAccumulator()
	Transform.addAccumulator(robotR.transformAcc, {positionV3 = robotR., orientationQ = orientationQ})
	--]]

	-- add robots that sees me
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		if msgM.dataT.mySight[vns.Msg.myIDS()] ~= nil then
			if vns.connector.seenRobots[msgM.fromS] == nil then
				local quad = {idS = msgM.fromS, robotTypeS = "drone"}
				Transform.AxCis0(msgM.dataT.mySight[vns.Msg.myIDS()], quad)
				vns.connector.seenRobots[quad.idS] = quad
				vns.connector.seenRobots[quad.idS].seenThrough = {"seen"}
			else
				table.insert(vns.connector.seenRobots[msgM.fromS].seenThrough, "seen")
			end
		end
	end

	-- add other robots that seen by robots that sees me
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do if msgM.dataT.mySight[vns.Msg.myIDS()] ~= nil then
		for idS, robotR in pairs(msgM.dataT.mySight) do if idS ~= vns.Msg.myIDS() then
			-- idS, robotR is one of such robot
			if vns.connector.seenRobots[idS] == nil then
				local quad = {idS = idS, robotTypeS = "drone"}
				quad.transformAcc = Transform.createAccumulator()
				Transform.addAccumulator(quad.transformAcc, Transform.AxBisC(vns.connector.seenRobots[msgM.fromS], robotR))

				vns.connector.seenRobots[idS] = quad
				vns.connector.seenRobots[idS].seenThrough = {msgM.fromS}
			else
				table.insert(vns.connector.seenRobots[idS].seenThrough, msgM.fromS)
				if vns.connector.seenRobots[idS].transformAcc ~= nil then
					Transform.addAccumulator(vns.connector.seenRobots[idS].transformAcc, Transform.AxBisC(vns.connector.seenRobots[msgM.fromS], robotR))
				end
			end
		end end
	end end

	-- add robots that sees common robot with me
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		for commonIdS, commonRobotRinItsSight in pairs(msgM.dataT.mySight) do if vns.connector.seenRobots[commonIdS] ~= nil and vns.connector.seenRobots[commonIdS].seenThrough[1] == "direct" then
				-- msgM.fromS is such robot, common Robot is commonRobotRinItsSight or vns.connector.seenRobots[commonIdS]
			if vns.connector.seenRobots[msgM.fromS] == nil then
				local quad = {idS = msgM.fromS, robotTypeS = "drone"}
				quad.transformAcc = Transform.createAccumulator()
				Transform.addAccumulator(quad.transformAcc, Transform.CxBisA(vns.connector.seenRobots[commonIdS], commonRobotRinItsSight))

				vns.connector.seenRobots[quad.idS] = quad
				vns.connector.seenRobots[quad.idS].seenThrough = {commonIdS}
			else
				table.insert(vns.connector.seenRobots[msgM.fromS].seenThrough, commonIdS)
				if vns.connector.seenRobots[msgM.fromS].transformAcc ~= nil then
					Transform.addAccumulator(vns.connector.seenRobots[msgM.fromS].transformAcc, Transform.CxBisA(vns.connector.seenRobots[commonIdS], commonRobotRinItsSight))
				end
			end
		end end
	end

	for idS, robotR in pairs(vns.connector.seenRobots) do
		if robotR.transformAcc ~= nil then
			Transform.averageAccumulator(robotR.transformAcc, robotR)
			robotR.transformAcc = nil
		end
	end

	--[[
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

	-- add seenThrough tag
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		if msgM.dataT.mySight[vns.Msg.myIDS()] ~= nil then
			-- if I'm seen, add what it can see
			for idS, robotR in pairs(msgM.dataT.mySight) do
			end
		end
	end
	--]]

	--[[
	if vns.api.parameters.second_report_sight == 12345 then
		-- run a second round of sight report, generate quadcopters
		local myRobotRT = DeepCopy(vns.connector.seenRobots)
		vns.Msg.send("ALLMSG", "reportSight_second", {mySight = myRobotRT})
		for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight_second")) do
			if vns.connector.seenRobots[msgM.fromS] ~= nil then
				local quad = vns.connector.seenRobots[msgM.fromS]
				-- add what it can see
				for idS, R in pairs(msgM.dataT.mySight) do
					if idS ~= vns.Msg.myIDS() and vns.connector.seenRobots[idS] == nil then
						vns.connector.seenRobots[idS] = {
							idS = idS,
							positionV3 = quad.positionV3 + 
										 vector3(R.positionV3):rotate(quad.orientationQ),
							orientationQ = quad.orientationQ * R.orientationQ,
							robotTypeS = R.robotTypeS,
						}
					end
				end
			end
		end
	end
	--]]

	-- convert vns.connector.seenRobots from real frame into virtual frame
	local seenRobotinR = vns.connector.seenRobots
	vns.connector.seenRobots = {}
	for idS, robotR in pairs(seenRobotinR) do
		vns.connector.seenRobots[idS] = {
			idS = idS,
			robotTypeS = robotR.robotTypeS,
			positionV3 = vns.api.virtualFrame.V3_RtoV(robotR.positionV3),
			orientationQ = vns.api.virtualFrame.Q_RtoV(robotR.orientationQ),
			seenThrough = robotR.seenThrough
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

function DroneConnector.create_droneconnector_node(vns)
	return function()
		vns.DroneConnector.step(vns)
		return false, true
	end
end

return DroneConnector
