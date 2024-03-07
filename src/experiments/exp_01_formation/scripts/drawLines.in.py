drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

# Get experiment type
#--------------------------------------
usage="[usage] example: python3 xxx.py -t polyhedron_12"
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
    Experiment_type = "polyhedron_12"
    print("Experiment_type not provided: using default", Experiment_type)

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_01_formation"
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
ax_main = fig.add_subplot(1,1,1)
ax_main.set_ylim([-1,23])

# read data sets
#--------------------------------------
dataSet = []

for subfolder in getSubfolders(DATADIR) :
    dataSet.append(readDataFrom(subfolder + "result_data.txt"))

step_time_scalar = 5
#----- data1 -----
stepsData, X = transferTimeDataToRunSetData(dataSet)
mean, mini, maxi, upper, lower = calcMeanFromStepsData(stepsData)
X = [i / step_time_scalar for i in X]
drawShadedLinesInSubplot(X, mean, maxi, mini, upper, lower, ax_main, {'color':'blue'})

#plt.show()
plt.savefig("exp01_plot_" + Experiment_type + ".pdf")
