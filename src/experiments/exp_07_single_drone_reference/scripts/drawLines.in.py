drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os
import numpy
import seaborn as sns

# Get experiment type
#--------------------------------------
usage="[usage] example: python3 xxx.py -t discrete"
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
    Experiment_type = "discrete"
    print("Experiment_type not provided: using default", Experiment_type)

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_07_single_drone_reference"
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
fig, (ax_main, ax_violin1, ax_violin2) = plt.subplots(1, 3, gridspec_kw={'width_ratios': [2, 1, 1]})
#ax_main.set_ylim([-1,23])

# read data sets
#--------------------------------------

hoveringData = []
movingData = []

for subfolder in getSubfolders(DATADIR) :
    #if subfolder != "/home/harry/code/mns3.0/src/../../mns3.0-3Ddrone-data/exp_07_acceleration/discrete/run_data/run2/" :
    #    continue

    # for each run
    print("loading ", subfolder)

    # read total error
    drawDataInSubplot(readDataFrom(subfolder + "result_local_errors.txt"), ax_main)

    robotsData = []
    # load from eachRobotGoalError
    for subfile in getSubfiles(subfolder + "result_eachRobotGoalError") :
        robotData = readDataFrom(subfile)
        drawDataInSubplot(robotData, ax_main)
        robotsData.append(robotData)
    # convert into step data
    stepData, positions = transferTimeDataToBoxData(robotsData, step_length = 1, interval_steps = False)
        # stepData[0] has all the robots data in step 1
    
    # read key steps
    switchSteps = readDataFrom(subfolder + "switchSteps.dat")
    switchSteps = [int(step) for step in switchSteps]
    # switch Steps[0] enter hovering
    # switch Steps[1] hovering over, start acc

    # read hover data
    for i in range(switchSteps[1] - 50, switchSteps[1]) :
        hoveringData = hoveringData + stepData[i]

    #ax_main.axvline(x=switchSteps[1] - 50, color='red', linestyle='--', label='Hover Start')
    #ax_main.axvline(x=switchSteps[1], color='red', linestyle='--', label='Hover End')

    # read moving data for discrete
    if Experiment_type == "discrete" :
        #for k in range(2, len(switchSteps)) :
        for k in range(2, 5) :
            for i in range(switchSteps[k] - 50, switchSteps[k]) :
                movingData = movingData + stepData[i]

                #ax_main.axvline(x=switchSteps[k] - 50, color='green', linestyle='--', label='Move Start ' + str(k))
                #ax_main.axvline(x=switchSteps[k], color='green', linestyle='--', label='Move End ' + str(k))

    # read moving data for continuous
    if Experiment_type == "continuous" :
        #for i in range(switchSteps[1] + 1, len(stepData)) :
        #switch Steps[2] reach 4m/s
        for i in range(switchSteps[1] + 1, switchSteps[2]) :
            movingData = movingData + stepData[i]

maxData = max(max(hoveringData), max(movingData)) if movingData else max(hoveringData)
# Draw violin plot for hoveringData
sns.violinplot(ax=ax_violin1, data=hoveringData, color='red')
ax_violin1.set_title('Hovering Data Distribution')
ax_violin1.set_ylabel('Error')
ax_violin1.set_ylim(0, maxData)  # Set y-limits to match the other violin plot

# Draw violin plot for movingData
sns.violinplot(ax=ax_violin2, data=movingData, color='green')
ax_violin2.set_title('Moving Data Distribution')
ax_violin2.set_ylabel('Error')
ax_violin2.set_ylim(0, maxData)  # Set y-limits to match the other violin plot

plt.show()
#plt.savefig("exp07_plot_" + Experiment_type + ".pdf")
