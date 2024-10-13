# This file is for plotting experiment results data.

import matplotlib.pyplot as plt
import numpy as np
import os
import statistics
import math

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

def readMatrixDataFrom(fileName) :
	file = open(fileName,"r")
	data = []
	for line in file :
		lineList = line.strip().split(",")
		stepData = []
		for col in lineList :
			stepData.append(float(col))
		data.append(stepData)
	file.close()
	return data

def readVecFrom(fileName) :
	file = open(fileName,"r")
	data = []
	for line in file :
		lineList = line.strip().strip("()").split(",")
		stepData = []
		stepData.append(float(lineList[0]))
		stepData.append(float(lineList[1]))
		stepData.append(float(lineList[2]))
		data.append(stepData)
	file.close()
	return data

def transposeData(data) :
	transposeData = []
	for i in range(0, len(data[0])) :
		transposeData.append([])
		for j in range(0, len(data)) :
			transposeData[i].append(data[j][i])
	return transposeData

#----------------------------------------------------------------------------------------------
# Takes and array of data, and draw in python matplot
def drawData(data, color = None) :
	if color == None:
		return plt.plot(data)
	else:
		return plt.plot(data, color=color)

def drawRibbonDataInSubplot(data, subplot, option = {}) :
	# parameters
	color = 'b'
	if 'color' in option :
		color = option['color']

	width = 5
	if 'width' in option :
		width = option['width']

	dataStart = 0
	if 'dataStart' in option :
		dataStart = option['dataStart']

	ribbonStart = 0
	if 'ribbonStart' in option :
		ribbonStart = option['ribbonStart']

	alpha = 0.3
	if 'alpha' in option :
		alpha = option['alpha']

	dataLineOffset = width
	if 'dataLineOffset' in option :
		dataLineOffset = option['dataLineOffset']

	X1D = np.arange(0, width, 0.25)
	if 'leading' in option :
		Y1D = range(0, len(data)+1)
	else :
		Y1D = range(1, len(data)+1)

	X, Y = np.meshgrid(X1D, Y1D)

	Z = np.zeros((len(Y), len(Y[1])))
	for i in range(0, len(Y)) :
		for j in range(0, len(Y[i])) :
			if Y[i][j] == 0 :
				Z[i][j] = option['leading']
			else :
				Z[i][j] = data[Y[i][j] - 1]
			Y[i][j] += dataStart
			X[i][j] += ribbonStart

	const1D = []
	data1D = []
	if 'leading' in option :
		data1D.append(option['leading'])
	for i in range(0, len(data)) :
		data1D.append(data[i])

	for i in range(0, len(Y1D)) :
		const1D.append(ribbonStart+dataLineOffset)

	subplot.plot3D(const1D, Y, data1D, color=color, alpha=alpha)
	return subplot.plot_surface(X, Y, Z, color=color, alpha=alpha)

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
#     [a,b,c,d],  -- robot1's data from step1 to step 4
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

def transferTimeDataToBoxData(robotsData, step_length = 50, interval_steps = False) :
	boxdata = []
	positions = []
	robot_count = 0
	# for each robot
	for robotData in robotsData :
		box_count = 0
		# for each step of this robot
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

#----------------------------------------------------------------------------------------------
# This function re-arrange a set of line datas by time
# input:
# robotsData = [
#     [a,b,c,d],  -- run1's data from step1 to step 4
#     [e,f,g,h],  -- run2's data
#     [i,j,k,l],  -- run3's data
#     [m,n,o,p],  -- run4's data
#     ...
# ]

# output:
# boxdata = [
#      [a,e,i,m]  -- all the runs data at step 1
#      [b,f,j,n]  -- all the runs data at step 2 (<step_length>)
#      [c,g,k,o]  -- all the runs data at step 3
#      [d,h,l,p]  -- all the runs data at step 4
#      ....
# ]
def transferTimeDataToRunSetData(runsData, step_length = 1, interval_steps = False) :
	stepsdata = []
	positions = []
	# for each run
	for runData in runsData :
		step_count = 0
		# for each step of this run
		for i in range(0, len(runData)) :
			# if a right step by step_length
			if i % step_length == 0 :
				if len(stepsdata) <= step_count:
					stepsdata.append([])
					positions.append(i)
				stepsdata[step_count].append(runData[i])
				step_count = step_count + 1
			# if count interval steps
			if interval_steps == True:
				stepsdata[step_count-1].append(runData[i])

	return stepsdata, positions

