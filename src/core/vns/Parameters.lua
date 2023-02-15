return {
	connector_pipuck_children_max_count = tonumber(robot.params.connector_pipuck_children_max_count or 0),
	connector_drone_children_max_count = tonumber(robot.params.connector_drone_children_max_count or 0),

	-- safe zone and danger zone-----------------------------------
	-- recruit happens only if robots in the safezone
	-- robots wait if neighbours outside the safezone
	safezone_default = tonumber(robot.params.safezone_default or 1.00), -- for unknown robot type
	safezone_drone_drone = tonumber(robot.params.safezone_drone_drone or 1.70),
	safezone_drone_pipuck = tonumber(robot.params.safezone_drone_pipuck or 1.10),
	safezone_pipuck_pipuck = tonumber(robot.params.safezone_pipuck_pipuck or 1.00),

	-- robots avoid each other within dangerzone
	dangerzone_drone = tonumber(robot.params.dangerzone_drone or 1.50),
	dangerzone_pipuck = tonumber(robot.params.dangerzone_pipuck or 0.40),
	dangerzone_block = tonumber(robot.params.dangerzone_block or 0.40),
	dangerzone_predator = tonumber(robot.params.dangerzone_predator or 0.50),

	deadzone_pipuck = tonumber(robot.params.deadzone_pipuck or 0.10),
	deadzone_drone = tonumber(robot.params.deadzone_pipuck or 0),
	deadzone_block = tonumber(robot.params.deadzone_pipuck or 0),

	dangerzone_reference_pipuck_scalar = tonumber(robot.params.dangerzone_reference_pipuck_scalar or 1),
	deadzone_reference_pipuck_scalar = tonumber(robot.params.deadzone_reference_pipuck_scalar or 1),

	reference_count_down = tonumber(robot.params.reference_count_down or 1),
	-- avoid speed
	--[[
	        |   |
	        |   |
	speed   |    |  -log(d/dangerzone) * scalar
	        |     |
	        |      \  
	        |       -\
	        |         --\ 
	        |            ---\ 
	        |---------------+------------------------ d
	                        |
	                    dangerzone
	        |  ||
	        |  ||
	speed   |  | |  -log(d/dangerzone) * scalar
	        |  |  |
	        |  |   \  
	        |  |    -\
	        |  |      --\ 
	        |------------+------------------------
	           |         |
	        deadzone   dangerzone
	--]]
	avoid_speed_scalar = tonumber(robot.params.avoid_speed_scalar or 0.5),
	avoid_drone_vortex = robot.params.avoid_drone_vortex or "goal",
	avoid_pipuck_vortex = robot.params.avoid_pipuck_vortex or "goal",
	avoid_block_vortex = robot.params.avoid_block_vortex or "goal",

	-- driver --------------------------------------------------------
	--[[
	        |          slowdown            
	        |              /----------- default_speed
	speed   |             /
	        |            /
	        |       stop/ 
	        |-----------------------------------
	                      distance
	--]]
	driver_default_speed = tonumber(robot.params.driver_default_speed or 0.10),
	driver_slowdown_zone = tonumber(robot.params.driver_slowdown_zone or 0.10),
	driver_stop_zone = tonumber(robot.params.driver_stop_zone or 0.01),
	driver_default_rotate_scalar = tonumber(robot.params.driver_default_rotate_scalar or 0.5),
	driver_spring_default_speed_scalar = tonumber(robot.params.driver_spring_default_speed_scalar or 2),

	-- time out
	connector_waiting_count = tonumber(robot.params.connector_waiting_count or 7),
		-- robots wait this waiting_count steps for ack after recruiting a robot
	connector_waiting_parent_count = tonumber(robot.params.connector_waiting_parent_count or 10),
		-- robots wait this waiting_parent_count steps for a parent recuit again
	connector_unseen_count = tonumber(robot.params.connector_unseen_count or 7),
		-- robots disconnect after this steps after losing visual of a robot
	connector_heartbeat_count = tonumber(robot.params.connector_heartbeat_count or 3),
		-- robots disconnect after this steps after stop receiving hearbeat from a neighbour (parent + children)

	brainkeeper_time = tonumber(robot.params.brainkeeper_time or 100), 

	stabilizer_preference_robot = robot.params.stabilizer_preference_robot,
	stabilizer_preference_brain = robot.params.stabilizer_preference_brain,
	stabilizer_preference_brain_time = tonumber(robot.params.stabilizer_preference_brain_time or 150),

}
