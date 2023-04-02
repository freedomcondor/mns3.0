--[[
--	drone api
--]]
logger.register("droneAPI")
logger.disable("droneAPI")

local api = require("commonAPI")
if robot.params.simulation == true then local DroneRealistSimulator = require("droneRealistSimulator") end
local Transform = require("Transform")

---- actuator --------------------------
-- Idealy, I would like to use robot.flight_system.set_targets only once per step
-- newPosition and newRad are recorded, and enforced at last in dronePostStep
api.actuator = {}
if robot.flight_system ~= nil then
	api.actuator.newPosition = robot.flight_system.position
	api.actuator.newRad = robot.flight_system.orientation.z
else
	api.actuator.newPosition = vector3()
	api.actuator.newRad = 0
end
function api.actuator.setNewLocation(locationV3, rad)
	api.actuator.newPosition = locationV3
	api.actuator.newRad = rad
end

-- drone flight preparation sequence
---- take off preparation -------------------
api.actuator.flight_preparation = {
	state = "pre_flight",
	state_duration = 25,
	state_count = 0,
}

api.actuator.flight_preparation.run_state_velocity_control_mode = function()
	if robot.flight_system ~= nil and robot.flight_system.ready() then
		-- flight preparation state machine
		if api.actuator.flight_preparation.state == "pre_flight" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = 0
			api.actuator.newRad = 0

			api.actuator.flight_preparation.state_count =
				api.actuator.flight_preparation.state_count + 1
			if api.actuator.flight_preparation.state_count >= api.actuator.flight_preparation.state_duration then
				api.actuator.flight_preparation.state_count = 0
				api.actuator.flight_preparation.state = "armed"
			end
		elseif api.actuator.flight_preparation.state == "armed" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = 0
			api.actuator.newRad = 0

			robot.flight_system.set_armed(true, false)
			robot.flight_system.set_offboard_mode(true)
			api.actuator.flight_preparation.state = "take_off"
			api.actuator.flight_preparation.state_count = 0
		elseif api.actuator.flight_preparation.state == "take_off" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			if robot.flight_system.position.z < api.parameters.droneDefaultStartHeight then
				api.actuator.newPosition.z = (api.parameters.droneDefaultStartHeight - robot.flight_system.position.z) / 5;
			else
				api.actuator.newPosition.z = 0
			end
			api.actuator.newRad = 0

			api.actuator.flight_preparation.state_count =
				api.actuator.flight_preparation.state_count + 1
			if api.actuator.flight_preparation.state_count >= api.actuator.flight_preparation.state_duration * 2 then
				api.actuator.flight_preparation.state_count = 0
				api.actuator.flight_preparation.state = "navigation"
			end
		elseif api.actuator.flight_preparation.state == "navigation" then
			-- TODO: there may be a jump after navigation mode
			--do nothing
		end
	end
end

api.actuator.flight_preparation.run_state_waypoint_control_mode = function()
	if robot.flight_system ~= nil and robot.flight_system.ready() then
		-- flight preparation state machine
		if api.actuator.flight_preparation.state == "pre_flight" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = api.parameters.droneDefaultStartHeight
			api.actuator.newRad = 0

			api.actuator.flight_preparation.state_count =
				api.actuator.flight_preparation.state_count + 1
			if api.actuator.flight_preparation.state_count >= api.actuator.flight_preparation.state_duration then
				api.actuator.flight_preparation.state_count = 0
				api.actuator.flight_preparation.state = "armed"
			end
		elseif api.actuator.flight_preparation.state == "armed" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = api.parameters.droneDefaultStartHeight
			api.actuator.newRad = 0

			robot.flight_system.set_armed(true, false)
			robot.flight_system.set_offboard_mode(true)
			api.actuator.flight_preparation.state = "take_off"
			api.actuator.flight_preparation.state_count = 0
		elseif api.actuator.flight_preparation.state == "take_off" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = api.parameters.droneDefaultStartHeight
			api.actuator.newRad = 0

			api.actuator.flight_preparation.state_count =
				api.actuator.flight_preparation.state_count + 1
			if api.actuator.flight_preparation.state_count >= api.actuator.flight_preparation.state_duration * 2 then
				api.actuator.flight_preparation.state_count = 0
				api.actuator.flight_preparation.state = "navigation"
			end
		elseif api.actuator.flight_preparation.state == "navigation" then
			-- TODO: there may be a jump after navigation mode
			--do nothing
		end
	end
