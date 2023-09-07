createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

params = '''
    mode_2D="true"

    stabilizer_preference_robot="pipuck1"
    stabilizer_preference_brain="drone4"

    connector_waiting_count="5"
    connector_waiting_parent_count="8"
    connector_unseen_count="20"
    connector_heartbeat_count="10"

    obstacle_label="0, 200"

    obstacle_match_distance="0.30"
    obstacle_unseen_count="10"

    safezone_drone_drone="10.0"
    dangerzone_drone="1.8"
    deadzone_drone="1.3"

    driver_arrive_zone="0.5"
'''

drone_params = '''
    script="drone.lua"
'''

# generate argos file
generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/drone_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/code/01_hw_drone.argos",
	[
		["PARAMS",       "driver_default_speed=\"0.03\"\n" + drone_params + params],
	]
)