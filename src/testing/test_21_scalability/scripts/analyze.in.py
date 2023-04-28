import matplotlib.pyplot as plt
import numpy as np
import os

#----------------------------------------------------------------
def getSubfolders(data_dir) :
	# get the self folder item of os.walk
	walk_dir_item=[]
	for folder in os.walk(data_dir) :
		if folder[0] == data_dir :
			walk_dir_item=folder
			break

	# iterate subdir
	subfolders=[]
	for subfolder in walk_dir_item[1] :
		#rundir = walk_dir_item[0] + "/" + subfolder + "/"
		#subfolders.append(rundir)
		subfolders.append(subfolder)
	
	return subfolders

#----------------------------------------------------------------
def readMemFromLine_linux(line) :
	return 1

def readMemFromLine_mac(line) :
	memstr = line.split()[7]
	memstr = memstr.replace("K", "E-06")
	memstr = memstr.replace("M", "E-03")
	memstr = memstr.replace("G", "E+00")

	return float(memstr)

readMemFromLine = readMemFromLine_linux
mac = "@CMAKE_APPLE_FLAG@"
if mac == "true" :
	readMemFromLine = readMemFromLine_mac

def readDataFile(fileName) :
	file = open(fileName,"r")

	step = []
	mem = []
	time = []

	idx = "init"
	for line in file :
		#--- start     ----
		if idx == "init" :
			idx = "init_time"
			continue
		#--- init time ----
		if idx == "init_time" :
			lastTime = float(line)
			idx = "step"
			continue
		#--- step block: step ---
		if idx == "step" :
			step.append(int(line))
			idx = "mem"
			continue
		#--- step block: mem ---
		if idx == "mem" :
			mem.append(readMemFromLine(line))
			idx = "time"
			continue
		#--- step block: time ---
		if idx == "time" :
			time5step = float(line) - lastTime
			time.append(time5step / 5)
			lastTime = float(line)
			idx = "step"
			continue

	file.close()
	return step, mem, time

#----------------------------------------------------------------
dataFolder = "scalability_test"
dataFile = "record.dat"

tests = []
steps = []
times = []
mems = []

testCases = []
for subFolder in getSubfolders(dataFolder) :
	subFolderDataFile = dataFolder + "/" + subFolder + "/" + dataFile
	step, mem, time = readDataFile(subFolderDataFile)

	for i in range(0, len(step)) :
		if i < len(time) and i < len(mem) :
			tests.append(int(subFolder))
			steps.append(step[i])
			times.append(time[i])
			mems.append(mem[i])

#----------------------------------------------------------------
fig = plt.figure()

ax1 = fig.add_subplot(1, 2, 1, projection='3d')
ax2 = fig.add_subplot(1, 2, 2, projection='3d')

ax1.scatter3D(tests, steps, times, c=times, cmap='viridis')
ax2.scatter3D(tests, steps, mems, c=mems, cmap='viridis')

ax1.set_title("time per step")
ax1.set_xlabel("swarm scale")
ax1.set_ylabel("steps")
ax1.set_zlabel("time(s)")

ax2.set_title("memory")
ax2.set_xlabel("swarm scale")
ax2.set_ylabel("steps")
ax2.set_zlabel("mem(G)")

plt.show()