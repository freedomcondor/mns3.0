if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

logger.enable("main")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require(robot.params.structure or "morphology_20")

-- Analyze function -----
function getCurrentTime()
	local wallTimeS, wallTimeNS, CPUTimeS, CPUTimeNS = robot.radios.wifi.get_time()
	--return CPUTimeS + CPUTimeNS * 0.000000001
	return wallTimeS + wallTimeNS * 0.000000001
end

--[[
function getCurrentTime()
	local tmpfile = robot.id .. '_time_tmp.dat'

	local mac = @CMAKE_APPLE_FLAG@
	if mac == true then
		os.execute('gdate +\"%s.%N\" > ' .. tmpfile) -- use gdate in mac
	else
		os.execute('date +\"%s.%N\" > ' .. tmpfile)
	end

	local time
	local f = io.open(tmpfile)
	for line in f:lines() do
		time = tonumber(line)
	end
	f:close()
	return time
end
--]]

if robot.id == "drone1" then
	lastTime = getCurrentTime()
end

time_accumulator = 0
time_accumulator_count = 0

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

	bt = BT.create(vns.create_vns_node(vns))
end

function step()
	if robot.id == "drone1" then
		local currentTime = getCurrentTime()
		local interval = currentTime - lastTime
		time_accumulator = time_accumulator + interval
		time_accumulator_count = time_accumulator_count + 1
		logger("-------------------------------------------------------------------------", interval, "average = ", time_accumulator / time_accumulator_count)
		lastTime = currentTime
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
	api.debug.showMorphologyLines(vns, true)
end

function destroy()
	vns.destroy()
	api.destroy()
end