import getopt
import sys
import xml.etree.ElementTree as ET

#----------------------------------------------------------------------------------------------
# usage message 
usage="[usage] example: python3 create_calibration_file.py -i lua_calibration.xml -t /home/root/calibration/builderbot_camera_system.xml"
print(usage)

#----------------------------------------------------------------------------------------------
# parse opts
try:
	optlist, args = getopt.getopt(sys.argv[1:], "i:t:h")
except:
	print("[error] unexpected opts")
	print(usage)
	sys.exit(0)

input_file = ""
output_file = ""
arm = ""

for opt, value in optlist:
	if opt == "-i":
		input_file = value
		print("input_file provided:", input_file)
	elif opt == "-t":
		output_file = value
		print("output_file provided:", output_file)
	elif opt == "-h":
		print(usage)
		exit()

#----------------------------------------------------------------------------------------------
# default value
if input_file == "":
	input_file = "lua_calibration.xml"
	print("input_file not provided, use default:", input_file)

if output_file == "":
	output_file = "/home/root/calibration/builderbot_camera_system.xml"
	print("output_file not provided, use default:", output_file)

#----------------------------------------------------------------------------------------------
# read position and orientation from input_file
position_text = None; orientation_text = None
root = ET.parse(input_file).getroot()
# get camera_matrix tag
for extrinsic_tag in root.findall("extrinsic"):
	#if arm_tag.attrib[id]
	position_text = extrinsic_tag.attrib["position"]
	orientation_text = extrinsic_tag.attrib["orientation"]
	break

print("Read extrinsic parameters")
if position_text == None:
	print("position is not detected in " + input_file)
	exit()
print("position = " + position_text)
print("orientation = " + orientation_text)

#----------------------------------------------------------------------------------------------
# read output file and attributes to it
xml_file = ET.parse(output_file)
root = xml_file.getroot()
attrib = ""
for camera_tag in root.findall("builderbot_camera_system"):
	camera_tag.attrib["position"] = position_text
	camera_tag.attrib["orientation"] = orientation_text 
	attrib = camera_tag.attrib

#xml_file.write(output_file, encoding="utf8")

# write output file
str='''<?xml version="1.0" ?>
<calibration>
   <builderbot_camera_system focal_length="{}"
                             principal_point="{}"
                             position="{}"
                             orientation="{}"/>
</calibration>
'''.format(attrib["focal_length"],
           attrib["principal_point"],
           attrib["position"],
           attrib["orientation"])

f = open(output_file, "w")
f.write(str)
f.close()
print("File \"" + output_file + "\" updated!")