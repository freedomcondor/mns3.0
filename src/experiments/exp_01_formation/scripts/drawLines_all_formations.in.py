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

fig, axs = plt.subplots(2,3)

Experiment_types = {
    "cube_27"  : axs[0,0],
    "donut_48" : axs[0,1],
    "cube_64"  : axs[0,2],
    "donut_64" : axs[1,0],
    "screen_64": axs[1,1],
}

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_01_formation"

for Experiment_type in Experiment_types :
    print("Drawing ", Experiment_type)

    #Experiment_type = None
    for opt, value in optlist:
        if opt == "-t":
            Experiment_type = value
            print("Experiment_type provided: ", Experiment_type)
    if Experiment_type == None :
        Experiment_type = "polyhedron_12"
        print("Experiment_type not provided: using default", Experiment_type)

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
        #legend.append(subfolder)
        data = readDataFrom(subfolder + "result_data.txt")
        #if data[150] > 0.25 :
        #    print(subfolder)
        drawDataInSubplot(data, Experiment_types[Experiment_type])
        data = readDataFrom(subfolder + "result_minimum_distances.txt")
        drawDataInSubplot(data, Experiment_types[Experiment_type])
        Experiment_types[Experiment_type].set_ylim([0,5.5])
        Experiment_types[Experiment_type].set_title(Experiment_type)
    #plt.legend(legend)

'''
drawData(readDataFrom("result_data.txt"))
drawData(readDataFrom("result_minimum_distances.txt"))
'''

plt.show()
