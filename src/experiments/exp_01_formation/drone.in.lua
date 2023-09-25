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
	structure = create_horizontal_truss_chain(nodes, 5, vector3(5,0,0), quaternion(2*math.pi/nodes, vector3(0,0,1)), vector3(), quaternion(), true)
elseif robot.params.structure == "donut_48" then
	nodes = 48 / 4
	structure = create_horizontal_truss_chain(nodes, 5, vector3(5,0,0), quaternion(2*math.pi/nodes, vector3(0,0,1)), vector3(), quaternion(), true)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local baseHeight = 4
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

	bt = BT.create(vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				create_failsafe_node(vns),
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


	-- show morphology lines
	local LED_zone = vns.Parameters.driver_arrive_zone * 2
	if vns.goal.positionV3:length() < LED_zone then
		api.debug.showMorphologyLines(vns, true)
	end

	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_failsafe_node(vns)
return function()
	-- fail safe
	if vns.scalemanager.scale["drone"] == 1 and
	   vns.api.actuator.flight_preparation.state == "navigation" then
		if vns.brainkeeper ~= nil and vns.brainkeeper.brain ~= nil then
			local target = vns.brainkeeper.brain.positionV3 + vector3(0,0,5)
			vns.Spreader.emergency_after_core(vns, target:normalize() * 0.5, vector3())
		else
			--vns.Spreader.emergency_after_core(vns, vector3(0,0,0.1), vector3())
		end
		return false, true
	end
	
end end