#----------------------------------------------------------------------------------------------
# This function calculates mean, max, min, confidence interval from a stepsData
# input: stepsData =
#      [a,e,i,m]  -- all the runs data at step 1
#      [b,f,j,n]  -- all the runs data at step 2 (<step_length>)
#      [c,g,k,o]  -- all the runs data at step 3
#      [d,h,l,p]  -- all the runs data at step 4
# output:
#      mean = [q,w,e,r]   mean at step 1,2,3,4
#      upper= [q,w,e,r]   upper of confidence interval 95%
#      lower= [q,w,e,r]   lower of confidence interval 95%
#      min  = [q,w,e,r]   min at step 1,2,3,4
#      max  = [q,w,e,r]   max at step 1,2,3,4
#      or min max could be CI 99.999%
def calcMeanFromStepsData(stepsData) :
	mean = []
	upper = []
	lower = []
	mini = []
	maxi = []

	for stepData in stepsData :
		if len(stepData) == 1 :
			mean.append(stepData[0])
			upper.append(stepData[0])
			lower.append(stepData[0])
			mini.append(stepData[0])
			maxi.append(stepData[0])
			continue

		meanvalue = statistics.mean(stepData)
		minvalue = min(stepData)
		maxvalue = max(stepData)

		stdev = statistics.stdev(stepData)
		count = len(stepData)
		interval95 = 1.96 * stdev / math.sqrt(count)
		#interval999 = 3.291 * stdev / math.sqrt(count)
		interval99999 = 4.417 * stdev / math.sqrt(count)

		mean.append(meanvalue)
		upper.append(meanvalue + interval95)
		lower.append(meanvalue - interval95)
		mini.append(minvalue)
		maxi.append(maxvalue)
		'''
		upper.append(meanvalue + interval95)
		lower.append(meanvalue - interval95)
		mini.append(meanvalue - interval99999)
		maxi.append(meanvalue + interval99999)
		'''

	return mean, mini, maxi, upper, lower

#----------------------------------------------------------------------------------------------
# This function draw shaded lines: darker between upper and lower, lighter between mini, maxi
# input: X,       : x-positions,
#        mean, maxi, mini, upper, lower
#        subplot  : index of subplot
def drawShadedLinesInSubplot(X, mean, maxi, mini, upper, lower, subplot, option={}) :
	# check options
	color='blue'
	if 'color' in option:
		color = option['color']
	startPosition = 0
	if 'startPosition' in option:
		startPosition = option['startPosition']
	leading = None
	if 'leading' in option:
		leading = option['leading']

	# offset start position
	X_with_offset = []
	for i in X:
		X_with_offset.append(i + startPosition)

	# check leading
	if leading != None :
		X_with_offset.insert(0, startPosition-1)
		mean.insert(0, leading)
		maxi.insert(0, leading)
		mini.insert(0, leading)
		upper.insert(0, leading)
		lower.insert(0, leading)


	legend_handle_mean, = drawDataWithXInSubplot(X_with_offset, mean, subplot, color)
	legend_handle_minmax = subplot.fill_between(
		X_with_offset, mini, maxi, color=color, alpha=.10)
	legend_handle_lowerupper = subplot.fill_between(
		X_with_offset, lower, upper, color=color, alpha=.30)
	return legend_handle_mean, legend_handle_minmax, legend_handle_lowerupper


#----------------------------------------------------------------------------------------------
def fill_between_3d(X, upper, lower, subplot, option) :
	alpha = 0.5
	if 'alpha' in option :
		alpha = option['alpha']

	color = 'blue'
	if 'color' in option :
		color = option['color']

	zLocation = 0
	if 'zLocation' in option :
		zLocation = option['zLocation']

	zDirection = 'x'
	if 'zDirection' in option :
		zDirection = option['zDirection']

	xStart = 0
	if 'xStart' in option :
		xStart = option['xStart']

	vertices = []
	vertices.append([])
	for i in range(0, len(X)) :
		vertices[0].append((X[i] + xStart, upper[i]))

	for i in range(len(X)-1, 0, -1) :
		vertices[0].append((X[i] + xStart, lower[i]))

	poly = PolyCollection(vertices, facecolors=[color], alpha=alpha)
	subplot.add_collection3d(poly, zs=[zLocation], zdir=zDirection)
