import random
import sys
import getopt
import time
import math

#----------------------------------------------------------------------------------------------
# usage message 
usage="[usage] example: python3 xxx.py -r 1 -l 1000 -v true -m 10"

#----------------------------------------------------------------------------------------------
# parse opts
if "customizeOpts" not in locals() or customizeOpts != True :
    try:
        optlist, args = getopt.getopt(sys.argv[1:], "r:l:v:m:h")
    except:
        print("[error] unexpected opts")
        print(usage)
        sys.exit(0)

Inputseed = None
MultiThreads = None
Experiment_length = None
Visualization = True
VisualizationArgosFlag = ""

if "customizeOpts" not in locals() or customizeOpts != True :
    for opt, value in optlist:
        if opt == "-r":
            Inputseed = int(value)
            print("Inputseed provided:", Inputseed)
        elif opt == "-l":
            Experiment_length = int(value)
            print("experiment_length provided:", Experiment_length)
        elif opt == "-v":
            if value == "False" or value == "false" :
                Visualization = False
            print("visualization provided:", Visualization)
        elif opt == "-m":
            MultiThreads = int(value) 
            print("Multi threads provided:", MultiThreads)
        elif opt == "-h":
            print(usage)
            exit()

if Inputseed == None :
    Inputseed = int(time.time())
    print("Inputseed not provided, using:", Inputseed)

if MultiThreads == None :
    MultiThreads = 0
    print("MultiThreads not provided, using:", MultiThreads)

if Visualization == False :
    VisualizationArgosFlag = " -z"

#######################################################################
# random seed
random.seed(Inputseed)

#######################################################################
# Controller
def generate_drone_controller(params, option={}) :
    show_tag_rays = "false"
    show_frustum = "false"
    ideal_mode ="false"
    velocity_mode ="false"

    if "show_tag_rays" in option and option["show_tag_rays"] == True :
        show_tag_rays = "true"
    if "show_frustum" in option and option["show_frustum"] == True :
        show_frustum = "true"
    if "ideal_mode" in option and option["ideal_mode"] == True :
        ideal_mode = "true"
    if "velocity_mode" in option and option["velocity_mode"] == True :
        velocity_mode = "true"

    text = '''
    <!-- Drone Controller -->
    <lua_controller id="drone">
      <actuators>
        <debug implementation="default" />
        <drone_flight_system implementation="default" ideal_mode="{}" velocity_mode="{}" />
        <drone_leds implementation="default" />
        <radios implementation="default" />
      </actuators>
      <sensors>
        <drone_system implementation="default" />
        <drone_cameras_system implementation="default" show_frustum="{}" show_tag_rays="{}" />
        <drone_flight_system implementation="default" />
        <radios implementation="default" />
      </sensors>
      <params simulation="true" {} />
    </lua_controller>
    '''.format(ideal_mode, velocity_mode, show_frustum, show_tag_rays, params)

    return text

def generate_pipuck_controller(params) :
    text = '''
    <!-- Pi-Puck Controller -->
    <lua_controller id="pipuck">
      <actuators>
        <pipuck_differential_drive implementation="default" />
        <pipuck_leds implementation="default" />
        <debug implementation="default" />
        <radios implementation="default" />
      </actuators>
      <sensors>
        <pipuck_system implementation="default" />
        <radios implementation="default" />
      </sensors>
      <params simulation="true" {} />
    </lua_controller>
    '''.format(params)

    return text

def generate_physics_media_loop_visualization(cmake_binary_dir, lua_editor=False, replay=False) :
    if lua_editor :
        lua_editor = "true"
    else :
        lua_editor = "false"
      
    loop_functions_lib = "libmy_extensions"
    loop_functions_label = "my_loop_functions"
    if replay == True:
        loop_functions_lib = "libreplay_loop_functions"
        loop_functions_label = "replay_loop_functions"

    text = '''
  <!-- ******************* -->
  <!-- * Physics engines * -->
  <!-- ******************* -->
  <physics_engines>
    <pointmass3d id="pm3d" iterations="10" />
    <dynamics3d id="dyn3d" iterations="25">
      <gravity g="9.8" />
      <floor />
    </dynamics3d>
  </physics_engines>

  <!-- ********* -->
  <!-- * Media * -->
  <!-- ********* -->
  <media>
    <directional_led id="directional_leds" index="grid" grid_size="20,20,20"/>
    <tag id="tags" index="grid" grid_size="20,20,20" />
    <radio id="wifi" index="grid" grid_size="20,20,20" />
  </media>

  <!-- ****************** -->
  <!-- * Loop functions * -->
  <!-- ****************** -->
  <loop_functions library="{}/{}"
                  label="{}" />

  <!-- ****************** -->
  <!-- * Visualization  * -->
  <!-- ****************** -->
  <visualization>
    <qt-opengl lua_editor="{}" show_boundary="false">
      <user_functions library="{}/libmy_qtopengl_extensions"
                      label="my_qtopengl_user_functions" />
      <camera>
        <placements>
          <placement index="0" position="0,-0.1,25" look_at="0,0,0" up="0,0,1" lens_focal_length="30" />
        </placements>
      </camera>
    </qt-opengl>
  </visualization>
    '''.format(cmake_binary_dir, loop_functions_lib, loop_functions_label, lua_editor, cmake_binary_dir)

    return text

