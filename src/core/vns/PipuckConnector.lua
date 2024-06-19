--[[
--	Pipuck connector
--	the Pipuck listen to drone's recruit message, with deny
--]]

local PipuckConnector = {}
local SensorUpdater = require("SensorUpdater")

function PipuckConnector.reset(vns)
	vns.connector.pipuckReportSightCountDown = vns.Parameters.connector_pipuck_report_sight_count_down
end

function PipuckConnector.preStep(vns)
	vns.connector.seenRobots = {}
end

function PipuckConnector.step(vns)
	local seenObstacles = {}
	local seenBlocks = {}

	local valid_report_flag = false
	-- For any sight report, update quadcopter and other pipucks to seenRobots
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		if msgM.dataT.mySight[vns.Msg.myIDS()] ~= nil then
			valid_report_flag = true
			-- I'm seen in this report sight, add this drone into seenRobots
			local common = msgM.dataT.mySight[vns.Msg.myIDS()]
			local quad = {
				idS = msgM.fromS,
				positionV3 = 
					vector3(-common.positionV3):rotate(
					common.orientationQ:inverse()),
				orientationQ = 
					common.orientationQ:inverse(),
				robotTypeS = "drone",
			}

			if vns.connector.seenRobots[quad.idS] == nil then --TODO average
				vns.connector.seenRobots[quad.idS] = quad
			end

			-- add other pipucks to seenRobots
			for idS, R in pairs(msgM.dataT.mySight) do
				if idS ~= vns.Msg.myIDS() and vns.connector.seenRobots[idS] == nil and 
				   R.robotTypeS ~= "drone" then -- TODO average
					vns.connector.seenRobots[idS] = {
						idS = idS,
						positionV3 = quad.positionV3 + 
						             vector3(R.positionV3):rotate(quad.orientationQ),
						orientationQ = quad.orientationQ * R.orientationQ,
						robotTypeS = R.robotTypeS,
					}
				end
			end

			-- add obstacles
			if msgM.dataT.myObstacles ~= nil then
				for i, obstacle in ipairs(msgM.dataT.myObstacles) do
					local positionV3 = quad.positionV3 + 
									   vector3(obstacle.positionV3):rotate(quad.orientationQ)
					local orientationQ = quad.orientationQ * obstacle.orientationQ 

					-- check positionV3 in existing obstacles
					local flag = true
					for j, existing_ob in ipairs(seenObstacles) do
						if (existing_ob.positionV3 - positionV3):length() < vns.api.parameters.obstacle_match_distance then
							flag = false
							break
						end
					end

					if flag == true then
						seenObstacles[#seenObstacles + 1] = {
							type = obstacle.type,
							robotTypeS = obstacle.robotTypeS,
							positionV3 = positionV3,
							orientationQ = orientationQ,
						}
					end
				end
			end

			-- add blocks
			if msgM.dataT.myBlocks ~= nil then
				for i, block in ipairs(msgM.dataT.myBlocks) do
					local positionV3 = quad.positionV3 +
					                   vector3(block.positionV3):rotate(quad.orientationQ)
					local orientationQ = quad.orientationQ * block.orientationQ

					-- check positionV3 in existing obstacles
					local flag = true
					for j, existing_ob in ipairs(seenBlocks) do
						if (existing_ob.positionV3 - positionV3):length() < vns.api.parameters.obstacle_match_distance and
						   existing_ob.type == block.type then
							flag = false
							break
						end
					end

					if flag == true then
						seenBlocks[#seenBlocks + 1] = {
							type = block.type,
							robotTypeS = block.robotTypeS,
							positionV3 = positionV3,
							orientationQ = orientationQ,
						}
					end
				end
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
		}
	end

	SensorUpdater.updateObstacles(vns, seenObstaclesInVirtualFrame, vns.avoider.obstacles)

	-- if no valid report, keep blocks for a while before forget
	if valid_report_flag == false then
		vns.connector.pipuckReportSightCountDown = vns.connector.pipuckReportSightCountDown - 1
		if vns.connector.pipuckReportSightCountDown < 0 then
			vns.avoider.blocks = {}
		end
	else
	-- valid report, update blocks
		vns.connector.pipuckReportSightCountDown = vns.Parameters.connector_pipuck_report_sight_count_down

		-- convert blocks from real frame into virtual frame
		local seenBlocksInVirtualFrame = {}
		for i, v in ipairs(seenBlocks) do
			seenBlocksInVirtualFrame[i] = {
				robotTypeS = v.robotTypeS,
				type = v.type,
				positionV3 = vns.api.virtualFrame.V3_RtoV(v.positionV3),
				orientationQ = vns.api.virtualFrame.Q_RtoV(v.orientationQ),
			}
		end

		vns.avoider.blocks = seenBlocksInVirtualFrame
		--SensorUpdater.updateObstacles(vns, seenBlocksInVirtualFrame, vns.avoider.blocks)
	end

	--[[ draw obstacles
	for i, ob in ipairs(vns.avoider.obstacles) do
		local color = "green"
		if ob.unseen_count ~= 3 then color = "red" end
		vns.api.debug.drawArrow(color,
		                        vns.api.virtualFrame.V3_VtoR(vector3(0,0,0)),
		                        vns.api.virtualFrame.V3_VtoR(vector3(ob.positionV3))
		                       )
		vns.api.debug.drawArrow(color,
		                        vns.api.virtualFrame.V3_VtoR(vector3(ob.positionV3)),
		                        vns.api.virtualFrame.V3_VtoR(vector3(ob.positionV3) + vector3(0.1,0,0):rotate(ob.orientationQ))
		                       )
	end
	--]]
end

function PipuckConnector.create_pipuckconnector_node(vns)
	return function()
		vns.PipuckConnector.step(vns)
		return false, true
	end
end

return PipuckConnector
