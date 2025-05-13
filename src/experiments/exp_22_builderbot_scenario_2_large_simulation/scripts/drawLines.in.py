drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

# Get experiment type
#--------------------------------------
usage="[usage] example: python3 xxx.py -t no_builderbot"
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
    Experiment_type = "no_builderbot"
    print("Experiment_type not provided: using default", Experiment_type)

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_22_builderbot_scenario_2_large_simulation"
DATADIR = ExperimentsDIR + "/" + Experiment_type + "/run_data"

# check experiment type existence
#--------------------------------------
if not os.path.isdir(DATADIR) :
    print("Data folder doesn't exist : ", DATADIR)
    print("Existing Datafolder are : ")
    for subfolder in getSubfolders(ExperimentsDIR) :
        print("    " + subfolder)
    exit()

# create figure and ax
#--------------------------------------
fig = plt.figure()
ax1 = fig.add_subplot(1,1,1)
ax2 = ax1.twinx()  # create a second y-axis

# read data sets
#--------------------------------------
dataSet1 = []
dataSet2 = []
for subfolder in getSubfolders(DATADIR) :
    dataSet1.append(readDataFrom(subfolder + "result_push_size.dat"))
    dataSet2.append(readDataFrom(subfolder + "learner_length.dat"))

step_time_scalar = 5
#----- data1 -----
stepsData1, X1 = transferTimeDataToRunSetData(dataSet1)
mean1, mini1, maxi1, upper1, lower1 = calcMeanFromStepsData(stepsData1)
X1 = [i / step_time_scalar for i in X1]
drawShadedLinesInSubplot(X1, mean1, maxi1, mini1, upper1, lower1, ax2, {'color':'blue'})

#----- data2 -----
stepsData2, X2 = transferTimeDataToRunSetData(dataSet2)
mean2, mini2, maxi2, upper2, lower2 = calcMeanFromStepsData(stepsData2)
X2 = [i / step_time_scalar for i in X2]
drawShadedLinesInSubplot(X2, mean2, maxi2, mini2, upper2, lower2, ax1, {'color':'red'})

# 设置标签和图例
ax1.set_xlabel('Time')
ax1.set_ylabel('Learner Length', color='red')
ax2.set_ylabel('Push Size', color='blue')

# set ax2 limit
ax1.set_ylim([-1,1000])

# 设置刻度颜色
ax1.tick_params(axis='y', labelcolor='red')
ax2.tick_params(axis='y', labelcolor='blue')

plt.show()
#plt.savefig("exp21_plot_" + Experiment_type + ".pdf")
