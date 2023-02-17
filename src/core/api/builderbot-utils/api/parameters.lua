-- register module with logger
robot.logger:register_module('api_parameters')

return {
    default_speed = tonumber(robot.params.default_speed or 0.020),
    default_turn_speed = tonumber(robot.params.default_turn_speed or 7),
    approach_block_speed = tonumber(robot.params.approach_block_speed or 0.01),
    approach_block_turn_speed = tonumber(robot.params.approach_block_turn_speed or 5),
    search_random_range = tonumber(robot.params.search_random_range or 25),
    aim_block_angle_tolerance = tonumber(robot.params.aim_block_angle_tolerance or 0.5),
    block_position_tolerance = tonumber(robot.params.block_position_tolerance or 0.001),
    proximity_touch_tolerance = tonumber(robot.params.proximity_touch_tolerance or 0.003),
    proximity_detect_tolerance = tonumber(robot.params.proximity_detect_tolerance or 0.03),
    proximity_maximum_distance = tonumber(robot.params.proximity_maximum_distance or 0.045),
    lift_system_rf_cover_threshold = tonumber(robot.params.lift_system_rf_cover_threshold or 0.06),
    lift_system_position_tolerance = tonumber(robot.params.lift_system_position_tolerance or 0.0015),
    obstacle_avoidance_backup = tonumber(robot.params.obstacle_avoidance_backup or 0.08),
    obstacle_avoidance_turn = tonumber(robot.params.obstacle_avoidance_turn or 60),
    z_approach_range_angle = tonumber(robot.params.z_approach_range_angle or 20),
    z_approach_range_distance = tonumber(robot.params.z_approach_range_distance or 0.27),
    z_approach_block_distance_increment = tonumber(robot.params.z_approach_block_distance_increment or 0.10),
    end_effector_overhang_length = tonumber(robot.params.end_effector_overhang_length or 0.005),
}

