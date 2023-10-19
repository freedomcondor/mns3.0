drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

customizeOpts = "t:"
logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/logReader/logReplayer.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))

drawTrackLogFileName = "@CMAKE_SOURCE_DIR@/scripts/drawTrackLogs.py"
exec(compile(open(drawTrackLogFileName, "rb").read(), drawTrackLogFileName, 'exec'))

# Get experiment type
#--------------------------------------
usage="[usage] example: python3 xxx.py -t polyhedron_12"
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
    Experiment_type = "polyhedron_12"
    print("Experiment_type not provided: using default", Experiment_type)

# start to draw
#-----------------------------------------
dataFolder = "@CMAKE_MNS_DATA_PATH@/exp_01_formation/exp_01_formation_normal_12_rangefinders/" + Experiment_type + "/run_data"

sample_run = "run1"

option = {
	'dataFolder'             : dataFolder,
	'sample_run'             : sample_run,
	'trackLog_save'          : "exp_01_formation_" + Experiment_type + ".pdf",
	'trackLog_show'          : False,

	'brain_marker'      :    '@CMAKE_SOURCE_DIR@/scripts/brain-icon-small.svg',
	'key_frame' :  [0] ,

	'x_lim'     :  [-20.0, 20.0]    ,
	'y_lim'     :  [-20.0, 20.0]    ,
	'z_lim'     :  [-1.0,  39.0]    ,
	'look_from' :  [45, 45],
}

drawTrackLog(option)