#######################################################################
# real lab scenario
def generate_real_scenario_object() :
    if Visualization == False :
        return ""
    text = '''
    <!-- room -->
    <!--
    <box id="north_room" size="-2.02,14,3.00" movable="false" mass="10">
      <body position="5.1,0,0"  orientation="0,0,0" />
    </box>
    <box id="south_room" size="-2.02,14,3.00" movable="false" mass="10">
      <body position="-9.1,0,0"  orientation="0,0,0" />
    </box>
    -->

    <!-- furnitures -->
    <box id="furniture1" size="3.20,1.0,2.00" movable="false" mass="10">
      <body position="4, 4.90,0"  orientation="0,0,0" />
    </box>
    <box id="furniture2" size="3.20,1.0,2.00" movable="false" mass="10">
      <body position="4,-4.90,0"  orientation="0,0,0" />
    </box>
    <box id="furniture3" size="3.20,1.0,2.00" movable="false" mass="10">
      <body position="-1, 4.90,0"  orientation="0,0,0" />
    </box>
    <box id="furniture4" size="3.20,1.0,2.00" movable="false" mass="10">
      <body position="-1,-4.90,0"  orientation="0,0,0" />
    </box>
    <box id="furniture5" size="3.20,1.0,2.00" movable="false" mass="10">
      <body position="-6, 4.90,0"  orientation="0,0,0" />
    </box>
    <box id="furniture6" size="3.20,1.0,2.00" movable="false" mass="10">
      <body position="-6,-4.90,0"  orientation="0,0,0" />
    </box>

    <!-- truss -->
    <box id="south_truss" size="0.02,9.50,0.20" movable="false" mass="10">
      <body position="-6.26,0,2.5"  orientation="0,0,0" />
    </box>
    <box id="north_truss" size="0.02,9.50,0.20" movable="false" mass="10">
      <body position="6.26,0,2.5"  orientation="0,0,0" />
    </box>
    <box id="west_truss" size="12.5,0.02,0.20" movable="false" mass="10">
      <body position="0, 4.76, 2.5"  orientation="0,0,0" />
    </box>
    <box id="east_truss" size="12.5,0.02,0.20" movable="false" mass="10">
      <body position="0, -4.76, 2.5"  orientation="0,0,0" />
    </box>

    <!-- man -->
    <cylinder id="head" radius="0.1" height="0.2" movable="false" mass="10">
      <body position="-6, 3.5, 1.55"  orientation="0,0,0" />
    </cylinder>
    <box id="body" size="0.3, 0.5, 0.60" movable="false" mass="10">
      <body position="-6, 3.5, 0.95"  orientation="0,0,0" />
    </box>
    <cylinder id="leg1" radius="0.1" height="0.95" movable="false" mass="10">
      <body position="-6, 3.35, 0"  orientation="0,0,0" />
    </cylinder>
    <cylinder id="leg2" radius="0.1" height="0.95" movable="false" mass="10">
      <body position="-6, 3.65, 0"  orientation="0,0,0" />
    </cylinder>
    <cylinder id="arm1" radius="0.05" height="0.90" movable="false" mass="10">
      <body position="-6, 3.80, 0.65"  orientation="0,0,0" />
    </cylinder>
    <cylinder id="arm2" radius="0.05" height="0.90" movable="false" mass="10">
      <body position="-6, 3.2, 0.65"  orientation="0,0,0" />
    </cylinder>

    <!-- boundary markers -->
    <!--box id="marker1" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="1.2,-2.4,0"  orientation="0,0,0" />
    </box>
    <box id="marker2" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="2.0,-2.0,0"  orientation="0,0,0" />
    </box>
    <box id="marker3" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="3.4,-2.4,0"  orientation="0,0,0" />
    </box>
    <box id="marker4" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="5.0,-1.1,0"  orientation="0,0,0" />
    </box>
    <box id="marker5" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="4.7,1.3,0"  orientation="0,0,0" />
    </box>
    <box id="marker6" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="3.6,2.4,0"  orientation="0,0,0" />
    </box>
    <box id="marker7" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="2.3,2.6,0"  orientation="0,0,0" />
    </box>
    <box id="marker8" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="1.0,3.0,0"  orientation="0,0,0" />
    </box>
    <box id="marker9" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-1.2,2.8,0"  orientation="0,0,0" />
    </box>
    <box id="marker10" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-3.1,3.2,0"  orientation="0,0,0" />
    </box>
    <box id="marker11" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-4.3,2.5,0"  orientation="0,0,0" />
    </box>
    <box id="marker12" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-5.1,1.3,0"  orientation="0,0,0" />
    </box>
    <box id="marker13" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-4.6,-1.3,0"  orientation="0,0,0" />
    </box>
    <box id="marker14" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-3.6,-2.1,0"  orientation="0,0,0" />
    </box>
    <box id="marker15" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-3.0,-2.7,0"  orientation="0,0,0" />
    </box>
    <box id="marker16" size="0.20,0.20,0.20" movable="false" mass="10">
      <body position="-1.0,-3.1,0"  orientation="0,0,0" />
    </box-->

    <!-- arena -->
    <box id="south_arena_inner" size="0.02,2.62,0.10" movable="false" mass="10">
      <body position="-4.31,0,0"  orientation="0,0,0" />
    </box>
    <box id="north_arena_inner" size="0.02,2.62,0.10" movable="false" mass="10">
      <body position="4.31,0,0"  orientation="0,0,0" />
    </box>
    <box id="west_arena_inner" size="6.62,0.02,0.10" movable="false" mass="10">
      <body position="0, -2.31,0"  orientation="0,0,0" />
    </box>
    <box id="east_arena_inner" size="6.62,0.02,0.10" movable="false" mass="10">
      <body position="-, 2.31,0"  orientation="0,0,0" />
    </box>
    <box id="south_west_arena_inner" size="0.02,1.42,0.10" movable="false" mass="10">
      <body position="-3.81,-1.81,0"  orientation="45,0,0" />
    </box>
    <box id="south_east_arena_inner" size="0.02,1.42,0.10" movable="false" mass="10">
      <body position="3.81,-1.81,0"  orientation="-45,0,0" />
    </box>
    <box id="north_east_arena_inner" size="0.02,1.42,0.10" movable="false" mass="10">
      <body position="3.81,1.81,0"  orientation="45,0,0" />
    </box>
    <box id="north_west_arena_inner" size="0.02,1.42,0.10" movable="false" mass="10">
      <body position="-3.81,1.81,0"  orientation="-45,0,0" />
    </box>

    <!--box id="south_arena" size="0.02,6.04,0.10" movable="false" mass="10">
      <body position="-5.01,0,0"  orientation="0,0,0" />
    </box>
    <box id="north_arena" size="0.02,6.04,0.10" movable="false" mass="10">
      <body position="5.01,0,0"  orientation="0,0,0" />
    </box>
    <box id="west_arena" size="10.00,0.02,0.10" movable="false" mass="10">
      <body position="0, -3.01,0"  orientation="0,0,0" />
    </box>
    <box id="east_arena" size="10.00,0.02,0.10" movable="false" mass="10">
      <body position="-, 3.01,0"  orientation="0,0,0" />
    </box-->


    '''
    return text

