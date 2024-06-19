DroneRealistSimulator = {}
-- doesn't support 3D mode yet

-- drone altitude noise
function DroneRealistSimulator.init(api)
	DroneRealistSimulator.altitude_bias = {
		biasScalar = robot.random.uniform(1 - api.parameters.droneAltitudeBias, 1 + api.parameters.droneAltitudeBias),
	}
end

function DroneRealistSimulator.changeSensors(api)
	if robot.params.simulation ~= true then return end
	DroneRealistSimulator.changeZSensor(api)
	DroneRealistSimulator.changeTagSensor(api)
end

function DroneRealistSimulator.changeActuators(api)
	if robot.params.simulation ~= true then return end
	DroneRealistSimulator.changeZActuator(api)
	DroneRealistSimulator.changeRadActuator(api)
end

function DroneRealistSimulator.changeZSensor(api)
	robot.flight_system.position.z = robot.flight_system.position.z * DroneRealistSimulator.altitude_bias.biasScalar
	robot.flight_system.position.z = robot.flight_system.position.z + robot.random.uniform(
		-api.parameters.droneAltitudeNoise,
		api.parameters.droneAltitudeNoise
	)
end

function DroneRealistSimulator.changeZActuator(api)
	-- check drone take off state
	if api.actuator.flight_preparation.state == "pre_flight" or
	   api.actuator.flight_preparation.state == "armed" then
		api.actuator.newPosition.z = 0
		api.actuator.newPosition.z = 0
	elseif api.actuator.flight_preparation.state == "take_off" or
	       api.actuator.flight_preparation.state == "navigation" then

		api.actuator.newPosition.z = api.actuator.newPosition.z / DroneRealistSimulator.altitude_bias.biasScalar
		api.actuator.newPosition.z = api.actuator.newPosition.z + robot.random.uniform(
			-api.parameters.droneAltitudeNoise,
			api.parameters.droneAltitudeNoise
		)
	end
end

function DroneRealistSimulator.changeRadActuator(api)
	-- mimic drone random rotate in hardware
	if api.actuator.flight_preparation.state == "take_off" and
	   api.actuator.flight_preparation.state_count == api.actuator.flight_preparation.state_duration then
		api.actuator.newRad = robot.random.uniform() * math.pi * 2
	end
end

function DroneRealistSimulator.changeTagSensor(api)
	for _, camera in pairs(robot.cameras_system) do
		local i = 1
		while i <= #camera.tags do
			local error = api.parameters.droneTagDetectionError
			local X = (robot.random.uniform() - 0.5) * 2 * error
			local Y = (robot.random.uniform() - 0.5) * 2 * error
			local Z = (robot.random.uniform() - 0.5) * 2 * error

			camera.tags[i].position = camera.tags[i].position + vector3(X, Y, Z)
			local random = robot.random.uniform()
			if random > api.parameters.droneTagDetectionRate then
				camera.tags[i] = camera.tags[#camera.tags]
				camera.tags[#camera.tags] = nil
				i = i - 1
			end
			i = i + 1
		end
	end
end


