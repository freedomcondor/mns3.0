if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require("morphology")

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()
	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)

	bt = BT.create(vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				create_navigation_node(vns),
			}}}

	))
end

function step()
	--logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	--api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
return function()
	signal_led(vns)
	return false, true
end end

function signal_led(vns)
	droneflag = false
	pipuckflag = false
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if robotR.robotTypeS == "drone" then
			droneflag = true
		end
		if robotR.robotTypeS == "pipuck" then
			pipuckflag = true
		end
	end
	if droneflag == true then
		robot.leds.set_leds("green")
	--elseif pipuckflag == true then
	--	robot.leds.set_leds("blue")
	else
		robot.leds.set_leds("red")
	end
end