#######################################################################
# add xml of drone, pipuck, obstacle, targets
def generate_obstacle_xml(i, x, y, th, type) :
    return generate_obstacle_box_xml(i, x, y, th, type)

def generate_obstacle_box_xml(i, x, y, th, type) :
    tag = '''
    <prototype id="obstacle{}" movable="false" friction="10">
        <body position="{},{},0" orientation="{},0,0" />
        <links ref="base">
            <link id="base" geometry="box" size="0.12, 0.12, 0.1" mass="0.01"
                  position="0,0,0" orientation="0,0,0" />
        </links>
        <devices>
            <tags medium="tags">
                <tag anchor="base" observable_angle="75" side_length="0.1078" payload="{}"
                     position="0,0,0.101" orientation="0,0,0" />
            </tags>
        </devices>
    </prototype>
    '''.format(i, x, y, th, type)
    return tag

def generate_obstacle_cylinder_xml(i, x, y, th, type) :
    tag = '''
    <prototype id="obstacle{}" movable="false" friction="10">
        <body position="{},{},0" orientation="{},0,0" />
        <links ref="base">
            <link id="base" geometry="cylinder" radius="0.10" height="0.1" mass="0.01"
                  position="0,0,0" orientation="0,0,0" />
        </links>
        <devices>
            <tags medium="tags">
                <tag anchor="base" observable_angle="75" side_length="0.1078" payload="{}"
                     position="0,0,0.101" orientation="0,0,0" />
            </tags>
        </devices>
    </prototype>
    '''.format(i, x, y, th, type)
    return tag

def generate_block_xml(i, x, y, th, type) :
    tag = '''
    <block id="obstacle{}" init_led_color="{}">
        <body position="{},{},0" orientation="{},0,0" />
        <controller config="block"/>
    </block>
    '''.format(i, type, x, y, th)
    return tag

def generate_drone_xml(i, x, y, th, wifi_range=None) :
    wifi_range_xml = ""
    if wifi_range != None:
      wifi_range_xml = '''wifi_transmission_range="{}"'''.format(wifi_range)
    tag = '''
    <drone id="drone{}" wifi_medium="wifi" {}>
        <body position="{},{},0" orientation="{},0,0"/>
        <controller config="drone"/>
    </drone>
    '''.format(i, wifi_range_xml, x, y, th)
    return tag

def generate_pipuck_xml(i, x, y, th, wifi_range=None) :
    wifi_range_xml = ""
    if wifi_range != None:
      wifi_range_xml = '''wifi_transmission_range="{}"'''.format(wifi_range)
    tag = '''
    <pipuck_ext id="pipuck{}" wifi_medium="wifi" tag_medium="tags" debug="true">
        <body position="{},{},0" orientation="{},0,0"/>
        <controller config="pipuck"/>
    </pipuck_ext>
    '''.format(i, wifi_range_xml, x, y, th)
    return tag

