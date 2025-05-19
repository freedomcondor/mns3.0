drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

#ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_23_builderbot_scenario_3_large_simulation_backup"
ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_23_builderbot_scenario_3_large_simulation"

fig = plt.figure(figsize=(10, 4))  # Make figure taller for four subplots

DATADIR = ExperimentsDIR + "/run_data"

def readAndDraw(filename, ax, color, step_time_scalar=5):
    # read data sets
    dataSet = []
    for subfolder in getSubfolders(DATADIR):
        dataSet.append(readDataFrom(subfolder + filename))
    
    # process and draw data
    stepsData, X = transferTimeDataToRunSetData(dataSet)
    mean, mini, maxi, upper, lower = calcMeanFromStepsData(stepsData)
    X = [i / step_time_scalar for i in X]
    drawShadedLinesInSubplot(X, mean, maxi, mini, upper, lower, ax, {'color':color})

# First subplot - original data
ax1 = fig.add_subplot(2, 1, 1)
ax2 = fig.add_subplot(2, 1, 2)

# read and draw all datasets
readAndDraw("result_forward_size.dat", ax1, 'yellow')
readAndDraw("result_meet_obstacle_size.dat", ax1, 'orange')
readAndDraw("result_send_help_size.dat", ax1, 'green')
readAndDraw("result_wait_to_help_size.dat", ax1, 'red')
readAndDraw("result_helping_size.dat", ax1, 'blue')
readAndDraw("result_move_left_size.dat", ax1, 'red')
readAndDraw("result_forward_2_size.dat", ax1, 'green')
readAndDraw("learner_length.dat", ax2, 'blue')

plt.tight_layout()
#plt.show()
plt.savefig("exp23_plot_combined.pdf")
