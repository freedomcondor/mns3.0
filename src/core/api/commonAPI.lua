local api = {}

-------------------------------------------------------------
---- parameters --------------------------
api.parameters = require("APIParameters")

---- hardware or simulation ------------------------
if robot.params.hardware == "true" then robot.params.hardware = true end
if robot.params.simulation == "true" then robot.params.simulation = true end
---- validity check, if setup invalid, consider hardware first for safety -------------------
if robot.params.hardware == true and robot.params.simulation == true then
	print("[Warning]: simulation and hardware both set to be true, overwrite hardware true and simulation false!")
	robot.params.simulation = nil
end
if robot.params.hardware ~= true and robot.params.simulation ~= true then
	print("[Warning]: simulation and hardware both unset, overwrite hardware true and simulation false!")
	robot.params.hardware = true
	robot.params.simulation = nil 
end
if robot.params.hardware == true then
	print("Hardware mode")
else
	print("Simulation mode")
end

-------------------------------------------------------------
---- Time -------------------------------------
api.time = {}
api.time.currentTime = robot.system.time
api.time.period = 0.2
function api.processTime()
	api.time.period = robot.system.time - api.time.currentTime
	api.time.currentTime = robot.system.time
end

-------------------------------------------------------------
---- step count -------------------------------
api.stepCount = 0

-------------------------------------------------------------
---- Location Estimate ------------------------
	-- estimates the location and orientation of the next step relative to current step
api.estimateLocation = {
	positionV3 = vector3(),
	orientationQ = quaternion(),
}

---- Virtual Coordinate Frame -----------------
	-- instead of turn(sometimes move) the real robot, we turn the virtual coordinate frame, 
	-- so that a pipuck can be "omni directional"
api.virtualFrame = {
	positionV3 = vector3(),  -- currently virtual position is not used
	orientationQ = quaternion(),
}

function api.virtualFrame.moveInSpeed(_speedV3)
	-- speedV3 in virtual frame
	local speedV3 = vector3(_speedV3)
	if api.parameters.mode_2D == true then speedV3.z = 0 end
	api.virtualFrame.positionV3 =
		api.virtualFrame.positionV3 +
		(speedV3 * api.time.period):rotate(api.virtualFrame.orientationQ)
end

function api.virtualFrame.rotateInSpeed(_speedV3)
	-- speedV3 in virtual frame
	local speedV3 = vector3(_speedV3)
	if api.parameters.mode_2D == true then speedV3.x = 0; speedV3.y = 0 end
	local axis = vector3(speedV3):normalize()
	if speedV3:length() == 0 then axis = vector3(0,0,1) end
	api.virtualFrame.orientationQ = 
		api.virtualFrame.orientationQ *
		quaternion(speedV3:length() * api.time.period, axis)
end

function api.virtualFrame.V3_RtoV(vec)
	return vector3(vec):rotate(api.virtualFrame.orientationQ:inverse())
end
function api.virtualFrame.V3_VtoR(vec)
	return vector3(vec):rotate(api.virtualFrame.orientationQ)
end
function api.virtualFrame.Q_RtoV(q)
	return api.virtualFrame.orientationQ:inverse() * q
end
function api.virtualFrame.Q_VtoR(q)
	return api.virtualFrame.orientationQ * q
end
--TODO: api.virtualFrame.Trans_RtoV({position, orientationQ})

---- Speed Control ---------------------------
function api.setSpeed()
	print("api.setSpeed needs to be implemented for specific robot")
end

function api.move(transV3, rotateV3)
	-- transV3 and rotateV3 in virtual frame
	local transRealV3 = api.virtualFrame.V3_VtoR(transV3)
	--local rotateRealV3 = api.virtualFrame.V3_VtoR(rotateV3)
	api.setSpeed(transRealV3.x, transRealV3.y, transRealV3.z, 0)
	-- rotate virtual frame
	api.virtualFrame.rotateInSpeed(rotateV3)
	-- estimate location of the new step
	api.estimateLocation.positionV3 = transV3 * api.time.period
	local axis = vector3(rotateV3):normalize()
	if rotateV3:length() == 0 then axis = vector3(0,0,1) end
	api.estimateLocation.orientationQ = 
		quaternion(rotateV3:length() * api.time.period, axis)
end