########## target ##############################################################
def generate_target_tag_xml(x, y, payload):
    tag = '''
        <tag anchor="base" observable_angle="75" side_length="0.1078" payload="{}"
             position="{},{},0.11" orientation="0,0,0" />
    '''.format(payload, x, y)
    return tag

def generate_target_tags_xml(r, l, mark_payload, obstacle_payload):
    tags = generate_target_tag_xml(-r, 0, mark_payload)

    if l > r * 2 :
        return tags

    th = math.asin(l/2/r) * 2
    alpha = 0
    while alpha < math.pi * 2 - th :
        tags = tags + generate_target_tag_xml(r * math.cos(alpha + math.pi),
                                              r * math.sin(alpha + math.pi),
                                              obstacle_payload
        )
        alpha = alpha + th

    return tags

def generate_target_xml(x, y, th, mark_type, obstacle_type, radius, tag_edge_distance, tag_distance):
    tag = '''
    <prototype id="target" movable="true" friction="2">
        <body position="{},{},0" orientation="{},0,0" />
        <links ref="base">
            <link id="base" geometry="cylinder" radius="{}" height="0.1" mass="0.10"
                  position="0,0,0" orientation="0,0,0" />
        </links>
        <devices>
            <tags medium="tags">
                {}
            </tags>
        </devices>
    </prototype>
    '''.format(x, y, th, radius, generate_target_tags_xml(radius-tag_edge_distance, tag_distance, mark_type, obstacle_type))
    return tag

########## 3D gate ##############################################################
def generate_3D_rectangular_gate_xml(id, x, y, z, rx, ry, rz, payload=0, size_x=5.0, size_y=3.0, thickness=0.2, margin_x=None, margin_y=None):
    bottom_position = "{}, {}, {}".format(0,            0,                  -size_y*0.5 - thickness*0.5)
    bottom_size =     "{}, {}, {}".format(thickness,    size_x + thickness, thickness)

    up_position =     "{}, {}, {}".format(0,            0,                  size_y*0.5 - thickness * 0.5)
    up_size =         "{}, {}, {}".format(thickness,    size_x + thickness, thickness)

    left_position =   "{}, {}, {}".format(0,            -size_x*0.5,        -size_y*0.5 + thickness * 0.5)
    left_size =       "{}, {}, {}".format(thickness,    thickness,          size_y - thickness)

    right_position =  "{}, {}, {}".format(0,            size_x*0.5,         -size_y*0.5 + thickness * 0.5)
    right_size =      "{}, {}, {}".format(thickness,    thickness,          size_y - thickness)

    up_joint =        "{}, {}, {}".format(0,            0,                  size_y)
    left_joint =      "{}, {}, {}".format(0,            -size_x*0.5,        thickness)
    right_joint =     "{}, {}, {}".format(0,            size_x*0.5,         thickness)

    tag_position =    "{}, {}, {}".format(0,            0,                  thickness + 0.005)

    margin = ""
    margin_joints = ""
    if margin_x != None and margin_y != None and margin_x > size_x and margin_y > size_y :
      margin = '''
        <link id="up_margin"     geometry="box" mass="1" position="{},{},{}" orientation="0,0,0" size="{},{},{}"/>
        <link id="bottom_margin" geometry="box" mass="1" position="{},{},{}" orientation="0,0,0" size="{},{},{}"/>
        <link id="left_margin" geometry="box" mass="1" position="{},{},{}" orientation="0,0,0" size="{},{},{}"/>
        <link id="right_margin" geometry="box" mass="1" position="{},{},{}" orientation="0,0,0" size="{},{},{}"/>
      '''.format(
        0,               0,                  size_y*0.5 - thickness * 0.5, 
        thickness,       margin_x,           (margin_y-size_y)*0.5+thickness*0.5,

        0,               0,                  -margin_y*0.5, 
        thickness,       margin_x,           (margin_y-size_y)*0.5+thickness*0.5,

        0,               -size_x*0.5+thickness*0.5-((margin_x-size_x)*0.5+thickness*0.5)*0.5, -size_y*0.5+thickness*0.5,
        thickness,       (margin_x-size_x)*0.5+thickness*0.5,     size_y-thickness,

        0,               -(-size_x*0.5+thickness*0.5-((margin_x-size_x)*0.5+thickness*0.5)*0.5), -size_y*0.5+thickness*0.5,
        thickness,       (margin_x-size_x)*0.5+thickness*0.5,     size_y-thickness
      )

      margin_joints = '''
        <joint id="bottom_up_margin" type="fixed">
          <parent link="bottom" position="{},{},{}" orientation="0,0,0"/>
          <child  link="up_margin"  position="0,0,0" orientation="0,0,0"/>
        </joint>
        <joint id="bottom_bottom_margin" type="fixed">
          <parent link="bottom" position="{},{},{}" orientation="0,0,0"/>
          <child  link="bottom_margin"  position="0,0,0" orientation="0,0,0"/>
        </joint>
        <joint id="bottom_left_margin" type="fixed">
          <parent link="bottom" position="{},{},{}" orientation="0,0,0"/>
          <child  link="left_margin"  position="0,0,0" orientation="0,0,0"/>
        </joint>
        <joint id="bottom_right_margin" type="fixed">
          <parent link="bottom" position="{},{},{}" orientation="0,0,0"/>
          <child  link="right_margin"  position="0,0,0" orientation="0,0,0"/>
        </joint>
      '''.format(
        0,              0,                   size_y,
        0,              0,                   -(margin_y-size_y)*0.5+thickness*0.5,
        0,              -size_x*0.5+thickness*0.5-((margin_x-size_x)*0.5+thickness*0.5)*0.5,                    thickness,
        0,              -(-size_x*0.5+thickness*0.5-((margin_x-size_x)*0.5+thickness*0.5)*0.5),                 thickness
      )

    tag = '''
    <!-- add obstacles -->
    <prototype id="3D_rectangular_gate{}" movable="false">
      <body position="{},{},{}" orientation="{},{},{}" />
      <links ref="bottom">
        <link id="bottom" geometry="box" mass="1" position="{}" orientation="0,0,0" size="{}"/>
        <link id="up"     geometry="box" mass="1" position="{}" orientation="0,0,0" size="{}"/>
        <link id="left"   geometry="box" mass="1" position="{}" orientation="0,0,0" size="{}"/>
        <link id="right"  geometry="box" mass="1" position="{}" orientation="0,0,0" size="{}"/>
        {}
      </links>
      <joints>
        <joint id="bottom_up" type="fixed">
          <parent link="bottom" position="{}" orientation="0,0,0"/>
          <child  link="up"     position="0,0,0" orientation="0,0,0"/>
        </joint>
        <joint id="bottom_left" type="fixed">
          <parent link="bottom" position="{}" orientation="0,0,0"/>
          <child  link="left"   position="0,0,0" orientation="0,0,0"/>
        </joint>
        <joint id="bottom_right" type="fixed">
          <parent link="bottom" position="{}" orientation="0,0,0"/>
          <child  link="right"  position="0,0,0" orientation="0,0,0"/>
        </joint>
        {}
      </joints>
      <devices>
        <tags medium="tags">
          <tag anchor="bottom" observable_angle="75" side_length="0.1078" payload="{}"
               position="{}" orientation="0,0,0" />
        </tags>
      </devices>
    </prototype>
    '''.format(id,
               x, y, z, rx, ry, rz,
               bottom_position, bottom_size,
               up_position,     up_size,
               left_position,   left_size,
               right_position,  right_size,
               margin,
               up_joint, left_joint, right_joint,
               margin_joints,
               payload, tag_position
              )
    return tag

