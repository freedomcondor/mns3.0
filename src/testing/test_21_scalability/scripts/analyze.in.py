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
def readMemFromLine_linux(line, total_mem) :
	memstr = line.split()[9] # %
	return float(memstr) * 0.01 * total_mem

def readMemFromLine_mac(line, total_mem) :
	memstr = line.split()[7]
	memstr = memstr.replace("K", "E-06")
	memstr = memstr.replace("M", "E-03")
	memstr = memstr.replace("G", "E+00")

	return float(memstr)

readMemFromLine = readMemFromLine_linux

'''
mac = "@CMAKE_APPLE_FLAG@"
if mac == "true" :
	readMemFromLine = readMemFromLine_mac
'''

def readDataFile(fileName) :
	file = open(fileName,"r")

	step = []
	mem = []
	time = []

	total_mem = 0

	idx = "total_mem"
	for line in file :
		#--- start     ----
		if idx == "total_mem" :
			if line.split()[0] == "MemTotal:" :
				# linux
				readMemFromLine = readMemFromLine_linux
				total_mem = float(line.split()[1]) * 1E-06
			if line.split()[0] == "hw.memsize:" :
				# mac
				readMemFromLine = readMemFromLine_mac
				total_mem = float(line.split()[1]) * 1E-09
			idx = "init"
			continue
		if idx == "init" :
			# read the title line
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
			mem.append(readMemFromLine(line, total_mem))
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
def slide(A,B,C,D,X) :
	A_res = []
	B_res = []
	C_res = []
	D_res = []

	index_dict = {}
	total = 0
	for i in range(0, len(X)) :
		if str(X[i]) not in index_dict :
			index_dict[str(X[i])] = total
			total = total + 1
			A_res.append([])
			B_res.append([])
			C_res.append([])
			D_res.append([])

		idx = index_dict[str(X[i])]
		A_res[idx].append(A[i])
		B_res[idx].append(B[i])
		C_res[idx].append(C[i])
		D_res[idx].append(D[i])

	return A_res, B_res, C_res, D_res

#----------------------------------------------------------------
#dataFolder = "scalability_test"
#dataFolder = "scalability_test_officePC"
dataFolder = "scalability_test_m5zn6xlarge"
dataFile = "record.dat"

tests = []
steps = []
times = []
mems = []

testCases = []
for subFolder in getSubfolders(dataFolder) :
	testCases.append(int(subFolder))
testCases.sort()

for subFolder in testCases :
	subFolderDataFile = dataFolder + "/" + str(subFolder) + "/" + dataFile
	step, mem, time = readDataFile(subFolderDataFile)

	for i in range(0, len(step)) :
		if i < len(time) and i < len(mem) :
			tests.append(int(subFolder))
			steps.append(step[i])
			times.append(time[i])
			mems.append(mem[i])

tests_slide_test, steps_slide_test, times_slide_test, mems_slide_test = slide(tests, steps, times, mems, tests)
tests_slide_step, steps_slide_step, times_slide_step, mems_slide_step = slide(tests, steps, times, mems, steps)

#----------------------------------------------------------------
fig = plt.figure()

ax1 = fig.add_subplot(1, 2, 1, projection='3d')
ax2 = fig.add_subplot(1, 2, 2, projection='3d')

#ax1.scatter3D(tests, steps, times, c=times, cmap='viridis')
#ax2.scatter3D(tests, steps, mems, c=mems, cmap='viridis')

for i in range(0, len(tests_slide_test)) :
	ax1.plot(tests_slide_test[i], steps_slide_test[i], times_slide_test[i])
	ax2.plot(tests_slide_test[i], steps_slide_test[i], mems_slide_test[i])

for i in range(0, len(tests_slide_step)) :
	ax1.plot(tests_slide_step[i], steps_slide_step[i], times_slide_step[i])
	ax2.plot(tests_slide_step[i], steps_slide_step[i], mems_slide_step[i])

ax1.set_title("time per step")
ax1.set_xlabel("swarm scale")
ax1.set_ylabel("steps")
ax1.set_zlabel("time(s)")

ax2.set_title("memory")
ax2.set_xlabel("swarm scale")
ax2.set_ylabel("steps")
ax2.set_zlabel("mem(G)")

plt.show()