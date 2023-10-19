from matplotlib import cm
from matplotlib.legend_handler import HandlerTuple
import matplotlib as mpl
from svgpathtools import svg2paths
from svgpath2mpl import parse_path
import math

#from scipy.interpolate import make_interp_spline

def setAxParameters(ax, option):
	# back ground color white
	#ax.w_xaxis.pane.fill = False
	#ax.w_yaxis.pane.fill = False
	ax.w_xaxis.set_pane_color((1.0, 1.0, 1.0, 1.0))
	ax.w_yaxis.set_pane_color((1.0, 1.0, 1.0, 1.0))
	ax.w_zaxis.set_pane_color((1.0, 1.0, 1.0, 1.0))

	plt.rcParams["font.family"] = "Arial"
	label_font = "Arial Black"
	ax.set_xlabel("$x$ distance (m)", fontname=label_font)
	#ax.set_ylabel("$y$ distance (m)", rotation=0)
	ax.yaxis.set_rotate_label(False) # disable automatic rotation
	ax.set_ylabel("$y$ distance (m)", fontname=label_font, rotation=90)
	#ax.set_zlabel("z")
	ax.set_xlim(option['x_lim'])
	ax.set_ylim(option['y_lim'])
	ax.set_zlim(option['z_lim'])
	# hide xyz axis
	ax.w_zaxis.line.set_lw(0)
	ax.w_xaxis.line.set_lw(0)
	ax.w_yaxis.line.set_lw(0)

	# draw border
	ax.patch.set_edgecolor('black')  
	ax.spines['bottom'].set_color('0.5')
	ax.spines['top'].set_color('0.5')
	ax.spines['right'].set_color('0.5')
	ax.spines['left'].set_color(None)
	bottom_left  = [option['x_lim'][0], option['y_lim'][0], option['z_lim'][0]]
	bottom_right = [option['x_lim'][1], option['y_lim'][0], option['z_lim'][0]]
	top_left     = [option['x_lim'][0], option['y_lim'][1], option['z_lim'][0]]
	top_right    = [option['x_lim'][1], option['y_lim'][1], option['z_lim'][0]]
	color = 'black'
	width = 1.0
	drawVector3(ax, top_left,    top_right,    color, width)
	drawVector3(ax, top_right,   bottom_right, color, width)
	drawVector3(ax, bottom_left, bottom_right, color, width)
	drawVector3(ax, top_left,    bottom_left,  color, width)

	# set ticks
	ax.set_xticks(range(math.ceil(option['x_lim'][0]),
	                    math.ceil(option['x_lim'][1]),
	                    math.ceil(
	                        (option['x_lim'][1] - option['x_lim'][0]) / 5
	                    )
	                   )
	             )
	ax.set_yticks(range(math.ceil(option['y_lim'][0]),
	                    math.ceil(option['y_lim'][1]),
	                    math.ceil(
	                        (option['y_lim'][1] - option['y_lim'][0]) / 5
	                    )
	                   )
	             )
	ax.set_zticks(range(math.ceil(option['z_lim'][0]),
	                    math.ceil(option['z_lim'][1]),
	                    math.ceil(
	                        (option['z_lim'][1] - option['z_lim'][0]) / 5
	                    )
	                   )
	             )
	
	# look from
	if 'look_from' in option:
		ax.view_init(option['look_from'][0], option['look_from'][1])
	else:
		ax.view_init(89.99999, -90.00001) # to make X axis on the bottom and Y on the left

	# hide grid
	# check wether on linux or mac
	if os.path.exists("/proc/version") == True :
		ax.grid(b=None)        # for linux
	else :
		ax.grid(visible=None)   # for mac
	