def generate_3D_triangle_gate_xml(id, x, y, z, rx, ry, rz, payload=0, size_x=5.0, thickness=0.2, margin_x=None, margin_y=None):
    L = size_x
    l = size_x * 0.5
    d = l / math.sqrt(3)

    bottom_position = "{}, {}, {}".format(0,            0,                  -d - thickness*0.5)
    bottom_size =     "{}, {}, {}".format(thickness,    L,                  thickness)

    left_position =   "{}, {}, {}".format(0,            l,                  -d)
    left_size =       "{}, {}, {}".format(thickness,    thickness,          L)

    right_position =  "{}, {}, {}".format(0,            -l,                 -d)
    right_size =      "{}, {}, {}".format(thickness,    thickness,          L)

    left_joint =      "{}, {}, {}".format(0,            l,                  thickness*0.5)
    right_joint =     "{}, {}, {}".format(0,            -l,                 thickness*0.5)

    tag_position =    "{}, {}, {}".format(0,            0,                  thickness + 0.005)

    margin = ""
    margin_joints = "" 

    if margin_x != None and margin_y != None and margin_x > size_x and margin_y > d * 4 :
      margin = '''
        <link id="bottom_margin"  geometry="box" mass="1" position="{},{},{}" orientation="0,0,0" size="{},{},{}"/>
        <link id="left_margin"  geometry="convex_hull" mass="1" position="0,0,0" orientation="0,0,0" > 
          ({},{},{})({},{},{})({},{},{})({},{},{})({},{},{})
          ({},{},{})({},{},{})({},{},{})({},{},{})({},{},{})
        </link>
        <link id="right_margin"  geometry="convex_hull" mass="1" position="0,0,0" orientation="0,0,0" > 
          ({},{},{})({},{},{})({},{},{})({},{},{})({},{},{})
          ({},{},{})({},{},{})({},{},{})({},{},{})({},{},{})
        </link>
      '''.format(
        0,          0,         -margin_y*0.5, 
        thickness,  margin_x,    margin_y*0.5-d+thickness*0.5,

        -thickness*0.5,     l,                 -d,
         thickness*0.5,     l,                 -d,
        -thickness*0.5,     margin_y*0.5,      -d,
         thickness*0.5,     margin_y*0.5,      -d,
        -thickness*0.5,     margin_y*0.5,      margin_x*0.5,
         thickness*0.5,     margin_y*0.5,      margin_x*0.5,
        -thickness*0.5,     0,                 margin_x*0.5,
         thickness*0.5,     0,                 margin_x*0.5,
        -thickness*0.5,     0,                 d*2,
         thickness*0.5,     0,                 d*2,

        -thickness*0.5,     -l,                 -d,
         thickness*0.5,     -l,                 -d,
        -thickness*0.5,     -margin_y*0.5,      -d,
         thickness*0.5,     -margin_y*0.5,      -d,
        -thickness*0.5,     -margin_y*0.5,      margin_x*0.5,
         thickness*0.5,     -margin_y*0.5,      margin_x*0.5,
        -thickness*0.5,     -0,                 margin_x*0.5,
         thickness*0.5,     -0,                 margin_x*0.5,
        -thickness*0.5,     -0,                 d*2,
         thickness*0.5,     -0,                 d*2,
      )
      margin_joints = '''
        <joint id="bottom_bottom_margin" type="fixed">
          <parent link="bottom" position="{},{},{}" orientation="0,0,0"/>
          <child  link="bottom_margin"  position="0,0,0" orientation="0,0,0"/>
        </joint>

        <joint id="bottom_left_margin" type="fixed">
          <parent link="bottom" position="{},{},{}" orientation="0,0,0"/>
          <child  link="left_margin"  position="0,0,0" orientation="0,0,0"/>
        </joint>

        <joint id="bottom_right_margin" type="fixed">
          <parent link="bottom" position="{},{},{}" orientation="0,0,0"/>
          <child  link="right_margin"  position="0,0,0" orientation="0,0,0"/>
        </joint>
      '''.format(
        0,        0,      -(margin_y*0.5-d-thickness*0.5),
        0,        0,      d+thickness*0.5,
        0,        0,      d+thickness*0.5,
      )

    tag = '''
    <!-- add obstacles -->
    <prototype id="3D_triangle_gate{}" movable="false">
      <body position="{},{},{}" orientation="{},{},{}" />
      <links ref="bottom">
        <link id="bottom" geometry="box" mass="1" position="{}" orientation="0,0,0" size="{}"/>
        <link id="left"   geometry="box" mass="1" position="{}" orientation="0,0,30" size="{}"/>
        <link id="right"  geometry="box" mass="1" position="{}" orientation="0,0,-30" size="{}"/>
        {}
      </links>
      <joints>
        <joint id="bottom_left" type="fixed">
          <parent link="bottom" position="{}" orientation="0,0,30"/>
          <child  link="left"   position="0,0,0" orientation="0,0,0"/>
        </joint>
        <joint id="bottom_right" type="fixed">
          <parent link="bottom" position="{}" orientation="0,0,-30"/>
          <child  link="right"   position="0,0,0" orientation="0,0,0"/>
        </joint>
        {}
      </joints>
      <devices>
        <tags medium="tags">
          <tag anchor="bottom" observable_angle="75" side_length="0.1078" payload="{}"
               position="{}" orientation="0,0,0" />
        </tags>
      </devices>
    </prototype>
    '''.format(id,
               x, y, z, rx, ry, rz,
               bottom_position, bottom_size,
               left_position,   left_size,
               right_position,  right_size,
               margin,
               left_joint, right_joint,
               margin_joints,
               payload, tag_position
              )
    return tag