---- Debug Draw -------------------------------
api.debug = {}
function api.debug.drawArrow(color, begin, finish, essential)
	if api.debug.show_all == false then return end
	if api.debug.show_all ~= true and essential ~= true then return end
	if robot.debug == nil then return end
	-- parse color
	local colorArray = {}
	for word in string.gmatch(color, '([^,]+)') do
		colorArray[#colorArray + 1] = word
	end 
	-- draw
	if tonumber(colorArray[1]) == nil then
		robot.debug.draw_arrow(begin, finish, color)
	else
		robot.debug.draw_arrow(begin, finish, 
		                       tonumber(colorArray[1]),
		                       tonumber(colorArray[2]),
		                       tonumber(colorArray[3])
	                          )
	end
end

function api.debug.drawRing(color, middle, radius, essential)
	if api.debug.show_all == false then return end
	if api.debug.show_all ~= true and essential ~= true then return end
	if robot.debug == nil then return end
	-- parse color
	local colorArray = {}
	for word in string.gmatch(color, '([^,]+)') do
		colorArray[#colorArray + 1] = word
	end 
	if tonumber(colorArray[1]) == nil then
		robot.debug.draw_ring(middle, radius, color) -- 0,0,255 (blue)
	else
		robot.debug.draw_ring(middle, radius, 
		                       tonumber(colorArray[1]),
		                       tonumber(colorArray[2]),
		                       tonumber(colorArray[3])
	                          )
	end
end

function api.debug.showVirtualFrame(essential)
	local upOffset = vector3(0,0,0.1)
	local offset = api.virtualFrame.positionV3 + upOffset
	local length = 0.15
	api.debug.drawArrow("green",
		offset + vector3(-1 * length, 0, 0):rotate(api.virtualFrame.orientationQ),
		offset + vector3( 3 * length, 0, 0):rotate(api.virtualFrame.orientationQ),
		essential
	)
	api.debug.drawArrow("green",
		offset + vector3(0, -1 * length, 0):rotate(api.virtualFrame.orientationQ),
		offset + vector3(0,  2 * length, 0):rotate(api.virtualFrame.orientationQ),
		essential
	)
	api.debug.drawArrow("green",
		offset + vector3(0, 0, -1 * length):rotate(api.virtualFrame.orientationQ),
		offset + vector3(0, 0,  1 * length):rotate(api.virtualFrame.orientationQ),
		essential
	)

	api.debug.drawArrow("blue",
		upOffset + vector3(-1 * length, 0, 0),
		upOffset + vector3( 3 * length, 0, 0),
		essential
	)
	api.debug.drawArrow("blue",
		upOffset + vector3(0, -1 * length, 0),
		upOffset + vector3(0,  2 * length, 0),
		essential
	)
	api.debug.drawArrow("blue",
		upOffset + vector3(0, 0, -1 * length),
		upOffset + vector3(0, 0,  1 * length),
		essential
	)
end

function api.debug.showEstimateLocation(essential)
	api.debug.drawArrow(
		"red", 
			-vector3(api.estimateLocation.positionV3):rotate(
			quaternion(api.estimateLocation.orientationQ):inverse()
		), 
		vector3(0,0,0.1),
		essential
	)
end

function api.debug.showParent(vns)
	if vns.parentR ~= nil then
		local robotR = vns.parentR
		api.debug.drawArrow("blue", vector3(), api.virtualFrame.V3_VtoR(vector3(robotR.positionV3)), true)
		api.debug.drawArrow("blue", 
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1),
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1) +
			vector3(0.1, 0, 0):rotate(
				api.virtualFrame.Q_VtoR(quaternion(robotR.orientationQ))
			),
			true  -- essential
		)
	end
end

function api.debug.showChildren(vns, option)
	-- draw children location
	for i, robotR in pairs(vns.childrenRT) do
		api.debug.drawArrow(
			"blue",
			vector3(),
			api.virtualFrame.V3_VtoR(
				vector3(
					robotR.positionV3 * (
						(robotR.positionV3:length() - 0.2) / robotR.positionV3:length()
					)
				)
			),
			true
		)
		if option ~= nil and option.drawOrientation == true then
			api.debug.drawArrow("blue", 
				api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1),
				api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1) +
				vector3(0.1, 0, 0):rotate(
					api.virtualFrame.Q_VtoR(quaternion(robotR.orientationQ))
				),
				true
			)
		end
	end

	if vns.parentR == nil then
		api.debug.drawRing(
			"blue",
			vector3(0,0,0.08),
			0.15,
			true
		)
	end
end

function api.debug.showSeenRobots(vns, option)
	-- draw children location
	for i, robotR in pairs(vns.connector.seenRobots) do
		api.debug.drawArrow(
			"blue",
			vector3(),
			api.virtualFrame.V3_VtoR(robotR.positionV3),
			true
		)
		if option ~= nil and option.drawOrientation == true then
			api.debug.drawArrow("red", 
				api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1),
				api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1) +
				vector3(0.2, 0, 0):rotate(
					api.virtualFrame.Q_VtoR(quaternion(robotR.orientationQ))
				),
				true
			)
		end
	end
end

function api.debug.showObstacles(vns, essential)
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		api.debug.drawArrow("red", vector3(),
		                           api.virtualFrame.V3_VtoR(vector3(obstacle.positionV3)),
		                           essential
		                   )
		api.debug.drawArrow("red",
		                    api.virtualFrame.V3_VtoR(vector3(obstacle.positionV3)),
		                    api.virtualFrame.V3_VtoR(obstacle.positionV3 + vector3(0.1, 0, 0):rotate(obstacle.orientationQ)),
		                    essential
		                   )
		--obstacle.positionV3)
	end
end

-------------------------------------------------------------
function api.linkRobotInterface(VNS)
	VNS.Msg.sendTable = function(table)
		robot.radios.wifi.send(table)
	end

	VNS.Msg.getTablesAT = function(table)
		return robot.radios.wifi.recv
	end

	VNS.Msg.myIDS = function()
		return robot.id
	end

	VNS.Driver.move = api.move
	VNS.api = api
end

---- Step Function -------------------------------------------
-- 5 step functions :
-- init, reset, destroy, preStep, postStep
function api.init()
	--api.reset()
end

function api.reset()
	api.estimateLocation.positionV3 = vector3()
	api.estimateLocation.orientationQ = quaternion()
	api.virtualFrame.positionV3 = vector3()
	api.virtualFrame.orientationQ = quaternion()
end

function api.destroy()
end

function api.preStep()
	api.stepCount = api.stepCount + 1
	api.processTime()
end

function api.postStep()
	api.debug.showVirtualFrame()
end

------------------------------------------------------------
return api
