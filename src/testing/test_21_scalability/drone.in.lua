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

local dataFileName = "record.dat"

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = 1
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = 3.0
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = 5.0
	end

	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)

	bt = BT.create(
		vns.create_vns_node(vns)
	)
end

function step()
	local getMEM_title_linux  = "top -b -n 1 | grep PID"
	local getMEM_argos_linux = "top -b -n 1 | grep argos3"
	local getMEM_title_mac  = "top -l 1 | grep PID"
	local getMEM_argos_mac = "top -l 1 | grep argos3"
	local getTotalMEM_linux = "grep MemTotal /proc/meminfo"
	local getTotalMEM_mac = "sysctl hw.memsize"
	local getTIME_linux = "date +\"%s.%N\""
	local getTIME_mac   = "gdate +\"%s.%N\""

	local getMEM_title = getMEM_title_linux
	local getMEM_argos = getMEM_argos_linux
	local getTIME      = getTIME_linux
	local getTotalMEM  = getTotalMEM_linux

	local mac = @CMAKE_APPLE_FLAG@
	if mac == true then
		getMEM_title = getMEM_title_mac
		getMEM_argos = getMEM_argos_mac
		getTIME      = getTIME_mac
		getTotalMEM  = getTotalMEM_mac
	end

	if robot.id == "drone1" then
		if api.stepCount == 0  then
			os.execute(getTotalMEM .. " > " .. dataFileName)
			os.execute(getMEM_title .. " >> " .. dataFileName)
			os.execute(getTIME .. " >> " .. dataFileName)
		end
		if api.stepCount % 5 == 0  then
			os.execute("echo ".. tostring(api.stepCount) .. " >> " .. dataFileName)
			os.execute(getMEM_argos .. " >> " .. dataFileName)
			os.execute(getTIME .. " >> " .. dataFileName)
		end
	end

	--logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	--api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	if vns.goal.positionV3:length() < vns.Parameters.driver_stop_zone * 2 then
		api.debug.showMorphologyLines(vns, true)
	end
end

function destroy()
	vns.destroy()
	api.destroy()
end