def generate_3D_circle_gate_xml(id, x, y, z, rx, ry, rz, payload=0, size_x=5.0, knots = 8, thickness = 0.2):
    R = size_x / 2
    th = math.pi * 2 / knots
    th_degree = th * 180 / math.pi
    L = 2 * R * math.tan(th*0.5)

    size_tag = "{}, {}, {}".format(thickness,    L,   thickness)

    def generate_link(id, y, z, rad) :
        return '''<link id="link{}" geometry="box" mass="1" position="0, {}, {}" orientation="0,0,{}" size="{}"/>\n'''.format(id, y, z, rad, size_tag)
    def generate_joint(id, y, z, rad) :
        return '''
        <joint id="bottom_link{}" type="fixed">
          <parent link="bottom"  position="0, {}, {}" orientation="0,0,{}"/>
          <child  link="link{}"   position="0,0,0" orientation="0,0,0"/>
        </joint>
        '''.format(id, y, z-thickness*0.5, rad, id)


    bottom_position = "{}, {}, {}".format(0,            0,                  -R - thickness*0.5)
    tag_position =    "{}, {}, {}".format(0,            0,                  thickness + 0.005)

    links_tag = '''<link id="bottom" geometry="box" mass="1" position="{}" orientation="0,0,0" size="{}"/>\n'''.format(bottom_position, size_tag)
    joints_tag = ""

    for i in range(1, knots) :
        links_tag += generate_link(i,   (R+thickness*0.5)*math.sin(th*i), (R+thickness*0.5)*(-math.cos(th*i)), th_degree*i)
        joints_tag += generate_joint(i, (R+thickness*0.5)*math.sin(th*i), (R+thickness*0.5)*(1-math.cos(th*i))+thickness*0.5, th_degree*i)

    tag = '''
    <!-- add obstacles -->
    <prototype id="3D_circle_gate{}" movable="false">
      <body position="{},{},{}" orientation="{},{},{}" />
      <links ref="bottom">
        {}
      </links>
      <joints>
        {}
      </joints>
      <devices>
        <tags medium="tags">
          <tag anchor="bottom" observable_angle="75" side_length="0.1078" payload="{}"
               position="{}" orientation="0,0,0" />
        </tags>
      </devices>
    </prototype>
    '''.format(id,
               x, y, z, rx, ry, rz,
               links_tag, joints_tag,
               payload, tag_position
              )
    return tag

