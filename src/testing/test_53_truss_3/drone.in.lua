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

require("complexTrussGenerator")
require("manGenerator")
require("sphere20Generator")
local n_drone = tonumber(robot.params.n_drone)
local structure = create_complex_beam(3, 5, 7)
--local structure = create_body()
--local structure = create_sphere20()

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local baseHeight = 80
	local distribute_scale = 4
	if number % 5 == 1 then
		api.parameters.droneDefaultStartHeight = baseHeight
	elseif number % 5 == 2 then
		api.parameters.droneDefaultStartHeight = baseHeight - 1 * distribute_scale
	elseif number % 5 == 3 then
		api.parameters.droneDefaultStartHeight = baseHeight - 2 * distribute_scale
	elseif number % 5 == 4 then
		api.parameters.droneDefaultStartHeight = baseHeight - 3 * distribute_scale
	elseif number % 5 == 0 then
		api.parameters.droneDefaultStartHeight = baseHeight - 4 * distribute_scale
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
end

function step()
	api.preStep()
	vns.preStep(vns)
	bt()
	vns.postStep(vns)
	api.postStep()
	---[[
	api.debug.showChildren(vns, {drawOrientation = false})
	if vns.goal.positionV3:length() < vns.Parameters.driver_stop_zone * 2 then
		api.debug.showMorphologyLines(vns, true)
	end
	--]]
	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end