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

require("morphologyGenerateCube")
require("screenGenerator")
require("trussGenerator")

local structure
if robot.params.structure == "polyhedron_12" then
	structure = require("morphology_polyhedron_12")
elseif robot.params.structure == "polyhedron_20" then
	structure = require("morphology_polyhedron_20")
elseif robot.params.structure == "cube_27" then
	structure = generate_cube_morphology(27)
elseif robot.params.structure == "cube_64" then
	structure = generate_cube_morphology(64)
elseif robot.params.structure == "cube_125" then
	structure = generate_cube_morphology(125)
elseif robot.params.structure == "screen_64" then
	structure = generate_screen_square(8)
elseif robot.params.structure == "donut_64" then
	nodes = 64 / 4
	structure = create_horizontal_truss_chain(nodes, 1.5, vector3(1.5, 0,0), quaternion(2*math.pi/nodes, vector3(0,0,1)), vector3(), quaternion(), true)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
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
	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)

	bt = BT.create(vns.create_vns_node(vns))
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

	api.debug.showMorphologyLines(vns, true)
	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end