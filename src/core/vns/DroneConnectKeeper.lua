--[[
--	Drone connector
--	the drone will always try to recruit seen pipucks
--]]
logger.register("DroneConnectKeeper")

Transform = require("Transform")

local DroneConnectKeeper = {}

function DroneConnectKeeper.step(vns)
	local connectKeeperSpeed = {transV3 = vector3(), rotateV3 = vector3()}

	local neighbours = {}
	for idS, childR in pairs(vns.childrenRT) do
		neighbours[idS] = childR
	end
	if vns.parentR ~= nil then
		neighbours[vns.parentR.idS] = vns.parentR
	end

	for idS, neighborR in pairs(neighbours) do
		if neighborR.seenThrough ~= nil and #neighborR.seenThrough == 1 then
			if neighborR.seenThrough[1] == "seen" then
				local relativePositionV3 = Transform.AxCis0(neighborR).positionV3
				local KeepSpeedinUpperDrone = calcVectorFromPositions(relativePositionV3, neighborR)
				local keepSpeed = KeepSpeedinUpperDrone:rotate(neighborR.orientationQ)
				connectKeeperSpeed.transV3 =
					connectKeeperSpeed.transV3 + keepSpeed
			end
			if vns.connector.seenRobots[neighborR.seenThrough[1]] ~= nil and
			   vns.connector.seenRobots[neighborR.seenThrough[1]].positionV3.z > 0 then
				local relativePositionV3 = Transform.AxCis0(neighborR).positionV3
				local KeepSpeedinUpperDrone = calcVectorFromPositions(relativePositionV3, neighborR)
				local keepSpeed = KeepSpeedinUpperDrone:rotate(neighborR.orientationQ)
				connectKeeperSpeed.transV3 =
					connectKeeperSpeed.transV3 + keepSpeed
			end
			if neighborR.seenThrough[1] == "direct" then
				local relativePositionV3 = vns.api.virtualFrame.V3_VtoR(neighborR.positionV3)
				local KeepSpeedinUpperDrone = calcVectorFromPositions(relativePositionV3, neighborR)
				local keepSpeed = vns.api.virtualFrame.V3_RtoV(-KeepSpeedinUpperDrone)
				connectKeeperSpeed.transV3 =
					connectKeeperSpeed.transV3 + keepSpeed
			end
			if vns.connector.seenRobots[neighborR.seenThrough[1]] ~= nil and
			   vns.connector.seenRobots[neighborR.seenThrough[1]].positionV3.z < 0 then
				local relativePositionV3 = Transform.AxCis0(neighborR).positionV3
				local KeepSpeedinUpperDrone = calcVectorFromPositions(relativePositionV3, neighborR)
				local keepSpeed = KeepSpeedinUpperDrone:rotate(neighborR.orientationQ)
				connectKeeperSpeed.transV3 =
					connectKeeperSpeed.transV3 + keepSpeed
			end
		end
	end

	vns.goal.transV3 = vns.goal.transV3 + connectKeeperSpeed.transV3
	vns.goal.rotateV3 = vns.goal.rotateV3 + connectKeeperSpeed.rotateV3

	---[[
	local r = 0.6
	local l = 3
	vns.api.debug.drawArrow("green", vector3(), vector3( l * r,  l * r, -l), true)
	vns.api.debug.drawArrow("green", vector3(), vector3(-l * r,  l * r, -l), true)
	vns.api.debug.drawArrow("green", vector3(), vector3( l * r, -l * r, -l), true)
	vns.api.debug.drawArrow("green", vector3(), vector3(-l * r, -l * r, -l), true)

	vns.api.debug.drawArrow("green", vector3(), vector3(     0,  l * r, -l), true)
	vns.api.debug.drawArrow("green", vector3(), vector3(     0, -l * r, -l), true)
	vns.api.debug.drawArrow("green", vector3(), vector3( l * r,      0, -l), true)
	vns.api.debug.drawArrow("green", vector3(), vector3(-l * r,      0, -l), true)
	--]]
end

function calcVectorFromPositions(relativePositionV3, neighborR)
	-- positionV3 is the relative position3 from the upper drone to the lower drone
	local targetSpeedV3 = vector3()

	local margin = 0.5
	local rate = 0.6

	local A = margin
	local B = rate * A

	local x0 = relativePositionV3.x
	local y0 = relativePositionV3.y
	local z0 = relativePositionV3.z

	local A2 = A*A
	local B2 = B*B
	local x02 = x0*x0
	local y02 = y0*y0
	local z02 = z0*z0

	if z02/A2 - x02/B2 < 1 then
		-- calc normal vector
		--[[
		local D2 = z02/A2 - x02/B2
		local n_z = z0*A2/D2
		local n_x = x0*B2/D2
		local nV3 = vector3(n_x, 0, n_z):normalize()
		--]]
		local nV3 = vector3(-x0, 0, -math.abs(x0 * (B/A))):normalize()
		local mag = 1 - (z02/A2 - x02/B2)
		if mag > 0.05 then mag = 0.05 end

		targetSpeedV3 = 
			targetSpeedV3 + nV3 * mag
		---[[
		vns.api.debug.drawArrow(
			"red",
			vector3(),
			vns.api.virtualFrame.V3_VtoR(
				vector3(
					neighborR.positionV3 * (
						(neighborR.positionV3:length() - 0.2) / neighborR.positionV3:length()
					)
				)
			),
			true
		)
		--]]
	end

	if z02/A2 - y02/B2 < 1 then
		-- calc normal vector
		--[[
		local D2 = z02/A2 - y02/B2
		local n_z = z0*A2/D2
		local n_y = y0*B2/D2
		local nV3 = vector3(0, n_y, n_z):normalize()
		--]]
		local nV3 = vector3(0, -y0, -math.abs(x0 * (B/A))):normalize()
		local mag = 1 - (z02/A2 - y02/B2)
		if mag > 0.05 then mag = 0.05 end

		targetSpeedV3 = 
			targetSpeedV3 + nV3 * mag

		---[[
		vns.api.debug.drawArrow(
			"red",
			vector3(),
			vns.api.virtualFrame.V3_VtoR(
				vector3(
					neighborR.positionV3 * (
						(neighborR.positionV3:length() - 0.2) / neighborR.positionV3:length()
					)
				)
			),
			true
		)
		--]]
	end

	return targetSpeedV3
end

function DroneConnectKeeper.create_droneconnectkeeper_node(vns)
	return function()
		vns.DroneConnectKeeper.step(vns)
		return false, true
	end
end

return DroneConnectKeeper
