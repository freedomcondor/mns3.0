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

local structure
if robot.params.structure == "cube_27" then
	structure = generate_cube_morphology(27)
elseif robot.params.structure == "cube_64" then
	structure = generate_cube_morphology(64)
elseif robot.params.structure == "cube_125" then
	structure = generate_cube_morphology(125)
elseif robot.params.structure == "cube_216" then
	structure = generate_cube_morphology(216)
elseif robot.params.structure == "cube_512" then
	structure = generate_cube_morphology(512)
elseif robot.params.structure == "cube_1000" then
	structure = generate_cube_morphology(1000)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local baseHeight = 8
	local distribute_scale = 5
	local layers = 5
	if robot.params.structure == "cube_512" then
		baseHeight = 30
		distribute_scale = 8
	end
	if robot.params.structure == "cube_1000" then
		baseHeight = 50
		distribute_scale = 5
		layers = 10
	end
	for i = 1, layers do
		if number % layers == (i % layers) then
			api.parameters.droneDefaultStartHeight = baseHeight + (i - 1) * distribute_scale
		end
	end

	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)

	bt = BT.create(vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				create_navigation_node(vns),
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
		if vns.brainkeeper ~= nil and vns.brainkeeper.parent ~= nil then
			local target = vns.brainkeeper.parent.positionV3 + vector3(0,0,5)
			vns.Spreader.emergency_after_core(vns, target:normalize() * 0.5, vector3())
		end
		return false, true
	end
end end

function create_navigation_node(vns)
	if robot.params.experiment_type == "discrete" then
		return create_navigation_discrete_node(vns)
	elseif robot.params.experiment_type == "continuous" then
		return create_navigation_continuous_node(vns)
	else
		return function() return false, true end
	end
end

function create_navigation_discrete_node(vns)
	state = "init"
	stateCount = 0

	local speedEachlevel = 1
	local levelTime = 200  -- in step

	local function newState(vns, _newState)
		stateCount = 0
		state = _newState
	end

return function()
	-- navigate node
	stateCount = stateCount + 1

	-- state
	if state == "init" then
		if robot.id == "drone1" and stateCount > 1000 and vns.driver.all_arrive == true then
			newState(vns, 0)
			logger("formation complete, enter hovering", vns.api.stepCount)
			os.execute("echo " ..tostring(vns.api.stepCount) .. " > switchSteps.dat")
		end
	-- forward
	elseif type(state) == "number" and vns.parentR == nil then
		vns.Spreader.emergency_after_core(vns, vector3(state * speedEachlevel, 0, 0), vector3())

		if stateCount >= levelTime then
			logger("switch state to ", state + 1, vns.api.stepCount)
			os.execute("echo " ..tostring(vns.api.stepCount) .. " >> switchSteps.dat")
			newState(vns, state + 1)
		end
	end

	return false, true

end end

function create_navigation_continuous_node(vns)
	state = "init"
	stateCount = 0

	local speedEachlevel = 5 / 1000

	local function newState(vns, _newState)
		stateCount = 0
		state = _newState
	end

return function()
	-- navigate node
	stateCount = stateCount + 1

	-- state
	if state == "init" then
		if robot.id == "drone1" and stateCount > 1000 and vns.driver.all_arrive == true then
			newState(vns, "hover")
			logger("formation complete, enter hovering", vns.api.stepCount)
			os.execute("echo " ..tostring(vns.api.stepCount) .. " > switchSteps.dat")
		end
	-- hover
	elseif state == "hover" and vns.parentR == nil then
		if stateCount >= 200 then
			newState(vns, "acc")
			logger("hover complete, enter acceleration", vns.api.stepCount)
			os.execute("echo " ..tostring(vns.api.stepCount) .. " >> switchSteps.dat")
		end
	-- forward
	elseif state == "acc" and vns.parentR == nil then
		vns.Spreader.emergency_after_core(vns, vector3(stateCount * speedEachlevel, 0, 0), vector3())
		if stateCount * speedEachlevel == 4 then
			os.execute("echo " ..tostring(vns.api.stepCount) .. " >> switchSteps.dat")
		end
		if stateCount % 50 == 0 then
			logger("accelerating, speed is ", stateCount * speedEachlevel, "at step", vns.api.stepCount)
		end
	end

	return false, true

end end