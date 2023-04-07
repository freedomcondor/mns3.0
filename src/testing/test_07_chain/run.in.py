createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

def generate_drone_xml_3D(i, x, y, z, th = 0) :
    tag = '''
    <drone id="drone{}" wifi_medium="wifi" >
        <body position="{},{},{}" orientation="{},0,0"/>
        <controller config="drone"/>
    </drone>
    '''.format(i, x, y, z, th)
    return tag

def generate_drones_3D(locations, start_id) :
    # take locations [ [x,y,z], [x,y,z], ... ]
    tagstr = ""
    i = start_id
    for loc in locations :
        tagstr = tagstr + generate_drone_xml_3D(i, loc[0], loc[1], loc[2])
        i = i + 1
    return tagstr

n = 30
dis = 2
drone_locations = []
for i in range(0, n) :
    drone_locations.append([0, 0, (n - i) * dis])

drone_xml = generate_drones_3D(drone_locations, 1)                 # from label 1 generate drone xml tags

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    drone_label="1, 100"

    drone_default_start_height="3.0"
    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.05"
    droneN={}
    disL={}

    drone_velocity_mode="true"
'''.format(n, dis)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos",
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["DRONES",            drone_xml],
        #["OBSTACLES",         obstacle_xml],
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters, {"show_tag_rays":False, "show_frustum":False, "velocity_mode":True, "ideal_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