end

if api.parameters.droneVelocityControlMode == true then
	api.actuator.flight_preparation.run_state = api.actuator.flight_preparation.run_state_velocity_control_mode
else
	api.actuator.flight_preparation.run_state = api.actuator.flight_preparation.run_state_waypoint_control_mode
end

---- Virtual Frame and tilt ---------------------
--api.virtualFrame.orientationQ = quaternion(math.pi/4, vector3(0,0,1))
api.virtualFrame.orientationQ = quaternion()
api.virtualFrame.logicOrientationQ = api.virtualFrame.orientationQ
-- overwrite rotateInspeed to change logicOrientationQ
function api.virtualFrame.rotateInSpeed(_speedV3)
	-- speedV3 in virtual frame
	local speedV3 = vector3(_speedV3)
	if api.parameters.mode_2D == true then speedV3.x = 0; speedV3.y = 0 end
	local axis = vector3(speedV3):normalize()
	if speedV3:length() == 0 then axis = vector3(0,0,1) end
	api.virtualFrame.logicOrientationQ =
		api.virtualFrame.logicOrientationQ *
		quaternion(speedV3:length() * api.time.period, axis)
end

function api.droneTiltVirtualFrame()
	local tilt
	if robot.flight_system ~= nil and api.parameters.droneTiltSensor == true then
		tilt = (quaternion(robot.flight_system.orientation.x, vector3(1,0,0)) *
		        quaternion(robot.flight_system.orientation.y, vector3(0,1,0))):inverse()
	else
		tilt = quaternion()
	end
	api.virtualFrame.tiltQ = tilt
	api.virtualFrame.orientationQ = tilt * api.virtualFrame.logicOrientationQ
	api.virtualFrame.positionV3 = api.virtualFrame.positionV3:rotate(tilt)
end

---- overwrite Step Function ---------------------
-- 5 step functions :
-- init, reset, destroy, preStep, postStep
api.commonInit = api.init
function api.init()
	api.commonInit()
	if robot.params.simulation == true and api.parameters.droneRealNoise == true then
		DroneRealistSimulator.init(api)
	end
	api.droneEnableCameras()
end

api.commonDestroy = api.destroy
function api.destroy()
	api.droneDisableCameras()
	api.commonDestroy()
end

api.commonPreStep = api.preStep
function api.preStep()
	if robot.flight_system ~= nil then logger("droneAPI: position sensor = ", robot.flight_system.position, robot.flight_system.orientation) end
	api.commonPreStep()
	api.droneTags = nil
	if robot.params.simulation == true and api.parameters.droneRealNoise == true then
		DroneRealistSimulator.changeSensors(api)
		if robot.flight_system ~= nil then
			logger("droneAPI: after real sim  = ", robot.flight_system.position, robot.flight_system.orientation)
		end
	end
	api.droneTiltVirtualFrame()
end

api.commonPostStep = api.postStep
function api.postStep()
	if robot.flight_system ~= nil then
		if api.parameters.mode_2D == true then api.droneAdjustHeight(api.parameters.droneDefaultHeight) end
		api.actuator.flight_preparation.run_state()
		logger("droneAPI: set_target_pose = ", api.actuator.newPosition, api.actuator.newRad)
		if robot.params.simulation == true and api.parameters.droneRealNoise == true then
			DroneRealistSimulator.changeActuators(api)
			logger("droneAPI: after real simu = ", api.actuator.newPosition, api.actuator.newRad)
		end
		robot.flight_system.set_target_pose(api.actuator.newPosition, api.actuator.newRad)
		api.updateLastSpeed()
	end
	api.commonPostStep()
end

---- Height control --------------------
api.droneCheckHeightCountDown = api.actuator.flight_preparation.state_duration * 3
api.droneLastHeight = api.parameters.droneDefaultStartHeight

