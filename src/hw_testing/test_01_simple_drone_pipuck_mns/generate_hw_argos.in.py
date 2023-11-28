createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

params = '''
    mode_2D="true"

    stabilizer_preference_robot="pipuck1"
    stabilizer_preference_brain="drone1"

    connector_waiting_count="5"
    connector_waiting_parent_count="8"
    connector_unseen_count="20"
    connector_heartbeat_count="10"

    pipuck_label="1, 20"

    obstacle_match_distance="0.30"
    obstacle_unseen_count="10"

    safezone_drone_drone="3.0"
    safezone_drone_pipuck="1.5"
    dangerzone_pipuck="0.35"
    dangerzone_block="0.35"
    dangerzone_drone="2.0"
    deadzone_drone="1.0"

    pipuck_wheel_speed_limit="0.15"
    pipuck_rotation_scalar="0.25"
'''

drone_params = '''
    script="drone.lua"
'''

pipuck_params = '''
    script="pipuck.lua"
'''

# generate argos file
generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/drone_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/code/01_hw_drone.argos",
	[
		["PARAMS",       "driver_default_speed=\"0.03\"\n" + drone_params + params],
	]
)

generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/pipuck_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/code/02_hw_pipuck.argos",
	[
		["PARAMS",       pipuck_params + params],
	]
)