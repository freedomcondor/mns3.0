createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

parameters = {
    "drone_tag_detection_pixel_orientation" : "true",
    "mode_2D"            :  "true",
    "mode_builderbot"    :  "true",
    "pipuck_label"       :  "1, 10",
    "builderbot_label"   :  "11, 15",
    "block_label"        :  "30, 34",

    "avoid_block_vortex"   :  "nil",
    "avoid_speed_scalar"   :  0.20,
    "driver_slowdown_zone" :  0.15,
    "driver_stop_zone"     :  0.03,
    "driver_default_speed" : 0.03,

    "dangerzone_pipuck"  :  0.20,
    "dangerzone_block"   :  0.20,

    "center_block_type"  :  32,
    "usual_block_type"   :  34,
    "pickup_block_type"  :  33,

    "connector_waiting_count"          : 5,
    "connector_waiting_parent_count"   : 10,
    "connector_unseen_count"           : 10,
    "connector_heartbeat_count"        : 8,

    "pipuck_wheel_speed_limit"   :  0.10,

    "special_pipuck"    :  "pipuck4",
}

#    "pipuck_rotation_scalar"     :  0.2,

parameters_txt = generateParametersText(parameters)

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
		["PARAMS",       drone_params + parameters_txt],
	]
)

generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/pipuck_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/hw_code/02_hw_pipuck.argos",
	[
		["PARAMS",       pipuck_params + parameters_txt],
	]
)

generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/builderbot_hw.argos",
                    "@CMAKE_CURRENT_BINARY_DIR@/hw_code/03_hw_builderbot.argos",
	[
		["PARAMS",       builderbot_params + parameters_txt],
	]
)