function api.droneAdjustHeight(z)
	--[[
	if api.droneCheckHeightCountDown > 0 then
		api.actuator.newPosition.z = api.droneLastHeight
		api.droneCheckHeightCountDown = api.droneCheckHeightCountDown - 1
	elseif api.droneCheckHeightCountDown <= 0 then
	--]]
	if true then
		local currentHeight = api.droneEstimateHeight()
		logger("checking height, current height = ", currentHeight)
		if currentHeight == nil then
			api.actuator.newPosition.z = api.droneLastHeight
			if z == 0 then
				local threshold = 0
				if robot.params.hardware == true then threshold = -1 end
				if api.actuator.newPosition.z > threshold then
					api.actuator.newPosition.z =
						api.actuator.newPosition.z - 0.02 * api.time.period
				end
				api.droneLastHeight = api.actuator.newPosition.z
			end
			return
		end
		local heightError = z - currentHeight
		local speed_limit = 0.3
		if heightError > speed_limit then heightError = speed_limit end
		if heightError < -speed_limit then heightError = -speed_limit end
		local ZScalar = 5
		if robot.params.hardware == true then ZScalar = 3 end
		-- TODO: there may be a jump here
		api.actuator.newPosition.z = robot.flight_system.position.z + heightError * api.time.period * ZScalar
		logger("heightError = ", heightError)
		logger("robot.flight_system.position.z = ", robot.flight_system.position.z)
		logger("api.actuator.newPosition.z = ", api.actuator.newPosition.z)
		api.droneLastHeight = api.actuator.newPosition.z
		if math.abs(heightError) < 0.1 then
			api.droneCheckHeightCountDown = api.actuator.flight_preparation.state_duration * 3
		end
	end
end

function api.droneEstimateHeight()
	-- estimate height
	local average_height = 0
	local average_count = 0
	local tags = api.droneDetectTags()
	for _, tag in ipairs(tags) do
		-- tag see me
		local tagSeeMe = Transform.AxCis0(tag)

		average_height = average_height + tagSeeMe.positionV3.z
		average_count = average_count + 1
	end

	if average_count ~= 0 then
		average_height = average_height / average_count
		return average_height
	else
		return nil
	end
end

---- speed control --------------------
-- everything in robot hardware's coordinate frame
-- Speed maybe set multiple times in a step, remember it in justSetSpeed, and push to lastSetSpeed in postStep
function api.rememberLastSpeed(x,y,z,th)
	api.actuator.justSetSpeed = {
		x = x, y = y, z = z, th = th,
	}
end

function api.updateLastSpeed()
	if api.actuator.justSetSpeed == nil then
		api.rememberLastSpeed(0,0,0,0)
	end

	api.actuator.lastSetSpeed = {
		x = api.actuator.justSetSpeed.x,
		y = api.actuator.justSetSpeed.y,
		z = api.actuator.justSetSpeed.z,
		th = api.actuator.justSetSpeed.th,
	}
end

function api.droneSetSpeed_velocity_control_mode(x, y, z, th)
	api.actuator.setNewLocation(vector3(x, y, z), th)
end

function api.droneSetSpeed_waypoint_control_mode(x, y, z, th)
	logger("droneSetSpeed = ", x, y, z, th)
	if robot.flight_system == nil then return end
	-- x, y, z in m/s, x front, z up, y left
	-- th in rad/s, counter-clockwise positive
	local rad = robot.flight_system.orientation.z
	local q = quaternion(rad, vector3(0,0,1))

	api.rememberLastSpeed(x, y, z, th)

	if api.actuator.lastSetSpeed ~= nil then
		logger(" last speed = ", api.actuator.lastSetSpeed.x,
		                         api.actuator.lastSetSpeed.y,
		                         api.actuator.lastSetSpeed.z,
		                         api.actuator.lastSetSpeed.th)
		x = (x + api.actuator.lastSetSpeed.x) / 2
		y = (y + api.actuator.lastSetSpeed.y) / 2
		z = (z + api.actuator.lastSetSpeed.z) / 2
		th = (th + api.actuator.lastSetSpeed.th) / 2
	end

	-- tune these scalars to make x,y,z,th match m/s and rad/s
		-- 6 and 0.5 are roughly calibrated for simulation
	local transScalar = 4
	local transScalarZ = 4
	local rotateScalar = 0.5
	if robot.params.hardware == true then
		transScalar = 10
		transScalarZ = 5
		rotateScalar = 0.1
	end

	x = x * transScalar * api.time.period
	y = y * transScalar * api.time.period
	z = z * transScalarZ * api.time.period
	th = th * rotateScalar * api.time.period

	logger("time = ", api.time.period)
	logger("inc = ", x, y, z, th)

	api.actuator.setNewLocation(
		vector3(x,y,z):rotate(q) + robot.flight_system.position,
		rad + th
		-- TODO: check when rad > pi
	)
