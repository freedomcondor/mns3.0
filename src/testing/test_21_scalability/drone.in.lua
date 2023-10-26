if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

require("morphology")
local n_drone = tonumber(robot.params.n_drone)
local structure = generate_morphology(n_drone)

local dataMemLogFileName = "logs_time/mem.dat"
local dataTimeLogFileName = "logs_time/lua_time_" .. robot.id .. ".dat"
local dataTimeLogFile

function getCurrentTime()
	local wallTimeS, wallTimeNS, CPUTimeS, CPUTimeNS = robot.radios.wifi.get_time()
	return wallTimeS + wallTimeNS * 0.000000001, CPUTimeS + CPUTimeNS * 0.000000001
end

local lastMeasuredWallTime, lastMeasuredCPUTime
local currentWallTime, currentCPUTime

-- Overwrite core node to get time
VNS.create_vns_core_node = function(vns, option)
	-- option = {
	--      connector_no_recruit = true or false or nil,
	--      connector_no_parent_ack = true or false or nil,
	--      specific_name = "drone1"
	--      specific_time = 150
	--          -- If I am stabilizer_preference_robot then ack to only drone1 for 150 steps
	-- }
	if option == nil then option = {} end
	if robot.id == vns.Parameters.stabilizer_preference_robot then
		option.specific_name = vns.Parameters.stabilizer_preference_brain
		option.specific_time = vns.Parameters.stabilizer_preference_brain_time
	end

																local vnsCoreNodeLastMeasuredWallTime, vnsCoreNodeLastMeasuredCPUTime
	return
	{type = "sequence", children = {
		--vns.create_preconnector_node(vns),
																function()
																	vnsCoreNodeLastMeasuredWallTime, vnsCoreNodeLastMeasuredCPUTime = getCurrentTime()
																	return false, true
																end,
		vns.Connector.create_connector_node(vns,
			{	no_recruit = option.connector_no_recruit,
				no_parent_ack = option.connector_no_parent_ack,
				specific_name = option.specific_name,
				specific_time = option.specific_time,
			}),

																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.1.____connector_____ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,

		--vns.DroneConnectKeeper.create_droneconnectkeeper_node(vns),
		vns.Assigner.create_assigner_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.2.____assigner______ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.ScaleManager.create_scalemanager_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.3.____scalemanager__ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.Stabilizer.create_stabilizer_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.4.____stabilizer____ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.Allocator.create_allocator_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.5.____allocator_____ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.TrussReferencer.create_trussreferencer_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.6.__trussreferencer_ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.IntersectionDetector.create_intersectiondetector_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.7.__intersection____ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.Avoider.create_avoider_node(vns, {
			drone_pipuck_avoidance = option.drone_pipuck_avoidance
		}),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.8.__intersection____ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.Spreader.create_spreader_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.9.__spreader________ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		vns.BrainKeeper.create_brainkeeper_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("        3.2.9.__brainkeeper_____ %.10f, %.10f\n",
																	                                    currentWallTime - vnsCoreNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsCoreNodeLastMeasuredCPUTime))
																	vnsCoreNodeLastMeasuredWallTime = currentWallTime
																	vnsCoreNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
		--vns.CollectiveSensor.create_collectivesensor_node(vns),
		--vns.Driver.create_driver_node(vns),
	}}
end

VNS.create_vns_node = function(vns, option)
	-- option = {
	--      connector_no_recruit = true or false or nil,
	--      connector_no_parent_ack = true or false or nil,
	--      driver_waiting
	-- }
	if option == nil then option = {} end

																local vnsNodeLastMeasuredWallTime, vnsNodeLastMeasuredCPUTime

	local children_node = {
																function()
																	vnsNodeLastMeasuredWallTime, vnsNodeLastMeasuredCPUTime = getCurrentTime()
																	return false, true
																end,
		vns.create_preconnector_node(vns),
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("    3.1.____preconnector________ %.10f, %.10f\n",
																	                                    currentWallTime - vnsNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsNodeLastMeasuredCPUTime))
																	vnsNodeLastMeasuredWallTime = currentWallTime
																	vnsNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end,
	}
	if option.navigation_node_pre_core ~= nil then
		table.insert(children_node, option.navigation_node_pre_core)
	end
	table.insert(children_node, vns.create_vns_core_node(vns, option))
															table.insert(children_node, 
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("    3.2.____core node___________ %.10f, %.10f\n",
																	                                    currentWallTime - vnsNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsNodeLastMeasuredCPUTime))
																	vnsNodeLastMeasuredWallTime = currentWallTime
																	vnsNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end
															)
	if option.navigation_node_post_core ~= nil then
		table.insert(children_node, option.navigation_node_post_core)
	end
	table.insert(children_node,
		vns.Driver.create_driver_node(vns, {waiting = option.driver_waiting})
	)
															table.insert(children_node, 
																function()
																	local currentWallTime, currentCPUTime = getCurrentTime()
																	dataTimeLogFile:write(string.format("    3.3.____driver node_________ %.10f, %.10f\n",
																	                                    currentWallTime - vnsNodeLastMeasuredWallTime,
																	                                    currentCPUTime - vnsNodeLastMeasuredCPUTime))
																	vnsNodeLastMeasuredWallTime = currentWallTime
																	vnsNodeLastMeasuredCPUTime = currentCPUTime
																	return false, true
																end
															)
	return {
		type = "sequence", children = children_node
	}
