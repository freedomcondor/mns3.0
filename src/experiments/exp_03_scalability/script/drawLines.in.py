drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

from matplotlib.collections import PolyCollection

import sys
import getopt
import os

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

# read data sets
#--------------------------------------
data1Set = []
data2lSet = []
data2rSet = []
data3Set = []

for subfolder in getSubfolders(DATADIR) :
    data1Set.append(readDataFrom(subfolder + "result_data_1.txt"))
    data2lSet.append(readDataFrom(subfolder + "result_data_2_left.txt"))
    data2rSet.append(readDataFrom(subfolder + "result_data_2_right.txt"))
    data3Set.append(readDataFrom(subfolder + "result_data_3.txt"))

# start to draw
#--------------------------------------
fig = plt.figure()

ax_main = fig.add_subplot(1,1,1)
ax_main.set_xlabel("time(s)")
ax_main.set_ylabel("error(m)")
ax_3D = fig.add_subplot(3,4,4, projection='3d')
ax_3D.set_box_aspect((1,5,2))  # set block ratio
ax_3D.set_facecolor('none')

ax_3D.set_xticks([])  # Disable xticks
ax_3D.view_init(60, -30)    # Z degree above ground    # X degree towards counterclockwise to the minus direction of X
# Hide all axis text ticks or tick labels
ax_3D.set_xticks([])
ax_3D.set_yticks([])
ax_3D.set_zticks([])

width=8
margin=1
gap = 0

step_time_scalar = 5

#----- data1 -----
data1StepsData, X = transferTimeDataToRunSetData(data1Set)
data1Mean, mini, maxi, upper, lower = calcMeanFromStepsData(data1StepsData)
drawRibbonDataInSubplot(data1Mean,     ax_3D, {'color':'blue',       'width'    :width,          'dataStart':0})
X = [i / step_time_scalar for i in X]
drawShadedLinesInSubplot(X, data1Mean, maxi, mini, upper, lower, ax_main, {'color':'blue'})

#----- data2 left -----
data2LeftStepsData, X = transferTimeDataToRunSetData(data2lSet)
data2LeftMean, mini, maxi, upper, lower = calcMeanFromStepsData(data2LeftStepsData)
drawRibbonDataInSubplot(data2LeftMean, ax_3D, {'color':'red',        'width'    :width/2-margin, 'dataStart':len(data1StepsData),     'leading':data1Mean[-1]})
X = [i / step_time_scalar for i in X]
drawShadedLinesInSubplot(X, data2LeftMean, maxi, mini, upper, lower, ax_main, {'color':'red', 'startPosition':len(data1StepsData)/step_time_scalar, 'leading':data1Mean[-1]})

#----- data2 right -----
data2RightStepsData, X = transferTimeDataToRunSetData(data2rSet)
data2RightMean, mini, maxi, upper, lower = calcMeanFromStepsData(data2RightStepsData)
drawRibbonDataInSubplot(data2RightMean, ax_3D, {'color':'green',     'width'    :width/2-margin,  'dataStart':len(data1StepsData),     'leading':data1Mean[-1],   'ribbonStart' : width/2+margin})
X = [i / step_time_scalar for i in X]
drawShadedLinesInSubplot(X, data2RightMean, maxi, mini, upper, lower, ax_main, {'color':'green', 'startPosition':len(data1StepsData)/step_time_scalar, 'leading':data1Mean[-1]})

#----- data3 -----
data3StepsData, X = transferTimeDataToRunSetData(data3Set)
data3Mean, mini, maxi, upper, lower = calcMeanFromStepsData(data3StepsData)
drawRibbonDataInSubplot(data3Mean,     ax_3D, {'color':'blue',      'width'    :width,           'dataStart':len(data1StepsData) + len(data2LeftStepsData),     'leading':min(data2RightMean[-1],data2LeftMean[-1])})
X = [i / step_time_scalar for i in X]
drawShadedLinesInSubplot(X, data3Mean, maxi, mini, upper, lower, ax_main, {'color':'blue', 'startPosition':(len(data1StepsData) + len(data2LeftStepsData))/step_time_scalar,     'leading':min(data2RightMean[-1],data2LeftMean[-1])})

plt.savefig("exp03_plot_" + Experiment_type + ".pdf")
