drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

Experiment_types = {
    "polyhedron_12",
    "polyhedron_20",
    "cube_27",
    "cube_64",
    #"cube_125", : axs[1,2],
    "donut_48",
    "donut_64",
    "screen_64",
}

fig, axs = plt.subplots(1,3)

#ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_01_formation"
ExperimentsDIR1 = "/home/harry/code/3Ddrone-data/with_intersection_solver/exp_01_formation_no_rangefinder"
ExperimentsDIR2 = "/home/harry/code/3Ddrone-data/with_intersection_solver/exp_01_formation_normal_12_rangefinders"
ExperimentsDIR3 = "/home/harry/code/3Ddrone-data/with_intersection_solver/exp_01_formation_200_rangefinders"

ExperimentsDIRS = {
    ExperimentsDIR1 : axs[0],
    ExperimentsDIR2 : axs[1],
    ExperimentsDIR3 : axs[2],
}

for ExperimentsDIR in ExperimentsDIRS :
    totalData = []
    for Experiment_type in Experiment_types :

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
            data = readDataFrom(subfolder + "result_minimum_distances.txt")
            totalData = totalData + data
        
    ExperimentsDIRS[ExperimentsDIR].boxplot(totalData, showmeans=True)
    ExperimentsDIRS[ExperimentsDIR].set_ylim(0,6)

plt.show()