end

if api.parameters.droneVelocityControlMode == true then
	api.droneSetSpeed = api.droneSetSpeed_velocity_control_mode
else
	api.droneSetSpeed = api.droneSetSpeed_waypoint_control_mode
end

api.setSpeed = api.droneSetSpeed
--api.move is implemented in commonAPI

api.commonMove = api.move
function api.move(transV3, rotateV3)
	api.commonMove(transV3, rotateV3)
	if api.actuator.flight_preparation.state ~= "navigation" then
		api.estimateLocation.positionV3 = vector3()
		api.estimateLocation.orientationQ = quaternion()
		api.estimateLocationInRealFrame.positionV3 = vector3()
		api.estimateLocationInRealFrame.orientationQ = quaternion()
	end
end

---- Cameras -------------------------
function api.droneEnableCameras()
	for index, camera in pairs(robot.cameras_system) do
		camera.enable()
	end
end

function api.droneDisableCameras()
	for index, camera in pairs(robot.cameras_system) do
		camera.disable()
	end
end

function api.droneDetectLeds()
	-- detect led is depricated by argos-srocs and resume in the future.
	for _, camera in pairs(robot.cameras_system) do
		if camera.detect_led == nil then return end
	end

	-- takes tags in camera_frame_reference
	local led_dis = 0.02 -- distance between leds to the center
	local led_loc_for_tag = {
	vector3(led_dis, 0, 0),
	vector3(0, led_dis, 0),
	vector3(-led_dis, 0, 0),
	vector3(0, -led_dis, 0)
	} -- start from x+ , counter-closewise

	for _, camera in pairs(robot.cameras_system) do
		for _, tag in ipairs(camera.tags) do
			tag.type = 0
			for j, led_loc in ipairs(led_loc_for_tag) do
				local led_loc_for_camera = vector3(led_loc):rotate(tag.orientation) + tag.position
				local color_number = camera.detect_led(led_loc_for_camera)
				if color_number ~= tag.type and color_number ~= 0 then
					tag.type = color_number
				end
			end
		end
	end
end


function api.droneDetectTags(option)
	if option == nil then option = {} end
	-- droneDetectTags maybe called multiple times by dronePreconnector and adjustheight in postStep
	if api.droneTags ~= nil then return api.droneTags end
	-- This function returns a tags table, in real robot coordinate frame
	api.droneDetectLeds()

	-- add tags
	tags = {}
	for _, camera in pairs(robot.cameras_system) do
		for _, newTag in ipairs(camera.tags) do
			local positionV3 =
			  (
			    camera.transform.position +
			    vector3(newTag.position):rotate(camera.transform.orientation)
			  )

			local orientationQ =
				camera.transform.orientation *
				newTag.orientation * quaternion(math.pi, vector3(1,0,0))

			-- check existed
			local flag = 0
			for i, existTag in ipairs(tags) do
				if (existTag.positionV3 - positionV3):length() < api.parameters.obstacle_match_distance and
				   existTag.id == newTag.id then
					flag = 1
					break
				end
			end

			-- check orientation Z up
			if option.check_vertical == true and
			   (vector3(0,0,1):rotate(orientationQ) - vector3(0,0,1)):length() > 0.3 then
				logger("bad tag orientation, ignore tag", newTag.id)
				logger("                     positionV3", positionV3)
				logger("                     orientationQ", orientationQ)
				logger("                             X = ", vector3(1,0,0):rotate(orientationQ))
				logger("                             Y = ", vector3(0,1,0):rotate(orientationQ))
				logger("                             Z = ", vector3(0,0,1):rotate(orientationQ))
				flag = 1
			end

			if flag == 0 then
				tags[#tags + 1] = {
					id = newTag.id,
					type = newTag.type,
					positionV3 = positionV3,
					orientationQ = orientationQ
				}
			end
		end
	end

	api.droneTags = tags
	return tags
