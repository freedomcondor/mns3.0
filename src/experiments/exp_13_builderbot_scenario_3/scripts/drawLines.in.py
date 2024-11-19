drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

# start to draw
#--------------------------------------
fig = plt.figure()

ax_SoNS_number = fig.add_subplot(4,1,1)
ax_SoNS_number.set_xlabel("time(step)")
ax_SoNS_number.set_ylabel("SoNS Number")

#ax_SoNS_number.set_ylim([-0.7, 13])
data_SoNS_number = readDataFrom("SoNSNumber.dat")
drawDataInSubplot(data_SoNS_number, ax_SoNS_number)
data_SoNS_size = readDataFrom("SoNSSize.dat")
drawDataInSubplot(data_SoNS_size, ax_SoNS_number)

#--------------------------------------------
ax_state = fig.add_subplot(4,1,2)
ax_state.set_xlabel("time(step)")
ax_state.set_ylabel("Robot Number in Different States")

result_forward_size = readDataFrom("result_forward_size.dat")
drawDataInSubplot(result_forward_size, ax_state)
result_meet_obstacle_size = readDataFrom("result_meet_obstacle_size.dat")
drawDataInSubplot(result_meet_obstacle_size, ax_state)
result_send_help_size = readDataFrom("result_send_help_size.dat")
drawDataInSubplot(result_send_help_size, ax_state)
result_wait_to_help_size = readDataFrom("result_wait_to_help_size.dat")
drawDataInSubplot(result_wait_to_help_size, ax_state)
result_helping_size = readDataFrom("result_helping_size.dat")
drawDataInSubplot(result_helping_size, ax_state)
result_move_right_size = readDataFrom("result_move_right_size.dat")
drawDataInSubplot(result_move_right_size, ax_state)
result_forward_2_size = readDataFrom("result_forward_2_size.dat")
drawDataInSubplot(result_forward_2_size, ax_state)

#--------------------------------------------
ax_recruit = fig.add_subplot(4,1,3)
ax_recruit.set_xlabel("time(step)")
ax_recruit.set_ylabel("Robot Number in recruitment")

recruit_data = transposeData(readVecFrom("recruit.dat"))
#drawDataInSubplot(recruit_data[0], ax_recruit)
drawDataInSubplot(recruit_data[1], ax_recruit)
#drawDataInSubplot(recruit_data[2], ax_recruit)

#--------------------------------------------
ax_learner = fig.add_subplot(4,1,4)
ax_learner.set_xlabel("time(step)")
ax_learner.set_ylabel("Code Transfer")

drawDataInSubplot(readDataFrom("learner_length.dat"), ax_learner)

#--------------------------------------------
plt.show()
#plt.savefig("exp_11_plot_" + Experiment_type + ".pdf")