#######################################################################
# generate random locations

# from <left_end> to <right_end>, generate <gate_number> gates of different sizes ranging from <small_limit> and <large_limit>
# return an array of gates in order
#	[
#		[left1, right1],
#		[left2, right2],
#	]
#	and the middle of the largest gate
attempt_count_down_default = 1000
def generate_gate_locations(gate_number, left_end, right_end, small_limit, large_limit, max_size, attempt_count_down_input=attempt_count_down_default) :
    margin = 0.4
    a = []
    largest_length = 0
    largest_loc = 0
    for i in range(1, gate_number+1) :
        valid_position = False
        attempt_count_down = attempt_count_down_input
        while valid_position == False :
            # check attempt
            if attempt_count_down == 0 :
                print("[warning] gate locations incomplete")
                break
            else :
                attempt_count_down = attempt_count_down - 1

            # generate a random location
            loc = left_end + random.random() * (right_end - left_end)
            size = small_limit + random.random() * (large_limit - small_limit)
            if i == 1 :
                size = max_size
            left = loc - size/2
            right = loc + size/2

            # valid check
            if left - margin < left_end or right + margin > right_end :
                valid_position = False
                continue

            valid_position = True
            for item in a:
                if (item[0] < left - margin and right + margin < item[1] or
                    left - margin < item[0] and item[0] < right + margin or
                    left - margin < item[1] and item[1] < right + margin
                   ) :
                    valid_position = False
                    break

            if valid_position == True:
                # push into list
                a.append([left,right])
                # check largest
                if right - left > largest_length :
                    largest_length = right - left
                    largest_loc = (left + right) / 2
        if attempt_count_down == 0 :
            break

    #sort
    for i in range(0, gate_number-1) :
        for j in range(i+1, gate_number) :
            if a[i][0] > a[j][0] :
                temp = a[i]
                a[i] = a[j]
                a[j] = temp
    return a, largest_loc

# from <left_end> to <right_end>, generate <gate_number> gates of different sizes ranging from <small_limit> and <large_limit>
# fill the wall with <step>
# return an array of gates in order
#	[
#		[1D-location, type],
#	]
#	and the middle of the largest gate
def generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step, gate_brick_type, wall_brick_type) :
    return generate_wall_brick_locations(gate_number, left_end, right_end, small_limit, large_limit, step, 0.055, gate_brick_type, wall_brick_type)

def generate_obstacle_locations(gate_number, left_end, right_end, small_limit, large_limit, max_size, step, gate_brick_type, wall_brick_type) :
    return generate_wall_brick_locations(gate_number, left_end, right_end, small_limit, large_limit, max_size, step, 0.10, gate_brick_type, wall_brick_type) # 254 gate, 255 wall brick

def generate_wall_brick_locations(gate_number, left_end, right_end, small_limit, large_limit, max_size, step, brick_size, gate_brick_type, wall_brick_type) :
    block_locations = []
    margin = 0.10
    gate_locations, largest_loc = generate_gate_locations(gate_number, left_end + margin, right_end - margin, small_limit, large_limit, max_size)
    for i in range(0, gate_number + 1) :
        # get interval of gates
        left = left_end
        right = right_end
        if i != 0 :
            left = gate_locations[i-1][1]
        if i != gate_number :
            right = gate_locations[i][0]

        #set blocks from left to right
        #set left block
        j = left
        block_locations.append([left, -90, gate_brick_type])
        j = j + step
        #set middle block
        while j < right - brick_size:
            block_locations.append([j, 0, wall_brick_type])
            j = j + step
        #set right block
        block_locations.append([right, 90, gate_brick_type])

    return block_locations, largest_loc

# from <left_end> to <right_end>, generate <gate_number> gates of different sizes ranging from <small_limit> and <large_limit>
# fill the wall with <step>
# return an array of gates in order
#	[
#		[1D-location, type],
#	]
#	and the middle of the largest gate
def generate_wall(gate_number, wall_x, left_end, right_end, small_limit, large_limit, max_size, step, gate_brick_type, wall_brick_type) :
    tagstr = ""
    #block_locations, largest_loc = generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step, gate_brick_type, wall_brick_type) 
    block_locations, largest_loc = generate_obstacle_locations(gate_number, left_end, right_end, small_limit, large_limit, max_size, step, gate_brick_type, wall_brick_type) 
    i = 0
    for loc in block_locations :
        i = i + 1
        tagstr = tagstr + generate_obstacle_xml(i, wall_x, loc[0], loc[1], loc[2]) #loc[0 to 2] means y, th, type

    return tagstr, largest_loc

