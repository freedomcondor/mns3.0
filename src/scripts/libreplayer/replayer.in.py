import os
import string
import re

customizeOpts = True
createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

#----------------------------------------------------------------------------------------------
# usage message 
usage="[usage] example: python3 replayer.py -i xxx/logs"

#----------------------------------------------------------------------------------------------
# parse opts
try:
    optlist, args = getopt.getopt(sys.argv[1:], "i:h")
except:
    print("[error] unexpected opts")
    print(usage)
    sys.exit(0)

InputFolder = None

for opt, value in optlist:
    if opt == "-i":
        InputFolder = value
        print("Inputseed provided:", InputFolder)
    elif opt == "-h":
        print(usage)
        exit()

if InputFolder == None :
    InputFolder = "./logs"
    print("InputFolder not provided, using:", InputFolder)

#----------------------------------------------------------------------------------------------
# read InputFolder and extract .log
def findRobotLogs(path, robotType) :
	robotNames = []
	robotTypes = []
	for folder in os.walk(path) :
		if folder[0] == path :
			for file in folder[2] :
				name = file.split(".",2)[0]
				ext  = file.split(".",2)[1]
				if ext != "log" :
					continue
				name_head = name.rstrip(string.digits)
				if robotType == "ALL" :
					if name_head == "drone" or name_head == "pipuck" or name_head == "obstacle" or name_head == "target":
						robotNames.append(name)
				else :
					if name_head == robotType :
						robotNames.append(name)
	
	return robotNames

robotNames = findRobotLogs(InputFolder, "drone") 
drone_xml = ""
for robotName in robotNames:
	id = re.findall(r'\d+', robotName)[0]
	drone_xml += generate_drone_xml(id, 0, 0, 0)

robotNames = findRobotLogs(InputFolder, "pipuck") 
pipuck_xml = ""
for robotName in robotNames:
	id = re.findall(r'\d+', robotName)[0]
	pipuck_xml += generate_drone_xml(id, 0, 0, 0)

#----------------------------------------------------------------------------------------------
# write input folder to file so that replay_loop_functions can read it
InputFolderNameFile = open("replay_input_folder.txt", "w")
InputFolderNameFile.write(InputFolder)
InputFolderNameFile.close()

'''
#----------------------------------------------------------------------------------------------
# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/replayer_template.argos", 
                    "replay.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, True)],
    ]
)

os.system("argos3 -c replay.argos")
'''