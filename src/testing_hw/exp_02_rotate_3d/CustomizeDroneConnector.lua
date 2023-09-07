--[[
--	Drone connector
--	the drone will always try to recruit seen pipucks
--]]
logger.register("CustomizeDroneConnector")

require("DeepCopy")
local SensorUpdater = require("SensorUpdater")
local Transform = require("Transform")

local DroneConnector = {}

function create_global_tag_index()
	local base   = {-5, 2.5}
	local offset = {1.23, -1.23}
	local obstacle_locations = {}
	for i = 0, 8 do
 		for j = 0, 4 do
			x = base[1] + i * offset[1]
			y = base[2] + j * offset[2]
			id = i * 5 + j
			obstacle_locations[id] = {
				positionV3 = vector3(x, y, 0),
				orientationQ = quaternion(),
			}
		end
	end
	return obstacle_locations
end

function DroneConnector.create(vns)
	vns.droneconnector = {global_tag_index = create_global_tag_index()}
end

function DroneConnector.preStep(vns)
	vns.connector.seenRobots = {}
end

function DroneConnector.postStep(vns)
	vns.Msg.send("ALLMSG", "droneEstimateLocation", {estimateLocation = vns.api.estimateLocationInRealFrame})
end

function DroneConnector.step(vns)
	local seenObstacles = {}
	vns.api.droneAddObstacles(
		vns.api.droneDetectTags(),
		seenObstacles
	)

	--[[
	logger("I'm customoize drone connector")
	logger("seenObstacles")
	logger(seenObstacles)
	--]]

	local transAcc = Transform.createAccumulator()
	for id, eachObstacle in ipairs(seenObstacles) do
		local myTrans = Transform.CxBisA(
			vns.droneconnector.global_tag_index[eachObstacle.type],
			eachObstacle
		)
		Transform.addAccumulator(transAcc, myTrans)
	end
	local myTrans = Transform.averageAccumulator(transAcc)
	if transAcc.n == 0 then myTrans = nil end

	-- draw arrow to show the origin to varify my position
	if myTrans ~= nil then
		vns.droneconnector.myTrans = myTrans
		vns.droneconnector.myLastKnownTrans = myTrans
		local origin = Transform.AxCis0(myTrans)
		vns.api.debug.drawArrow("green", vector3(), origin.positionV3)
		vns.api.debug.drawArrow("green",
		                        origin.positionV3,
		                        origin.positionV3 + vector3(0.2,0,0):rotate(origin.orientationQ)
		                       )

		-- broadcast my trans so other drones would see me
		local myTransToSend = DeepCopy(myTrans)
		vns.Msg.send("ALLMSG", "reportTrans", {myTrans = myTransToSend})

		-- receive trans from other drones and add to seenRobots
		for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportTrans")) do
			local hisID = msgM.fromS
			local hisTrans = msgM.dataT.myTrans
			-- create this drone
			local quad = {idS = msgM.fromS, robotTypeS = "drone"}
			Transform.AxCisB(myTrans, hisTrans, quad)

			vns.connector.seenRobots[hisID] = quad

			--vns.api.debug.drawArrow("red", vector3(), quad.positionV3)
			--vns.api.debug.drawArrow("red", quad.positionV3, quad.positionV3 + vector3(0.3, 0, 0):rotate(quad.orientationQ))
		end
	else
		vns.droneconnector.myTrans = nil
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
			seenThrough = robotR.seenThrough
		}
	end

	-- convert seenObstacles from real frame into virtual frame
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
	vns.avoider.obstacles = seenObstaclesInVirtualFrame
end

function DroneConnector.create_droneconnector_node(vns)
	return function()
		vns.DroneConnector.step(vns)
		return false, true
	end
end

return DroneConnector
