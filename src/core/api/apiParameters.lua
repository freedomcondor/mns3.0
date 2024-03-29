local Parameters = {
	mode_2D = robot.params.mode_2D or "false",
	mode_builderbot = robot.params.mode_builderbot or "false",
	---- Drones ------------------------
	droneVelocityMode = robot.params.drone_velocity_mode or "false",
	droneRealNoise = robot.params.drone_real_noise or "false",
	droneTiltSensor = robot.params.drone_tilt_sensor or "false",
	report_sight_rounds = tonumber(robot.params.report_sight_rounds or 1),
	-- tag detection rate
	droneTagDetectionRate = tonumber(robot.params.drone_tag_detection_rate or 0.9),
	-- altitude control -------
	droneAltitudeBias = tonumber(robot.params.drone_altitude_bias or 0.2),
	droneAltitudeNoise = tonumber(robot.params.drone_altitude_noise or 0.1),
	droneDefaultHeight = tonumber(robot.params.drone_default_height or 1.5),
	droneDefaultStartHeight = tonumber(robot.params.drone_default_start_height or 1.5),
	droneFlightPreparationStateDuration = tonumber(robot.params.drone_flight_preparation_state_duration or 25),
	droneTakeOffKp = tonumber(robot.params.droneTakeOffKp or 0.4),

	---- Pipucks ------------------------
	pipuckWheelSpeedLimit = tonumber(robot.params.pipuck_wheel_speed_limit or 0.1),
	pipuckRotationScalar = tonumber(robot.params.pipuck_rotation_scalar or 0.3),

	---- Obstacles ------------------------
	obstacle_match_distance = tonumber(robot.params.obstacle_match_distance or 0.15),
	obstacle_unseen_count = tonumber(robot.params.obstacle_unseen_count or 3),
}

if Parameters.mode_2D == "true" then
	Parameters.mode_2D = true
else
	Parameters.mode_2D = false
end

if Parameters.droneVelocityMode == "true" then
	Parameters.droneVelocityMode = true
else
	Parameters.droneVelocityMode = false
end

if Parameters.mode_builderbot == "true" then
	Parameters.mode_builderbot = true
else
	Parameters.mode_builderbot = false
end

if Parameters.droneRealNoise == "true" then
	Parameters.droneRealNoise = true
	if Parameters.mode_2D ~= true then
		print("[Warning] droneRealNoise is true and mode 2D is false")
	end
else
	Parameters.droneRealNoise = false
end

if Parameters.droneTiltSensor== "true" then
	Parameters.droneTiltSensor = true
else
	Parameters.droneTiltSensor = false
end

return Parameters
