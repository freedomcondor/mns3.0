drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

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
    Experiment_type = "cube_27"
    print("Experiment_type not provided: using default", Experiment_type)

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_03_scalability"
DATADIR = ExperimentsDIR + "/" + Experiment_type + "/run_data"

# check experiment type
#--------------------------------------
if not os.path.isdir(DATADIR) :
    print("Data folder doesn't exist : ", DATADIR)
    print("Existing Datafolder are : ")
    for subfolder in getSubfolders(ExperimentsDIR) :
        print("    " + subfolder)
    exit()

# start to draw
#--------------------------------------
legend = []
for subfolder in getSubfolders(DATADIR) :
    legend.append(subfolder)
    data = readDataFrom(subfolder + "result_data.txt")
    #if data[880] > 5 :
    #    print(subfolder)
    drawData(data, "black")

    #data = readDataFrom(subfolder + "result_minimum_distances.txt")
    #drawData(data)

    #for subFile in getSubfiles(subfolder + "result_each_robot_error") :
    #    data = readDataFrom(subFile)
    #    drawData(data)
    #break
#plt.legend(legend)
'''

drawData(readDataFrom("result_data.txt"))
drawData(readDataFrom("result_minimum_distances.txt"))
'''

plt.show()
