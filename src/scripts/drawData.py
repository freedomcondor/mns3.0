import matplotlib.pyplot as plt
import numpy as np
import os

# This file is for plotting experiment results data.

#----------------------------------------------------------------------------------------------
# This function reads data from a file
# The file is assumed to have one column of data, e.g. each line contains only one float number
# output data is an array of data
def readDataFrom(fileName) :
	file = open(fileName,"r")
	data = []
	for line in file :
		data.append(float(line))
	file.close()
	return data

# This function reads string data from a file
# The same as above, but reads a string from each line
def readStrDataFrom(fileName) :
	file = open(fileName,"r")
	data = []
	for line in file :
		data.append(line.rstrip())
	file.close()
	return data

#----------------------------------------------------------------------------------------------
# Takes and array of data, and draw in python matplot
def drawData(data, color = None) :
	if color == None:
		return plt.plot(data)
	else:
		return plt.plot(data, color=color)

# Takes and array of data, and draw in python matplot
# subplot is the ax index of the subplot
# For example :
#	fig, axs = plt.subplots(1, 2)
#	drawDataInSubplot([some data], axs[0], "blue")
def drawDataInSubplot(data, subplot, color = None) :
	return subplot.plot(data, color=color)

# The same as above, but with X positions
# For example :
#	drawDataInSubplot([1, 2, 5], [0.1, 0.2, 0.3], axs[0], "blue")
#	This will draw 0.1, 0.2, 0.3 at x positions 1, 2, 5
def drawDataWithXInSubplot(X, data, subplot, color = None) :
	return subplot.plot(X, data, color=color)

#----------------------------------------------------------------------------------------------
# This function iterates a path <data_dir> and return a list of all its subfolders
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
		rundir = walk_dir_item[0] + "/" + subfolder + "/"
		subfolders.append(rundir)
	
	return subfolders

# This function iterates a path <data_dir> and return a list of all the files in this folder
def getSubfiles(data_dir) :
	# get the self folder item of os.walk
	walk_dir_item=[]
	for folder in os.walk(data_dir) :
		if folder[0] == data_dir :
			walk_dir_item=folder
			break

	# iterate subdir
	subfiles =[]
	for subfile in walk_dir_item[2] :
		rundir = walk_dir_item[0] + "/" + subfile
		subfiles.append(rundir)
	
	return subfiles

#----------------------------------------------------------------------------------------------
# This function will generate a new list of datas from the input list of datas, by pick a data every <step_length> steps
# X is the index of the picked data
def sparceDataEveryXSteps(data, step_length) :
	X = []
	return_data = []
	for i in range(0, len(data)) :
		if i % step_length == 0 :
			X.append(i)
			return_data.append(data[i])
	return X, return_data

#----------------------------------------------------------------------------------------------
# This function re-arrange robots data by time
# input:
# robotsData = [
#     [a,b,c,d],  -- robot1's data from step1 to step 8
#     [e,f,g,h],  -- robot2's data
#     [i,j,k,l],  -- robot3's data
#     [m,n,o,p],  -- robot4's data
#     ...
# ]

# output:
# boxdata = [
#      [a,e,i,m]  -- all the robots data at step 1
#      [b,f,j,n]  -- all the robots data at step 50 (<step_length>)
#      [c,g,k,o]  -- all the robots data at step 100
#      [d,h,l,p]  -- all the robots data at step 150
#      ....
# ]

# if <interval_steps> is true, [a,e,i,m] will contain all the datas from step 1 to step 49

def transferTimeDataToBoxData(robotsData, step_number = 50, step_length = 50, interval_steps = False) :
	boxdata = []
	positions = []
	robot_count = 0
	# for each robot
	for robotData in robotsData :
		# for each step of this robot
		box_count = 0
		for i in range(0, len(robotData)) :
			# if a right step
			if i % step_length == 0 :
				#if robot_count == 0 :
				if len(boxdata) <= box_count:
					boxdata.append([])
					positions.append(i)
				boxdata[box_count].append(robotData[i])
				box_count = box_count + 1
			# if count interval steps
			if interval_steps == True:
				boxdata[box_count-1].append(robotData[i])


		robot_count = robot_count + 1

	return boxdata, positions