end

api.tagLabelIndex = {
	pipuck = {},
	builderbot = {},
	drone = {},

	block = {},
	obstacle = {},
}

local from, to = (robot.params.obstacle_label or "0,0"):match("([^,]+),([^,]+)")
api.tagLabelIndex.obstacle.from = tonumber(from)
api.tagLabelIndex.obstacle.to   = tonumber(to)

local from, to = (robot.params.block_label or "-1,-1"):match("([^,]+),([^,]+)")
api.tagLabelIndex.block.from = tonumber(from)
api.tagLabelIndex.block.to   = tonumber(to)

local from, to = (robot.params.pipuck_label or "-1,-1"):match("([^,]+),([^,]+)")
api.tagLabelIndex.pipuck.from = tonumber(from)
api.tagLabelIndex.pipuck.to   = tonumber(to)

local from, to = (robot.params.drone_label or "-1,-1"):match("([^,]+),([^,]+)")
api.tagLabelIndex.drone.from = tonumber(from)
api.tagLabelIndex.drone.to   = tonumber(to)

local from, to = (robot.params.builderbot_label or "-1,-1"):match("([^,]+),([^,]+)")
api.tagLabelIndex.builderbot.from = tonumber(from)
api.tagLabelIndex.builderbot.to   = tonumber(to)

tagOffset = {
	pipuck = vector3(0, 0, 0.0685),
	drone = vector3(0, 0, 0.25),   -- 0.285 for candidate
	builderbot = vector3(0, 0, 0.3875),
	block = vector3(0, 0, 0.028),
}

function api.droneAddSeenRobots(tags, seenRobotsInRealFrame)
	-- this function adds robots (in real frame) from seen tags (in real robot frames)
	for i, tag in ipairs(tags) do
		local robotTypeS = nil
		for typeS, index in pairs(api.tagLabelIndex) do
			if index.from <= tag.id and tag.id <= index.to then
				robotTypeS = typeS
				break
			end
		end
		if robotTypeS == nil then robotTypeS = "unknown" end

		if robotTypeS ~= "unknown" and robotTypeS ~= "block" and robotTypeS ~= "obstacle" then
			local idS = robotTypeS .. math.floor(tag.id)
			seenRobotsInRealFrame[idS] = {
				idS = idS,
				robotTypeS = robotTypeS,
				positionV3 = tag.positionV3 + (-tagOffset[robotTypeS]):rotate(tag.orientationQ),
				orientationQ = tag.orientationQ,
			}
		end
	end
end

function api.droneAddObstacles(tags, obstaclesInRealFrame) -- tags is an array of R
	for i, tag in ipairs(tags) do
		if api.tagLabelIndex.obstacle.from <= tag.id and
		   api.tagLabelIndex.obstacle.to >= tag.id then
			obstaclesInRealFrame[#obstaclesInRealFrame + 1] = {
				type = tag.id,
				robotTypeS = "obstacle",
				positionV3 = tag.positionV3 + vector3(0,0,-0.1):rotate(tag.orientationQ),
				orientationQ = tag.orientationQ,
			}
		end
	end
end

function api.droneAddBlocks(tags, blocksInRealFrame) -- tags is an array of R
	for i, tag in ipairs(tags) do
		if api.tagLabelIndex.block.from <= tag.id and
		   api.tagLabelIndex.block.to >= tag.id then
			blocksInRealFrame[#blocksInRealFrame + 1] = {
				type = tag.id,
				robotTypeS = "block",
				positionV3 = tag.positionV3 + vector3(0,0,-0.1):rotate(tag.orientationQ),
				orientationQ = tag.orientationQ,
			}
		end
	end
end

return api
