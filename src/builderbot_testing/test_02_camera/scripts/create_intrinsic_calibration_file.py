import getopt
import sys
import xml.etree.ElementTree as ET

#----------------------------------------------------------------------------------------------
# usage message 
usage="[usage] example: python3 create_drone_calibration_file.py -i out_camera_data.xml -t builderbot_camera_system.xml"

#----------------------------------------------------------------------------------------------
# parse opts
try:
	optlist, args = getopt.getopt(sys.argv[1:], "i:t:")
except:
	print("[error] unexpected opts")
	print(usage)
	sys.exit(0)

input_file = ""
output_file = ""

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
	input_file = "out_camera_data.xml"
	print("input_file not provided, use default:", input_file)

if output_file == "":
	output_file = "builderbot_camera_system.xml"
	print("output_file not provided, use default:", output_file)

#----------------------------------------------------------------------------------------------
# read input file to get fx fy cx cy k1 k2 k3 p1 p2
fx = None; fy = None; cx = None; cy = None
root = ET.parse(input_file).getroot()
# get camera_matrix tag
for camera_matrix_tag in root.findall("camera_matrix"):
	for data in camera_matrix_tag.findall("data"):
		print("retrieved camera_matrix data: ", data.text)
		data_array = data.text.split()
		fx = data_array[0];  cx = data_array[2]
		fy = data_array[4];  cy = data_array[5]

print("fx=", fx, "\tfy=", fy)
print("cy=",cx, "\tcy=", cy)

# check parameters
if fx == None or fy == None or cx == None or cy == None :
	print("[error] Reading parameters failure")
	sys.exit()

#----------------------------------------------------------------------------------------------
# write output file
str='''<?xml version="1.0" ?>
<calibration>
   <builderbot_camera_system focal_length="{}, {}"
                             principal_point="{}, {}"
                             position="0,0,0"
                             orientation="0,0,0"
   /> 
</calibration>
'''.format(fx, fy, cx, cy)

f = open(output_file, "w")
f.write(str)
f.close()