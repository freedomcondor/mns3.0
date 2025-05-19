drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

#ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_23_builderbot_scenario_3_large_simulation_backup"
ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_23_builderbot_scenario_3_large_simulation"

fig = plt.figure(figsize=(10, 8))  # Make figure taller for four subplots

DATADIR = ExperimentsDIR + "/run_data"

# First subplot - original data
ax1 = fig.add_subplot(1, 1, 1)
ax2 = ax1.twinx()

# read data sets for first subplot
dataSet1 = []
dataSet2 = []
dataSet3 = []
for subfolder in getSubfolders(DATADIR):
    dataSet1.append(readDataFrom(subfolder + "result_helping_size.dat"))
    dataSet2.append(readDataFrom(subfolder + "result_move_left_size.dat"))
    dataSet3.append(readDataFrom(subfolder + "result_forward_2_size.dat"))

step_time_scalar = 5
#----- data1 -----
stepsData1, X1 = transferTimeDataToRunSetData(dataSet1)
mean1, mini1, maxi1, upper1, lower1 = calcMeanFromStepsData(stepsData1)
X1 = [i / step_time_scalar for i in X1]
drawShadedLinesInSubplot(X1, mean1, maxi1, mini1, upper1, lower1, ax1, {'color':'blue'})

#----- data2 -----
stepsData2, X2 = transferTimeDataToRunSetData(dataSet2)
mean2, mini2, maxi2, upper2, lower2 = calcMeanFromStepsData(stepsData2)
X2 = [i / step_time_scalar for i in X2]
drawShadedLinesInSubplot(X2, mean2, maxi2, mini2, upper2, lower2, ax1, {'color':'red'})

#----- data3 -----
stepsData3, X3 = transferTimeDataToRunSetData(dataSet3)
mean3, mini3, maxi3, upper3, lower3 = calcMeanFromStepsData(stepsData3)
X3 = [i / step_time_scalar for i in X3]
drawShadedLinesInSubplot(X3, mean3, maxi3, mini3, upper3, lower3, ax1, {'color':'green'})

plt.tight_layout()
plt.show()
#plt.savefig("exp22_plot_combined.pdf")
