drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

fig, axs = plt.subplots(3,3, figsize=(15,9))

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

# appearings of subplots
axs[0,2].axis('off')
axs[1,2].axis('off')
fig.subplots_adjust(
    top=0.95,
    bottom=0.05,
    left=0.05,
    right=0.95,
    hspace=0.3,
    wspace=0.1)  # adjust space between axes

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_01_formation"
#ExperimentsDIR = "/home/harry/code/3Ddrone-data/exp_01_formation/exp_01_formation_no_rangefinder"
#ExperimentsDIR = "/home/harry/code/3Ddrone-data/exp_01_formation/exp_01_formation_normal_12_rangefinders"
#ExperimentsDIR = "/home/harry/code/3Ddrone-data/exp_01_formation/exp_01_formation_200_rangefinders"

for Experiment_type in Experiment_types :
    print("Drawing ", Experiment_type)
    type_ax = Experiment_types[Experiment_type]
    type_ax.set_title(Experiment_type)

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
    runsData = []
    for subfolder in getSubfolders(DATADIR) :
        #legend.append(subfolder)
        data = readDataFrom(subfolder + "result_data.txt")
        runsData.append(data)
        #if data[150] > 0.25 :
        #    print(subfolder)
        #drawDataInSubplot(data, type_ax, "black")
        #data = readDataFrom(subfolder + "result_minimum_distances.txt")
        #drawDataInSubplot(data, type_ax)
        #type_ax.set_ylim([0,20])

        #for subFile in getSubfiles(subfolder + "result_each_robot_error") :
        #    data = readDataFrom(subFile)
        #    drawDataInSubplot(data, type_ax)
        #break
    #plt.legend(legend)

    # convert runs data into steps data, and calc mean min, max ... for each step
    stepsData, X = transferTimeDataToRunSetData(runsData)
    mean, mini, maxi, upper, lower = calcMeanFromStepsData(stepsData)

    legend_handle_mean,\
    legend_handle_lowerupper,\
    legend_handle_minmax = drawShadedLinesInSubplot(X, mean, mini, maxi, upper, lower, type_ax)

legend_handles = [legend_handle_mean,
                  legend_handle_lowerupper,
                  legend_handle_minmax,
                 ]
legend_labels = ['mean',
                 '95% CI',
#                 '99.999% CI',
                 'Max-Min',
                ]

fig.legend(legend_handles,
               legend_labels,
    loc="upper right",
    #fontsize="xx-small",
    fontsize="xx-large",
	ncol=1
)

'''
drawData(readDataFrom("result_data.txt"))
drawData(readDataFrom("result_minimum_distances.txt"))
'''

plt.savefig("plot_exp_01_formation_error.pdf")
plt.show()
