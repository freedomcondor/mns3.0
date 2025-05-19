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

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_24_builderbot_scenario_4_large_simulation"

# Process both experiment types
#--------------------------------------
experiment_types = [
    "joystick_record_1.dat",
#    "joystick_record_2.dat",
#    "joystick_record_3.dat",
#    "joystick_record_4.dat",
#    "joystick_record_5.dat",
]

def Draw(dataSet, ax, color, step_time_scalar):
    # process and draw data
    stepsData, X = transferTimeDataToRunSetData(dataSet)
    mean, mini, maxi, upper, lower = calcMeanFromStepsData(stepsData)
    X = [i / step_time_scalar for i in X]
    drawShadedLinesInSubplot(X, mean, maxi, mini, upper, lower, ax, {'color':color})

fig = plt.figure(figsize=(10, 3))  # Make figure taller for four subplots

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
    ax1 = fig.add_subplot(len(experiment_types)*2, 1, idx*2+1)
    ax2 = fig.add_subplot(len(experiment_types)*2, 1, idx*2+2)

    # read data sets for first subplot
    dataSet1X = []
    dataSet1Y = []
    dataSet1Z = []
    dataSet2X = []
    dataSet2Y = []
    dataSet2Z = []
    for subfolder in getSubfolders(DATADIR):
        joystick_input = readVecFrom(subfolder + "joystick.log")
        inputX = []
        inputY = []
        inputZ = []
        for data in joystick_input:
            inputX.append(data[0])
            inputY.append(data[1])
            inputZ.append(data[2])
        dataSet1X.append(inputX)
        dataSet1Y.append(inputY)
        dataSet1Z.append(inputZ)
        velocity_output = readVecFrom(subfolder + "average_velocity.log")
        outputX = []
        outputY = []
        outputZ = []
        for data in velocity_output:
            outputX.append(data[0])
            outputY.append(data[1])
            outputZ.append(data[2])
        dataSet2X.append(outputX)
        dataSet2Y.append(outputY)
        dataSet2Z.append(outputZ)

    step_time_scalar = 5
    Draw(dataSet1X, ax1, "blue", step_time_scalar)
    Draw(dataSet1Y, ax1, "red", step_time_scalar)
    Draw(dataSet1Z, ax1, "green", step_time_scalar)
    
    # Set y-axis ticks for ax1
    ax1.set_ylim(-32767, 32767)
    ax1.set_yticks([-32767, 0, 32767])

    Draw(dataSet2X, ax2, "blue", step_time_scalar)
    Draw(dataSet2Y, ax2, "red", step_time_scalar)
    Draw(dataSet2Z, ax2, "green", step_time_scalar)


plt.tight_layout()
#plt.show()
plt.savefig("exp24_plot_combined.pdf")