def generate_line_locations(number, x_left, y_left, x_right, y_right) :
    a = []
    x = x_left
    y = y_left
    x_inc = (x_right - x_left) / (number-1)
    y_inc = (y_right - y_left) / (number-1)
    for i in range(1,number + 1):
        a.append([x,y])
        x = x + x_inc
        y = y + y_inc

    return a

#- random locations ------------------------------------------------------------------------
def generate_random_locations(n, origin_x,    origin_y, 
                                 x_min_limit, x_max_limit,
                                 y_min_limit, y_max_limit, 
                                 near_limit,  far_limit,
                                 attempt_count_down_input=attempt_count_down_default) :
    a = []

    # if origin is not None then add origin as the first
    start = 0
    if origin_x != None and origin_y != None :
        a.append([origin_x, origin_y])
        start = 1

    # start generating
    for i in range(start, n) : # 0/1 to n - 1
        valid = False
        attempt_count_down = attempt_count_down_input
        while valid == False :
            # check attempt
            if attempt_count_down == 0 :
                print("[warning] random locations incomplete")
                break
            else :
                attempt_count_down = attempt_count_down - 1

            # generate a random location
            loc_x = x_min_limit + random.random() * (x_max_limit - x_min_limit)
            loc_y = y_min_limit + random.random() * (y_max_limit - y_min_limit)

            #check near
            valid = True
            for j in range(0, i) :
                if (loc_x - a[j][0]) ** 2 + (loc_y - a[j][1]) ** 2 < near_limit ** 2 :
                    valid = False
                    break
            if valid == False :
                continue

            #check faraway
            valid = False
            if i == 0 :
                valid = True
            for j in range(0, i) :
                if (loc_x - a[j][0]) ** 2 + (loc_y - a[j][1]) ** 2 < far_limit ** 2 :
                    valid = True
                    break
            if valid == True :
                a.append([loc_x, loc_y])
        if attempt_count_down == 0 :
            break
    return a

def generate_slave_locations(n, master_locations,
                                x_min_limit, x_max_limit,
                                y_min_limit, y_max_limit,
                                near_limit, far_limit) :
    return generate_slave_locations_with_origin(n,
                                                master_locations,
                                                None, None,
                                                x_min_limit, x_max_limit,
                                                y_min_limit, y_max_limit,
                                                near_limit, far_limit)


def generate_slave_locations_with_origin(n, master_locations,
                                         origin_x, origin_y,
                                         x_min_limit, x_max_limit,
                                         y_min_limit, y_max_limit,
                                         near_limit, far_limit,
                                         attempt_count_down_input=attempt_count_down_default) :
    a = []

    # if origin is not None then add origin as the first
    start = 0
    if origin_x != None and origin_y != None :
        a.append([origin_x, origin_y])
        start = 1

    for i in range(start, n) :
        valid = False
        attempt_count_down = attempt_count_down_input
        while valid == False :
            # check attempt
            if attempt_count_down == 0 :
                print("[warning] slave locations incomplete")
                break
            else :
                attempt_count_down = attempt_count_down - 1

            # generate a random location
            loc_x = x_min_limit + random.random() * (x_max_limit - x_min_limit)
            loc_y = y_min_limit + random.random() * (y_max_limit - y_min_limit)

            # check near
            valid = True
            for j in range(0, i) :
                if (loc_x - a[j][0]) ** 2 + (loc_y - a[j][1]) ** 2 < near_limit ** 2 :
                    valid = False
                    break
            if valid == False :
                continue

            #check faraway
            valid = False
            for drone_loc in master_locations :
                if (loc_x - drone_loc[0]) ** 2 + (loc_y - drone_loc[1]) ** 2 < far_limit ** 2 :
                    valid = True
                    break
            if valid == True :
                a.append([loc_x, loc_y])
        if attempt_count_down == 0 :
            break
    return a

def generate_drones(locations, start_id, wifi_range=None) :
    tagstr = ""
    i = start_id
    for loc in locations :
        tagstr = tagstr + generate_drone_xml(i, loc[0], loc[1], 0, wifi_range)
        i = i + 1
    return tagstr

def generate_pipucks(locations, start_id, wifi_range=None) :
    tagstr = ""
    i = start_id
    for loc in locations :
        tagstr = tagstr + generate_pipuck_xml(i, loc[0], loc[1], 0, wifi_range)
        i = i + 1
    return tagstr

def generate_obstacles(locations, start_id, type) :
    tagstr = ""
    i = start_id
    for loc in locations :
        tagstr = tagstr + generate_obstacle_xml(i, loc[0], loc[1], 0, type)
        i = i + 1
    return tagstr
#######################################################################
# create argos file
def generate_argos_file(template_name, argos_name, replacements) :
    '''
    replacements =
    [
        [RANDOMSEED, str(500)],
        [xxx, yyy],
        [xxx, yyy],
    ]
    '''
    with open(template_name, 'r') as file :
        filedata = file.read()

    for i in replacements :
        filedata = filedata.replace(i[0], i[1])

    with open(argos_name, 'w') as file:
        file.write(filedata)
