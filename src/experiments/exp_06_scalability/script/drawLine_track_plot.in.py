drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

customizeOpts = "t:"
logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/logReader/logReplayer.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))

drawTrackLogFileName = "@CMAKE_SOURCE_DIR@/scripts/drawTrackLogs.py"
exec(compile(open(drawTrackLogFileName, "rb").read(), drawTrackLogFileName, 'exec'))

# Get experiment type
#--------------------------------------
usage="[usage] example: python3 xxx.py -t cube_27"
try:
    optlist, args = getopt.getopt(sys.argv[1:], "t:h")
except:
    print("[error] unexpected opts")
    print(usage)
    sys.exit(0)

Experiment_type = None
for opt, value in optlist:
    if opt == "-t":
        Experiment_type = value
        print("Experiment_type provided: ", Experiment_type)
if Experiment_type == None :
    Experiment_type = "cube_27"
    print("Experiment_type not provided: using default", Experiment_type)

# start to draw
#-----------------------------------------
dataFolder = "@CMAKE_MNS_DATA_PATH@/exp_06_scalability/" + Experiment_type + "/run_data"

sample_run = "run1"

option = {
	'dataFolder'             : dataFolder,
	'sample_run'             : sample_run,
	'trackLog_save'          : "exp_06_scalability_" + Experiment_type + ".pdf",
	'trackLog_show'          : False,

	'brain_marker'      :    '@CMAKE_SOURCE_DIR@/scripts/brain-icon-small.svg',
	'key_frame' :  [0, 250, 520] , # cube_27

	'x_lim'     :  [-20.0, 20.0]    ,
	'y_lim'     :  [-20.0, 20.0]    ,
	'z_lim'     :  [-1.0,  39.0]    ,
	'look_from' :  [45, 225],
}

half = 20
if Experiment_type == "cube_27" :
	option['key_frame'] = [0, 250, 520]
	half = 20
elif Experiment_type == "cube_64" :
	option['key_frame'] = [0, 500, 870]
	half = 40
elif Experiment_type == "cube_125" :
	option['key_frame'] = [0, 900, 1500]
	half = 60

option['x_lim'] = [-half, half]
option['y_lim'] = [-half, half]
option['z_lim'] = [-1, half * 2 - 1]

drawTrackLog(option)