end

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local baseHeight = 8
	local distribute_scale = 4
	if number % 5 == 1 then
		api.parameters.droneDefaultStartHeight = baseHeight
	elseif number % 5 == 2 then
		api.parameters.droneDefaultStartHeight = baseHeight + 1 * distribute_scale
	elseif number % 5 == 3 then
		api.parameters.droneDefaultStartHeight = baseHeight + 2 * distribute_scale
	elseif number % 5 == 4 then
		api.parameters.droneDefaultStartHeight = baseHeight + 3 * distribute_scale
	elseif number % 5 == 0 then
		api.parameters.droneDefaultStartHeight = baseHeight + 4 * distribute_scale
	end

	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)

	bt = BT.create(
		vns.create_vns_node(vns)
	)

	dataTimeLogFile = io.open(dataTimeLogFileName, "w")
end

function step()
	-- Log MEM
	local getMEM_title_linux  = "top -b -n 1 | grep PID"
	local getMEM_argos_linux = "top -b -n 1 | grep argos3"
	local getMEM_title_mac  = "top -l 1 | grep PID"
	local getMEM_argos_mac = "top -l 1 | grep argos3"
	local getTotalMEM_linux = "grep MemTotal /proc/meminfo"
	local getTotalMEM_mac = "sysctl hw.memsize"

	local getMEM_title = getMEM_title_linux
	local getMEM_argos = getMEM_argos_linux
	local getTotalMEM  = getTotalMEM_linux

	local mac = @CMAKE_APPLE_FLAG@
	if mac == true then
		getMEM_title = getMEM_title_mac
		getMEM_argos = getMEM_argos_mac
		getTotalMEM  = getTotalMEM_mac
	end

	if robot.id == "drone1" then
		if api.stepCount == 0  then
			os.execute(getTotalMEM .. " > " .. dataMemLogFileName)
			os.execute(getMEM_title .. " >> " .. dataMemLogFileName)
		end
		if api.stepCount % 50 == 0  then
			os.execute("echo ".. tostring(api.stepCount) .. " >> " .. dataMemLogFileName)
			os.execute(getMEM_argos .. " >> " .. dataMemLogFileName)
		end
	end

	--logger(robot.id, api.stepCount, "----------------------------")
																	-- log time
																		lastMeasuredWallTime, lastMeasuredCPUTime = getCurrentTime()
																		dataTimeLogFile:write("--- " .. tostring(api.stepCount) .. "--------\n")
	api.preStep()
																		currentWallTime, currentCPUTime = getCurrentTime()
																		dataTimeLogFile:write(string.format("1. api_prestep__________________ %.10f, %.10f\n",
																		                                    currentWallTime - lastMeasuredWallTime,
																		                                    currentCPUTime - lastMeasuredCPUTime))
																		lastMeasuredWallTime = currentWallTime
																		lastMeasuredCPUTime = currentCPUTime

	vns.preStep(vns)
																		currentWallTime, currentCPUTime = getCurrentTime()
																		dataTimeLogFile:write(string.format("2. vns_prestep__________________ %.10f, %.10f\n",
																		                                    currentWallTime - lastMeasuredWallTime,
																		                                    currentCPUTime - lastMeasuredCPUTime))
																		lastMeasuredWallTime = currentWallTime
																		lastMeasuredCPUTime = currentCPUTime

	bt()

																		currentWallTime, currentCPUTime = getCurrentTime()
																		dataTimeLogFile:write(string.format("3. bt___________________________ %.10f, %.10f\n",
																		                                    currentWallTime - lastMeasuredWallTime,
																		                                    currentCPUTime - lastMeasuredCPUTime))
																		lastMeasuredWallTime = currentWallTime
																		lastMeasuredCPUTime = currentCPUTime

	vns.postStep(vns)
																		currentWallTime, currentCPUTime = getCurrentTime()
																		dataTimeLogFile:write(string.format("4. vns.postStep_________________ %.10f, %.10f\n",
																		                                    currentWallTime - lastMeasuredWallTime,
																		                                    currentCPUTime - lastMeasuredCPUTime))
																		lastMeasuredWallTime = currentWallTime
																		lastMeasuredCPUTime = currentCPUTime
	api.postStep()
																		currentWallTime, currentCPUTime = getCurrentTime()
																		dataTimeLogFile:write(string.format("5. api.postStep_________________ %.10f, %.10f\n",
																		                                    currentWallTime - lastMeasuredWallTime,
																		                                    currentCPUTime - lastMeasuredCPUTime))
																		lastMeasuredWallTime = currentWallTime
																		lastMeasuredCPUTime = currentCPUTime
	--api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	if vns.goal.positionV3:length() < vns.Parameters.driver_stop_zone * 2 then
		api.debug.showMorphologyLines(vns, true)
	end
	vns.logLoopFunctionInfo(vns)
																		currentWallTime, currentCPUTime = getCurrentTime()
																		dataTimeLogFile:write(string.format("6. after postStep_______________ %.10f, %.10f\n",
																		                                    currentWallTime - lastMeasuredWallTime,
																		                                    currentCPUTime - lastMeasuredCPUTime))
																		lastMeasuredWallTime = currentWallTime
																		lastMeasuredCPUTime = currentCPUTime

																		dataTimeLogFile:flush()
end

function destroy()
	vns.destroy()
	api.destroy()
	io.close(dataTimeLogFile)
end