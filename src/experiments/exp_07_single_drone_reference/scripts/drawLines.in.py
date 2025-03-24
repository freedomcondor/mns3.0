drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os
import numpy
import seaborn as sns
import statistics

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
fig, (ax_main, ax_violin1, ax_violin2) = plt.subplots(1, 3, figsize=(20, 5), gridspec_kw={'width_ratios': [6, 1, 1]})
#ax_main.set_ylim([-1,23])

# read data sets
#--------------------------------------

hoveringData = []
movingData = []
totalStepsData = []

for subfolder in getSubfolders(DATADIR) :
    #if subfolder != "/home/harry/code/mns3.0/src/../../mns3.0-3Ddrone-data/exp_07_acceleration/discrete/run_data/run2/" :
    #    continue

    # for each run
    print("loading ", subfolder)

    # read total error
    #drawDataInSubplot(readDataFrom(subfolder + "result_local_errors.txt"), ax_main)

    robotsData = []
    # load from eachRobotGoalError
    for subfile in getSubfiles(subfolder + "result_eachRobotGoalError") :
        robotData = readDataFrom(subfile)
        #drawDataInSubplot(robotData, ax_main)
        robotsData.append(robotData)

        if robotData[1275] > 1.0 :
            print("wrong case : ", subfolder)

    # convert into step data
    stepData, positions = transferTimeDataToBoxData(robotsData, step_length = 1, interval_steps = False)
        # stepData[0] has all the robots data in step 1

    if len(totalStepsData) == 0 :
        totalStepsData = stepData
    else :
        for i in range(len(totalStepsData)) :
            totalStepsData[i] = totalStepsData[i] + stepData[i]
    
    # read key steps
    switchSteps = readDataFrom(subfolder + "switchSteps.dat")
    switchSteps = [int(step) for step in switchSteps]
    # switch Steps[0] enter hovering
    # switch Steps[1] hovering over, start acc

    # read hover data
    for i in range(switchSteps[1] - 200, switchSteps[1]) :
        hoveringData = hoveringData + stepData[i]

    legend_handle_red_line = ax_main.axvline(x=switchSteps[1] - 200, color='red', linestyle='--', label='Hover Start')
    legend_handle_red_line = ax_main.axvline(x=switchSteps[1], color='red', linestyle='--', label='Hover End')

    # read moving data for discrete
    if Experiment_type == "discrete" :
        #for k in range(2, len(switchSteps)) :
        for k in range(2, 6) :
            for i in range(switchSteps[k] - 50, switchSteps[k]) :
                movingData = movingData + stepData[i]

            legend_handle_green_line = ax_main.axvline(x=switchSteps[k] - 50, color='green', linestyle='--', label='Move Start ' + str(k))
            legend_handle_green_line = ax_main.axvline(x=switchSteps[k], color='green', linestyle='--', label='Move End ' + str(k))

    # read moving data for continuous
    if Experiment_type == "continuous" :
        #for i in range(switchSteps[1] + 1, len(stepData)) :
        #switch Steps[2] reach 4m/s
        for i in range(switchSteps[1] + 1, switchSteps[2]) :
            movingData = movingData + stepData[i]

        legend_handle_green_line = ax_main.axvline(x=switchSteps[1] + 10, color='green', linestyle='--', label='Move Start')
        legend_handle_green_line = ax_main.axvline(x=switchSteps[2], color='green', linestyle='--', label='Move End')

#- draw main ax ---------------------------------------------------------------
X=[]
for i in range(0, len(positions)) :
    X.append(i)

mean = []
upper = []
lower = []
mini = []
maxi = []
mask_min = 0

for stepData in totalStepsData :
    meanvalue = statistics.mean(stepData)
    stdev = statistics.stdev(stepData)

    minvalue = min(stepData)
    maxvalue = max(stepData)
    mean.append(meanvalue)
    count = len(stepData)
    interval95 = 1.96 * stdev / math.sqrt(count)
    #interval999 = 3.291 * stdev / math.sqrt(count)
    interval99999 = 4.417 * stdev / math.sqrt(count)

    upper.append(meanvalue + interval95)
    lower.append(meanvalue - interval95)
    mini.append(meanvalue - interval99999)
    maxi.append(meanvalue + interval99999)

#drawDataWithXInSubplot(positions, mean, axs[0], 'royalblue')
#drawDataWithXInSubplot(X, mean, ax_main, 'royalblue')
legend_handle_mean, = drawDataWithXInSubplot(X, mean, ax_main, 'b')
legend_handle_minmax = ax_main.fill_between(
    #positions, mini, maxi, color='b', alpha=.10)
    X, mini, maxi, color='b', alpha=.10)
legend_handle_lowerupper = ax_main.fill_between(
    #positions, lower, upper, color='b', alpha=.30)
    X, lower, upper, color='b', alpha=.30)

legend_handles = [legend_handle_mean,
                    legend_handle_lowerupper,
                    legend_handle_minmax]
legend_labels = ['mean',
                    '95% CI',
                    '99.999% CI']
legend_columns = 1
if legend_handle_red_line != None :
    legend_handles.append(legend_handle_red_line)
    legend_labels.append('hover period')
    legend_columns = 2
if legend_handle_green_line != None :
    legend_handles.append(legend_handle_green_line)
    legend_labels.append('moving peiods')

ax_main.legend(legend_handles,
                legend_labels,
    loc="upper right",
    fontsize="large",
    ncol=legend_columns
)

# Set y-axis limits for main plot
ax_main.set_ylim(0, 100)

# Add titles for x and y axes
ax_main.set_xlabel('Time(s)', fontsize=14)  # Set your desired title for the x-axis
ax_main.set_ylabel('Errors(m)', fontsize=14)  # Set your desired title for the y-axis

# Set x-ticks and labels
ax_main.set_xticks(     [0, 500, 1000, 1500, 2000, 2500])  # Set the positions of the ticks
ax_main.set_xticklabels([0, 100,  200,  300,  400,  500])  # Set the corresponding labels

#- draw violin plots ---------------------------------------------------------------
maxData = max(max(hoveringData), max(movingData)) if movingData else max(hoveringData)
# Draw violin plot for hoveringData
sns.violinplot(ax=ax_violin1, data=hoveringData, color='red')
ax_violin1.set_title('Hovering Data Distribution')
ax_violin1.set_ylabel('Errors(m)', fontsize=14)  # Set your desired title for the y-axis
ax_violin1.set_ylim(0, maxData)  # Set y-limits to match the other violin plot

# Draw violin plot for movingData
sns.violinplot(ax=ax_violin2, data=movingData, color='green')
ax_violin2.set_title('Moving Data Distribution')
ax_violin2.set_ylabel('Errors(m)', fontsize=14)  # Set your desired title for the y-axis
ax_violin2.set_ylim(0, maxData)  # Set y-limits to match the other violin plot

plt.savefig("exp07_single_drone_reference_plot_" + Experiment_type + ".pdf")
plt.show()
