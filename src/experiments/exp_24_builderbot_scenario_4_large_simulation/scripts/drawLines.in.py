drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

# start to draw
#--------------------------------------
fig = plt.figure()

# joystick data
#--------------------------------------
ax_joystick = fig.add_subplot(2,1,1)
ax_joystick.set_xlabel("time(step)")
ax_joystick.set_ylabel("Joystick input")

#ax_joystick.set_ylim([-0.7, 13])
joystick_data = transposeData(readMatrixDataFrom("joystick.log"))
drawDataInSubplot(joystick_data[0], ax_joystick)
drawDataInSubplot(joystick_data[1], ax_joystick)
drawDataInSubplot(joystick_data[2], ax_joystick)

# average velocity data
#--------------------------------------
ax_joystick = fig.add_subplot(2,1,2)
ax_joystick.set_xlabel("time(step)")
ax_joystick.set_ylabel("Average Velocity")

#ax_joystick.set_ylim([-0.7, 13])
average_velocity_data = transposeData(readVecFrom("average_velocity.log"))
drawDataInSubplot(average_velocity_data[0], ax_joystick)
drawDataInSubplot(average_velocity_data[1], ax_joystick)
drawDataInSubplot(average_velocity_data[2], ax_joystick)

#--------------------------------------------
plt.show()
#plt.savefig("exp_11_plot_" + Experiment_type + ".pdf")
