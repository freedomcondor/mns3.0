drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

# start to draw
#--------------------------------------
fig = plt.figure()
rows = 4
cols = 1

ax_SoNS_number = fig.add_subplot(rows,cols,1)
ax_SoNS_number.set_xlabel("time(step)")
ax_SoNS_number.set_ylabel("SoNS Number")

#ax_SoNS_number.set_ylim([-0.7, 13])
data_SoNS_number = readDataFrom("SoNSNumber.dat")
drawDataInSubplot(data_SoNS_number, ax_SoNS_number)
data_SoNS_size = readDataFrom("SoNSSize.dat")
drawDataInSubplot(data_SoNS_size, ax_SoNS_number)

#--------------------------------------------
ax_state = fig.add_subplot(rows,cols,2)
ax_state.set_xlabel("time(step)")
ax_state.set_ylabel("Robot Number in Different States")

state1 = readDataFrom("result_wait_to_forward_size.dat")
drawDataInSubplot(state1, ax_state)
state2 = readDataFrom("result_forward_size.dat")
drawDataInSubplot(state2, ax_state)
state3 = readDataFrom("result_wait_to_forward_2_size.dat")
drawDataInSubplot(state3, ax_state)
state4 = readDataFrom("result_forward_2_size.dat")
drawDataInSubplot(state4, ax_state)
state5 = readDataFrom("result_wait_for_obstacle_clearance_size.dat")
drawDataInSubplot(state5, ax_state)
state6 = readDataFrom("result_push_size.dat")
drawDataInSubplot(state6, ax_state)

#--------------------------------------------
ax_recruit = fig.add_subplot(rows,cols,3)
ax_recruit.set_xlabel("time(step)")
ax_recruit.set_ylabel("Robot Number in recruitment")

recruit_data = transposeData(readVecFrom("recruit.dat"))
drawDataInSubplot(recruit_data[0], ax_recruit)
drawDataInSubplot(recruit_data[1], ax_recruit)
drawDataInSubplot(recruit_data[2], ax_recruit)

#--------------------------------------------
ax_learner = fig.add_subplot(rows,cols,4)
ax_learner.set_xlabel("time(step)")
ax_learner.set_ylabel("Leaner Length")

drawDataInSubplot(readDataFrom("learner_length.dat"), ax_learner)

#--------------------------------------------
plt.show()
#plt.savefig("exp_11_plot_" + Experiment_type + ".pdf")