def drawTrackLog(option):
	dataFolder = option['dataFolder']
	brain_marker_svg_path = option['brain_marker']

	case_name = None
	for subFolder in getSubfolders(dataFolder) :
		if 'sample_run' in option and subFolder != dataFolder + "/" + option['sample_run'] + "/" :
			continue
		case_name = subFolder
		break

	input_file = case_name + "logs"
	if 'overwrite_trackFig_log_foler' in option :
		input_file = option['overwrite_trackFig_log_foler']
		print("overwrite trackLog input file:", input_file)
	else :
		print("trackLog input file:", input_file)

	pipuckLogNames, pipuckNames = findRobotLogs(input_file, "pipuck")
	pipuckLogs = openRobotLogs(pipuckLogNames)

	droneLogNames, droneNames = findRobotLogs(input_file, "drone")
	droneLogs = openRobotLogs(droneLogNames)

	targetLogNames, targetNames = findRobotLogs(input_file, "target")
	targetLogs = openRobotLogs(targetLogNames)

	obstacleLogNames, obstacleNames = findRobotLogs(input_file, "obstacle")
	obstacleLogs = openRobotLogs(obstacleLogNames)

	fig = None
	if 'figsize' in option :
		fig = plt.figure(figsize=(option['figsize'][0], option['figsize'][1]))
	else :
		# default size should be 5x5
		fig = plt.figure()

	ax = fig.add_subplot(projection='3d')

	count = 0
	stepLength = 1

	# colors and key frames
	n_colors = len(pipuckLogs + droneLogs)
	#n_colors = 3
	colours = cm.rainbow(np.linspace(0, 1, n_colors))

	key_frame = option['key_frame']

	# for each robot, draw line
	robot_count = 0
	RobotNames = pipuckNames + droneNames
	key_frame_robots = []   # key frame record
	#  start for
	for pipuckLog in pipuckLogs + droneLogs:
		robotName = RobotNames[robot_count]
		robot_count = robot_count + 1
		print("reading", robot_count, robotName)

		# read data for this robot
		X = []
		Y = []
		Z = []
		T = []
		P = []
		B = []
		step_count = 0
		while True:
			step = None
			for i in range(0, stepLength):
				step = readNextLine(pipuckLog, True)    # True means asking readNextLine to return none if pipuckLog ends, otherwise it returns exit()
				if step == None :
					break
			if step == None :
				break
		
			X.append(step['position'][0])
			Y.append(step['position'][1])
			Z.append(step['position'][2])
			T.append(step_count)
			P.append(step['parent'])
			B.append(step['brain'])

			step_count = step_count + stepLength
		#end while True
		total_step = step_count
		key_frame.append(total_step + 1)

		print("smoothing", robot_count, robotName)
		# smooth data
		def moving_average(interval, windowsize) :
			window = np.ones(int(windowsize)) / float(windowsize)
			re = np.convolve(interval, window, 'same')
			return re

		window = 70
		T_smooth = T
		X_smooth = moving_average(X, window)
		Y_smooth = moving_average(Y, window)
		Z_smooth = moving_average(Z, window)

		# draw
		print("drawing", robot_count, robotName)
		i = window
		interval = 1
		key_frame_i = 0
		while i < len(T_smooth)-window : 
			if i != 0 :
				drawVector3(ax, 
				            [X_smooth[i-interval], Y_smooth[i-interval], Z_smooth[i-interval]], 
				            [X_smooth[i],          Y_smooth[i],          Z_smooth[i]], 
				            colours[robot_count-1],
				            0.7
				)
		
			# record key_frame
			if i * stepLength > key_frame[key_frame_i] :
				if robot_count == 1:
					key_frame_robots.append({})
				key_frame_robots[key_frame_i][robotName] = {
					"position" : [X_smooth[i], Y_smooth[i], Z_smooth[i]],
					"parent" : P[i],
					"brain" : B[i]
				}

				# check key_frame_parent_index from option
				if 'key_frame_parent_index' in option and \
				   len(option['key_frame_parent_index']) > key_frame_i and \
				   robotName in option['key_frame_parent_index'][key_frame_i] :
					key_frame_robots[key_frame_i][robotName]["parent"] = option['key_frame_parent_index'][key_frame_i][robotName]
					print("set keyframe", key_frame_i, robotName, "'s parent to",key_frame_robots[key_frame_i][robotName]["parent"])

				# add a color for start step
				# remove parent for start step
				if key_frame[key_frame_i] == 0 :
					key_frame_robots[key_frame_i][robotName]["color"] = colours[robot_count - 1]
					key_frame_robots[key_frame_i][robotName]["parent"] = "nil"

				key_frame_i = key_frame_i + 1
			'''
			if i > key_frame[key_frame_i] :
				ax.plot3D(X_smooth[i], Y_smooth[i], Z_smooth[i], color = 'black', marker = key_frame_style[key_frame_i], linewidth='5')
				key_frame_i = key_frame_i + 1
			'''

			i = i + interval
		#end while i < total_step

		# record last step into key frame 
		if robot_count == 1:
			key_frame_robots.append({})
		key_frame_robots[key_frame_i][robotName] = {
			"position" : [X_smooth[i-interval], Y_smooth[i-interval], Z_smooth[i-interval]],
			"parent" : P[i-interval],
			"brain" : B[i-interval]
		}

		# check key_frame_parent_index from option
		if 'key_frame_parent_index' in option and \
		   len(option['key_frame_parent_index']) > key_frame_i and \
		   robotName in option['key_frame_parent_index'][key_frame_i] :
			key_frame_robots[key_frame_i][robotName]["parent"] = option['key_frame_parent_index'][key_frame_i][robotName]
			print("set keyframe", key_frame_i, robotName, "'s parent to",key_frame_robots[key_frame_i][robotName]["parent"])


		#ax.plot3D(X_smooth[i-interval], Y_smooth[i-interval], Z_smooth[i-interval], color = 'black', marker = 'o')

	# draw obstacles
	color = 'red'
	for obstacleLog in obstacleLogs:
		step = readNextLine(obstacleLog, True)    # True means asking readNextLine to return none if pipuckLog ends, otherwise it returns exit()
		# draw dot
		ax.plot3D([step["position"][0]], 
		          [step["position"][1]],
		          [step["position"][2]],
		          color = color, linewidth='0.5', markersize='2.5', marker = 's')

	for obstacleLog in targetLogs:
		step = readNextLine(obstacleLog, True)    # True means asking readNextLine to return none if pipuckLog ends, otherwise it returns exit()
		# draw dot
		ax.plot3D([step["position"][0]], 
		          [step["position"][1]],
		          [step["position"][2]],
		          color = color, linewidth='0.5', markersize='2.5', marker = 'v')

	# draw key frame
	# first check failed step and failed robots
	print("checking failed robots from : " + input_file + "/../failure_robots.txt")
	failed_robot_flag = False
	failed_robots = []
	failed_step = None
	if os.path.isfile(input_file + "/../failure_robots.txt") :
		print("failure_robots.txt exists")
		failed_robots = readStrDataFrom(input_file + "/../failure_robots.txt")
		failed_robot_flag = True
	else:
		print("failure_robots.txt doesn't exist")

	if os.path.isfile(input_file + "/../failure_step.txt") :
		failed_step = readDataFrom(input_file + "/../failure_step.txt")[0]

	print("failed at", failed_step, "failed_robots = ", failed_robots)

	# start to draw
	usualcolor = 'black'
	failedcolor = 'blue'
	key_frame_i = 0
	key_frame_origin = key_frame
	for key_frame in key_frame_robots :
		step_number = key_frame_origin[key_frame_i]
		print("drawing keyframe " + str(key_frame_i) + " at step " + str(step_number))
		key_frame_i = key_frame_i + 1

		for robotID, robotData in key_frame.items() : 
			# draw regular robots
			robotType = robotID.rstrip(string.digits)
			marker = 'o'
			markersize = '3.5'
			if robotType == "drone" :
				marker = '*'
				markersize = '7'
			color = usualcolor

			# draw failed robots
			if robotID in failed_robots and step_number >= failed_step:
				color = failedcolor

			# draw colored robots (for first step)
			if "color" in robotData :
				color = robotData["color"]
			# draw dot
			ax.plot3D([robotData["position"][0]], 
			          [robotData["position"][1]],
			          [robotData["position"][2]],
			          color = color, 
			          marker = marker,
			          markersize=markersize
			         )
			# draw parent line
			if robotData["parent"] != "nil" :
				parentData = key_frame[robotData["parent"]]
				ax.plot3D([robotData["position"][0], parentData["position"][0]], 
				          [robotData["position"][1], parentData["position"][1]],
				          [robotData["position"][2], parentData["position"][2]],
				          linewidth="1.2",
				          color = color)

	#draw brain at last to cover the lines and overlapping robots
	key_frame_i = 0
	for key_frame in key_frame_robots :
		step_number = key_frame_origin[key_frame_i]
		print("drawing keyframe " + str(key_frame_i) + " at step " + str(step_number))
		key_frame_i = key_frame_i + 1

		for robotID, robotData in key_frame.items() : 
			if robotData['brain'] == robotID and \
			   not (robotID in failed_robots and step_number >= failed_step) and \
			   "color" not in robotData: # color not in robotData means not the first frame
				# check if it is a true brain (not failed robot)
				true_brain_flag = False
				for j_robotID, j_robotData in key_frame.items() : 
					#if j_robotData["parent"] == robotID :
					if j_robotData["brain"] == robotID :
						true_brain_flag = True 
						break
					
				brain_svg_front_path, attributes = svg2paths(brain_marker_svg_path)
				brain_svg_marker = parse_path(attributes[0]['d'])
				brain_svg_marker.vertices -= brain_svg_marker.vertices.mean(axis=0)

				if true_brain_flag == True :
					# draw a white circle
					ax.plot3D([robotData["position"][0]],
					          [robotData["position"][1]],
					          [robotData["position"][2]],
					          color = "white",
					          marker = "o",
					          markersize=str(float(markersize)*1.6)
					         )
					# draw svgs for fancy marker
					ax.plot3D([robotData["position"][0]],
					          [robotData["position"][1]],
					          [robotData["position"][2]],
					          color = "black",
					          marker = brain_svg_marker,
					          markersize=str(float(markersize)*1.4)
					         )

					ax.plot3D([robotData["position"][0]],
					          [robotData["position"][1]],
					          [robotData["position"][2]],
					          color = "black",
					          marker = marker,
					          markersize=str(float(markersize)*0.8)
					         )

	# legend
	legend_handle_usual_robot, = ax.plot([], [],
	          color = usualcolor, 
	          marker = 'o',
	          markersize = '3.5',
	          linestyle = 'None'
	)
	legend_handle_usual_drone, = ax.plot([], [],
	          color = usualcolor, 
	          marker = '*',
	          markersize = '7',
	          linestyle = 'None'
	)
	legend_handle_brain_drone, = ax.plot([], [],
	          color = "black", 
	          marker = brain_svg_marker,
	          markersize = '9',
	          linestyle = 'None'
	)
	legend_handles = [legend_handle_brain_drone,
	                  legend_handle_usual_drone,
	                  legend_handle_usual_robot,
	                 ]
	labels = ['brain',
	          'aerial robots',
	          'ground robots',
	         ]

	legend_position = (0.815, 0.75) # position for xx-small
	#legend_position = (0.815, 0.74) # position for small
	#legend_position = (0.815, 0.73) # position for small
	legend_col = 1

	if 'legend_obstacle' in option and option['legend_obstacle'] :
		legend_handle_obstacle, = ax.plot([], [],
		          color = 'red', 
		          marker = 's',
		          markersize = '2.5',
		          linestyle = 'None'
		)
		legend_handles.append(legend_handle_obstacle)
		labels.append('obstacles')

		legend_handle_target, = ax.plot([], [],
		          color = 'red', 
		          marker = 'v',
		          markersize = '2.5',
		          linestyle = 'None'
		)
		legend_handles.append(legend_handle_target)
		labels.append('target')

		#legend_position = (0.815, 0.73)  # col = 2 and position doesn't need to change
		legend_col = 2
	
	if failed_robot_flag == True :
		legend_handle_failed_robot, = ax.plot([], [],
		          color = failedcolor, 
		          marker = 'o',
		          markersize = '3.5',
		          linestyle = 'None'
		)
		legend_handle_failed_drone, = ax.plot([], [],
		          color = failedcolor, 
		          marker = '*',
		          markersize = '7',
		          linestyle = 'None'
		)
		legend_handles.append((legend_handle_failed_robot, legend_handle_failed_drone))
		labels.append('failed robot')

		if not ('legend_obstacle' in option and option['legend_obstacle']) :
			# then we have 4 rows
			legend_position = (0.815, 0.74) # position for xx-small
	
	'''
	ax.legend(
	    legend_handles, 
	    labels,
	    handler_map={tuple: HandlerTuple(ndivide=None)},  # to make two markers share one label [(a, b)], ['label']
	    loc="right",
	    #bbox_to_anchor=(1.33, 0.7),   # position outside
	    bbox_to_anchor=legend_position,
	    fontsize="xx-small",
	    ncol=legend_col
	)
	'''

	# save images

	setAxParameters(ax, option)
	plt.draw()
	if 'trackLog_save' in option :
		plt.savefig(option['trackLog_save'])
	if 'trackLog_show' in option and option['trackLog_show'] == True :
		plt.show()