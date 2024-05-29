createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

params = '''
    mode_2D="true"
    mode_builderbot="true"

    stabilizer_preference_brain="pipuck5"

    pipuck_label="1, 10"
    builderbot_label="11,11"
    block_label="34,34"

    connector_waiting_count="5"
    connector_waiting_parent_count="10"
    connector_unseen_count="10"
    connector_heartbeat_count="8"

    dangerzone_pipuck="0.1"
'''

drone_params = '''
    script="drone.lua"
'''

pipuck_params = '''
    script="pipuck.lua"
'''

builderbot_params = '''
    script="builderbot.lua"
'''

# generate argos file
generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/drone_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/hw_code/01_hw_drone.argos",
	[
		["PARAMS",       "driver_default_speed=\"0.03\"\n" + drone_params + params],
	]
)

generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/pipuck_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/hw_code/02_hw_pipuck.argos",
	[
		["PARAMS",       pipuck_params + params],
	]
)

generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/builderbot_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/hw_code/03_hw_builderbot.argos",
	[
		["PARAMS",       builderbot_params + params],
	]
)