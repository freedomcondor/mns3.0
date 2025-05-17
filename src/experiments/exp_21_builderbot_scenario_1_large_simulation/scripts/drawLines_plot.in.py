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

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_21_builderbot_scenario_1_large_simulation"

# Process both experiment types
#--------------------------------------
experiment_types = ["no_builderbot", "builderbot"]
fig = plt.figure(figsize=(10, 8))  # Make figure taller for four subplots

for idx, exp_type in enumerate(experiment_types):
    DATADIR = ExperimentsDIR + "/" + exp_type + "/run_data"
    
    # check experiment type existence
    if not os.path.isdir(DATADIR):
        print("Data folder doesn't exist : ", DATADIR)
        print("Existing Datafolder are : ")
        for subfolder in getSubfolders(ExperimentsDIR):
            print("    " + subfolder)
        continue

    # First subplot - original data
    ax1 = fig.add_subplot(4, 1, idx*2+1)
    ax2 = ax1.twinx()

    # read data sets for first subplot
    dataSet1 = []
    dataSet2 = []
    for subfolder in getSubfolders(DATADIR):
        dataSet1.append(readDataFrom(subfolder + "start_push_size.dat"))
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

    # Second subplot - new data
    ax3 = fig.add_subplot(4, 1, idx*2+2)
    ax4 = ax3.twinx()

    # read data sets for second subplot
    dataSet3 = []
    dataSet4 = []
    for subfolder in getSubfolders(DATADIR):
        dataSet3.append(readDataFrom(subfolder + "result_data.txt"))
        dataSet4.append(readDataFrom(subfolder + "SoNSSize.dat"))

    #----- data3 -----
    stepsData3, X3 = transferTimeDataToRunSetData(dataSet3)
    mean3, mini3, maxi3, upper3, lower3 = calcMeanFromStepsData(stepsData3)
    X3 = [i / step_time_scalar for i in X3]
    drawShadedLinesInSubplot(X3, mean3, maxi3, mini3, upper3, lower3, ax4, {'color':'red'})  # Changed to ax4 and red

    #----- data4 -----
    stepsData4, X4 = transferTimeDataToRunSetData(dataSet4)
    mean4, mini4, maxi4, upper4, lower4 = calcMeanFromStepsData(stepsData4)
    X4 = [i / step_time_scalar for i in X4]
    drawShadedLinesInSubplot(X4, mean4, maxi4, mini4, upper4, lower4, ax3, {'color':'blue'})  # Changed to ax3 and blue

    # Set labels for both subplots
    ax1.set_xlabel('Time(s)')
    ax3.set_xlabel('Time(s)')
    
    # Set limits
    ax1.set_ylim([-1,200])
    ax3.set_ylim([-1,20])
    ax4.set_ylim([-1,5])
    
    # Set y axis positions
    ax4.yaxis.set_ticks_position('left')     # Move to left side
    ax4.yaxis.set_label_position('left')
    ax3.yaxis.set_ticks_position('right')    # Move to right side
    ax3.yaxis.set_label_position('right')
    
    # Set colors
    ax1.tick_params(axis='y', labelcolor='red')
    ax2.tick_params(axis='y', labelcolor='blue')
    ax4.tick_params(axis='y', labelcolor='red')    # Changed from ax3
    ax3.tick_params(axis='y', labelcolor='blue')   # Changed from ax4

    # Add titles
    ax1.set_title(f'Experiment Type: {exp_type} - Push Size vs Learner Length')
    ax3.set_title(f'Experiment Type: {exp_type} - Result Data vs SoNS Size')

# Add shared y-axis labels
fig.text(0.04, 0.5, 'Code Transfer Amount / SoNS Size', va='center', ha='center', rotation='vertical', color='red')
fig.text(0.96, 0.5, 'Robot Number in Pushing State / Result Data', va='center', ha='center', rotation='vertical', color='blue')

plt.tight_layout()
#plt.show()
plt.savefig("exp21_plot_combined.pdf")
