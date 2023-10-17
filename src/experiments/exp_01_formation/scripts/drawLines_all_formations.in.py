drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

fig, axs = plt.subplots(3,3)

Experiment_types = {
    "polyhedron_12": axs[0,0],
    "polyhedron_20": axs[0,1],
    "cube_27"  : axs[1,0],
    "cube_64"  : axs[1,1],
    #"cube_125" : axs[1,2],
    "donut_48" : axs[2,0],
    "donut_64" : axs[2,1],
    "screen_64": axs[2,2],
}

#ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_01_formation"
#ExperimentsDIR = "/home/harry/code/3Ddrone-data/with_intersection_solver/exp_01_formation_no_rangefinder"
ExperimentsDIR = "/home/harry/code/3Ddrone-data/with_intersection_solver/exp_01_formation_normal_12_rangefinders"
#ExperimentsDIR = "/home/harry/code/3Ddrone-data/with_intersection_solver/exp_01_formation_200_rangefinders"

for Experiment_type in Experiment_types :
    print("Drawing ", Experiment_type)

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
        if data[150] > 0.25 :
            print(subfolder)
        drawDataInSubplot(data, Experiment_types[Experiment_type])
        #data = readDataFrom(subfolder + "result_minimum_distances.txt")
        #drawDataInSubplot(data, Experiment_types[Experiment_type])
        #Experiment_types[Experiment_type].set_ylim([0,20])
        Experiment_types[Experiment_type].set_title(Experiment_type)
    #plt.legend(legend)

'''
drawData(readDataFrom("result_data.txt"))
drawData(readDataFrom("result_minimum_distances.txt"))
'''

plt.show()
