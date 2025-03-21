if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
local Transform = require("Transform")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

require("morphologyGenerateCube")

local structure = generate_cube_morphology(1)

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	api.parameters.droneDefaultStartHeight = 15

	api.debug.show_all = true
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

function get_my_global_pose(vns)
	for index, obstacle in ipairs(vns.avoider.seenObstacles) do
		local obstacleToMe = Transform.AxCis0(obstacle) 
		local obstacleGlobal = {
			positionV3 = vector3((obstacle.type-1) * 10, 0, 0),
			orientationQ = quaternion(),
		}
		return Transform.AxBisC(obstacleGlobal, obstacleToMe)
	end
end

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

	local global_goal = vector3(0,0,8)
	local stepTime = 0.2

return function()
	-- navigate node
	stateCount = stateCount + 1

	local myGlobalPose = get_my_global_pose(vns)
	local MeToOrigin
	if myGlobalPose ~= nil then
		MeToOrigin = Transform.AxCis0(myGlobalPose)
		api.debug.drawArrow("red", vector3(0,0,0), api.virtualFrame.V3_VtoR(MeToOrigin.positionV3), true)
	end

	-- state
	if state == "init" then
		if robot.id == "drone1" and stateCount > 300 and vns.driver.all_arrive == true then
			newState(vns, 0)
			logger("formation complete, enter hovering", vns.api.stepCount)
			os.execute("echo " ..tostring(vns.api.stepCount) .. " > switchSteps.dat")
		end
	-- forward
	elseif type(state) == "number" and vns.parentR == nil then
		vns.Spreader.emergency_after_core(vns, vector3(state * speedEachlevel, 0, 0), vector3())
		local velocity = vns.goal.transV3
		if velocity:length() > 5 then velocity = 5 * velocity:normalize() end
		global_goal = global_goal + velocity * api.time.period

		if stateCount >= levelTime then
			logger("switch state to ", state + 1, vns.api.stepCount)
			os.execute("echo " ..tostring(vns.api.stepCount) .. " >> switchSteps.dat")
			newState(vns, state + 1)
		end
	end

	if myGlobalPose ~= nil then
		Transform.AxCisB(myGlobalPose, {positionV3 = global_goal, orientationQ = quaternion()}, vns.goal)
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

	local global_goal = vector3(0,0,8)
	local stepTime = 0.2

return function()
	-- navigate node
	stateCount = stateCount + 1

	local myGlobalPose = get_my_global_pose(vns)
	local MeToOrigin
	if myGlobalPose ~= nil then
		MeToOrigin = Transform.AxCis0(myGlobalPose)
		api.debug.drawArrow("red", vector3(0,0,0), api.virtualFrame.V3_VtoR(MeToOrigin.positionV3), true)
	end

	-- state
	if state == "init" then
		if robot.id == "drone1" and stateCount > 300 and vns.driver.all_arrive == true then
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
		local velocity = vns.goal.transV3
		if velocity:length() > 5 then velocity = 5 * velocity:normalize() end
		global_goal = global_goal + velocity * api.time.period

		if stateCount * speedEachlevel == 4 then
			os.execute("echo " ..tostring(vns.api.stepCount) .. " >> switchSteps.dat")
		end
		if stateCount % 50 == 0 then
			logger("accelerating, speed is ", stateCount * speedEachlevel, "at step", vns.api.stepCount)
		end
	end

	if myGlobalPose ~= nil then
		Transform.AxCisB(myGlobalPose, {positionV3 = global_goal, orientationQ = quaternion()}, vns.goal)
	end

	return false, true

end end