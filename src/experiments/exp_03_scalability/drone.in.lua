if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
require("morphologyGenerateTetrahedron")
require("morphologyGenerateCube")
Transform = require("Transform")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local n_drone = tonumber(robot.params.n_drone)
local n_left_drone = tonumber(robot.params.n_left_drone)

local n_right_drone = n_drone - n_left_drone
n_side       = math.ceil(n_drone ^ (1/3))
n_left_side  = math.ceil(n_left_drone ^ (1/3))

local structure_full = generate_cube_morphology(n_drone, n_left_drone)
local structure_left = generate_cube_morphology(n_left_drone)
local structure_right, n_right_side = generate_tetrahedron_morphology(n_right_drone)

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_full,
		structure_left,
		structure_right,
	}
}
--]]

function VNS.CollectiveSensor.reportAll(vns)
	for i, ob in pairs(vns.avoider.obstacles) do
		VNS.CollectiveSensor.addToSendList(vns, ob)
	end
	for i, ob in pairs(vns.collectivesensor.receiveList) do
		local flag = true
		for j, existing_ob in pairs(vns.collectivesensor.sendList) do
			if existing_ob.type == ob.type then
				flag = false
				break
			end
		end
		if flag == true then
			VNS.CollectiveSensor.addToSendList(vns, ob)
		end
	end
end

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure_left)
end

-- Analyze function -----
function getCurrentTime()
	local wallTimeS, wallTimeNS, CPUTimeS, CPUTimeNS = robot.radios.wifi.get_time()
	--return CPUTimeS + CPUTimeNS * 0.000000001
	return wallTimeS + wallTimeNS * 0.000000001
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	api.debug.recordSwitch = true
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	local base_height = tonumber(robot.params.base_height)
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = base_height
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = base_height + 6
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = base_height + 12
	end
	api.debug.show_all = true
end

local startTime = getCurrentTime()

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 2 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure_full)

	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
				create_navigation_node(vns),
			}}}
		)
	)

	lastTime = startTime
end


function step()
	--[[
	local MeasureStepPeriod = 20
	if robot.id == "drone1" and api.stepCount % MeasureStepPeriod == 0 then
		local currentTime = getCurrentTime()
		logger(robot.id, api.stepCount, "----------------------------, runtime :", currentTime - startTime, "average : ", (currentTime - lastTime) / MeasureStepPeriod)
		lastTime = currentTime
	end
	--]]
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	--api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	vns.logLoopFunctionInfo(vns)

	if vns.goal.positionV3:length() < vns.Parameters.driver_stop_zone * 2 then
		api.debug.showMorphologyLines(vns, true)
	end
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
	state = "init"
	stateCount = 0

	local function sendChilrenNewState(vns, newState)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState})
		end
	end

	local function newState(vns, _newState)
		stateCount = 0
		state = _newState
	end

	local function switchAndSendNewState(vns, _newState)
		newState(vns, _newState)
		sendChilrenNewState(vns, _newState)
	end

	local function find_marker(vns, priority, priority_only)
		-- find marker
		local marker
		local marker_behind
		local dis = math.huge
		local dis_behind = -math.huge

		local priority_list = {}
		if priority ~= nil then
			for i, ob in ipairs(vns.collectivesensor.totalObstaclesList) do
				if ob.type == priority then
					table.insert(priority_list, ob)
				end
			end
		end
		if #priority_list == 0 and priority_only ~= true then
			priority_list = vns.collectivesensor.totalObstaclesList
		end

		local average_list = {}
		for i, ob in ipairs(priority_list) do
			-- check ob.type exist in average_list
			local exist_flag = false
			local exist_id = nil
			for j, ob_ave in ipairs(average_list) do
				if ob_ave.type == ob.type then
					exist_flag = true
					exist_id = j
					break
				end
			end

			-- if new
			if exist_flag == false then
				table.insert(average_list, ob)
				ob.accumulator = Transform.createAccumulator()
				Transform.addAccumulator(ob.accumulator, ob)
			else
			-- if exist
				Transform.addAccumulator(average_list[exist_id].accumulator, ob)
			end
		end

		--for i, ob in ipairs(priority_list) do
		for i, ob in ipairs(average_list) do
			Transform.averageAccumulator(ob.accumulator, ob)
			local dirVec = vector3(1,0,0):rotate(ob.orientationQ)
			local horizontal_shadow = ob.positionV3:dot(dirVec)
			if horizontal_shadow > 0 and horizontal_shadow < dis then
				marker = ob
				dis = horizontal_shadow
			end
			if horizontal_shadow <= 0 and horizontal_shadow > dis_behind then
				marker_behind = ob
				dis_behind = horizontal_shadow
			end
		end
		if marker == nil then marker = marker_behind end
		return marker
	end

	local obstacle_left = 1002
	local obstacle_right = 1001

	local start = true
	local startCountDown = 10

	local last_markers = {}
	local last_marker_n = 20

return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state)
	end end

	-- fail safe
	if vns.scalemanager.scale["drone"] == 1 and
	   n_drone ~= 8 and
	   vns.api.actuator.flight_preparation.state == "navigation" then
		if vns.brainkeeper ~= nil and vns.brainkeeper.brain ~= nil then
			local target = vns.brainkeeper.brain.positionV3 + vector3(3,0,5)
			vns.Spreader.emergency_after_core(vns, target:normalize() * 0.5, vector3())
		else
			vns.Spreader.emergency_after_core(vns, vector3(0,0,0.5), vector3())
		end
		return false, true
	end

	-- find marker
	marker = find_marker(vns)
	local lastScale = 0

	-- state
	-- init
	if state == "init" then
		if api.stepCount > 100 then
			switchAndSendNewState(vns, "wait")
		end
	elseif state == "wait" then
		if vns.parentR == nil and stateCount > 30 then
			if vns.driver.all_arrive == true then
				logger("--- NewState: forward")
				switchAndSendNewState(vns, "forward")
			end
		end
	-- forward
	elseif state == "forward" and vns.parentR == nil then
		--vns.intersectionDetector.switch = true
		lastScale = vns.scalemanager.scale["drone"]
		-- switch formations based on swarm size
		if vns.scalemanager.scale["drone"] == n_drone then
			vns.setMorphology(vns, structure_full)
		elseif vns.scalemanager.scale["drone"] == n_left_drone then
			vns.setMorphology(vns, structure_left)
		elseif vns.scalemanager.scale["drone"] == n_right_drone then
			vns.setMorphology(vns, structure_right)
		end

		local offset = vector3(0,0,0)
		local forward_speed_max = 1
		local vertical_speed_max = 0.5

		-- move blindly forward
		if start == true and marker == nil then
			startCountDown = 10
			-- horizontal speed
			-- move forward with speed, calculate into move_speed
			local forward_speed_scalar = stateCount / 50
			if forward_speed_scalar > 1 then forward_speed_scalar = 1 end
			local move_speed = vector3(1,0,0) * forward_speed_max * forward_speed_scalar
			vns.setGoal(vns, vector3(), quaternion())
			vns.Spreader.emergency_after_core(vns, move_speed, vector3())

		-- if I don't see the marker, but spliting, I still move accordingly
		--elseif start == false and (marker == nil or marker.positionV3.x < -5.0) then
		elseif start == false and marker == nil then
			logger("--- NewState: end")
			switchAndSendNewState(vns, "end")

		-- if I see marker, move forward
		elseif marker ~= nil then
			if startCountDown > 0 then
				startCountDown = startCountDown - 1
			else
				start = false
			end

			-- if full size and meet obstacle left or right, split
			if vns.scalemanager.scale["drone"] == n_drone and 
			   ((marker.type == obstacle_left and marker.positionV3.x > 0) or
			    (marker.type == obstacle_right and marker.positionV3.x > 0)
			   ) then
				logger("--- NewState: split")
				switchAndSendNewState(vns, "split")	
				return false, true
			end

			-- forward with adjustments
			if vns.scalemanager.scale["drone"] == n_left_drone and marker.type == obstacle_left then
				offset = vector3(-(n_left_side-1)*0.5 * 5, -(n_left_side-1)*0.5 * 5, 3)
			elseif vns.scalemanager.scale["drone"] == n_right_drone and marker.type == obstacle_right then
				offset = vector3(-(n_right_side-1)*5*math.sqrt(3)*0.5, 0, 3)
			else
				return false, true
			end

			-- vertical speed
			--local forwardDirQ = marker.orientationQ

			local forwardDirQ = quaternion()
			--local target_position = marker.positionV3 + offset:rotate(forwardDirQ)
			-- average last marker
			local sum = marker.positionV3 + offset:rotate(forwardDirQ)
			local sumN = 1
			for i = 1, last_marker_n do
				local last_marker = last_markers[i]
				if last_marker ~= nil then
					sum = sum + last_marker.positionV3 + offset:rotate(forwardDirQ) 
					sumN = sumN + 1
				end
			end
			for i = last_marker_n, 2 ,-1 do
				last_markers[i] = last_markers[i - 1]
			end
			last_markers[1] = marker

			local target_position = sum * (1.0/sumN)

			local target = sum * (1.0/sumN)
			local dirVec = vector3(1,0,0):rotate(forwardDirQ)
			local vertical_position = target_position - target_position:dot(dirVec) * dirVec
			local vertical_speed = vertical_position * 0.1
			if vertical_speed:length() > vertical_speed_max then
				vertical_speed = vertical_speed * (vertical_speed_max / vertical_speed:length())
			end

			-- horizontal speed
			-- move forward with speed, calculate into move_speed
			local forward_speed_scalar = stateCount / 50
			if forward_speed_scalar > 1 then forward_speed_scalar = 1 end
			local move_speed = vector3(dirVec):rotate(forwardDirQ) * forward_speed_max * forward_speed_scalar

			-- move forward with vertical speed and move speed
			--vns.setGoal(vns, vector3(0,0,0), forwardDirQ)
			-- calc rotate speed
			local targetXAxis = vector3(1,0,0):rotate(marker.orientationQ)
			local rotateAxis = vector3(1,0,0):cross(targetXAxis):normalize()
			local rotateSpeed = (vector3(1,0,0) - targetXAxis):length() * 0.1
			vns.Spreader.emergency_after_core(vns, vertical_speed + move_speed, vector3())
			vns.goal.rotateV3 = rotateAxis * rotateSpeed
		end

	elseif state == "split" then
		--vns.intersectionDetector.switch = false
		if vns.allocator.target.split == true then
			-- rebellion
			if vns.parentR ~= nil then
				vns.Msg.send(vns.parentR.idS, "whoissplitting", {idS = robot.id})
				vns.Msg.send(vns.parentR.idS, "dismiss")
				vns.deleteParent(vns)
			end
			vns.Connector.newVnsID(vns, 1, 1000000)
		end	

		-- spread the splitting one
		for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "whoissplitting")) do
			-- if not myself, spread the word
			if msgM.dataT.idS ~= robot.id then
				vns.connector.lastid[msgM.dataT.idS] = 1000000
				if receiveWhoissplittigFlag ~= true then
					for idS, neighbourR in pairs(vns.getNeighbours(vns)) do
						if idS ~= msgM.fromS then
							vns.Msg.send(idS, "whoissplitting", {idS = msgM.dataT.idS})
						end
					end
				end
				receiveWhoissplittigFlag = true
			end
		end

		if vns.parentR == nil then
			-- find marker again with priority
			local split_marker
			local offset
			local search_velocity = vector3(0, 0, 0)

			if vns.scalemanager.scale["drone"] == n_left_drone then
				split_marker = find_marker(vns, obstacle_left, true)
				vns.setMorphology(vns, structure_left)

				local side_length = (n_left_side - 1) * 5
				offset = vector3(-side_length-3, -side_length * 0.5, 3)
				search_velocity = vector3(0.3, 0.5, 0)
			else
			--if vns.scalemanager.scale["drone"] == n_right_drone then
				split_marker = find_marker(vns, obstacle_right, true)
				vns.setMorphology(vns, structure_right)

				local side_length = (n_right_side - 1 + 1) * 5
				--offset = vector3(-side_length*math.sqrt(3)*0.5, 0, 1.0)
				offset = vector3(-side_length * math.sqrt(3)*0.4 - 3, 0, 3)

				if n_drone == 27 then
					offset = vector3(-(n_right_side-1)* 5 *math.sqrt(3)*0.5*0.7, 0, 3)
				end
				search_velocity = vector3(0.1, 0.0, 0)
			end

			if split_marker ~= nil then
				--local target = split_marker.positionV3 + offset:rotate(split_marker.orientationQ)
				--local target = split_marker.positionV3 + offset:rotate(quaternion())
				local sum = split_marker.positionV3 + offset:rotate(quaternion())
				local sumN = 1
				for i = 1, last_marker_n do
					local last_marker = last_markers[i]
					if last_marker ~= nil then
						sum = sum + last_marker.positionV3 + offset:rotate(quaternion()) 
						sumN = sumN + 1
					end
				end
				for i = last_marker_n, 2 ,-1 do
					last_markers[i] = last_markers[i - 1]
				end
				last_markers[1] = split_marker

				local target = sum * (1.0/sumN)


				api.debug.drawArrow("red", vector3(0,0,0), api.virtualFrame.V3_VtoR(target), true)

				if target:length() > 0.3 then
					local slow_down = 1
					local max_speed = 0.3
					--local search_velocity = target * (max_speed / slow_down)
					local search_velocity = target * (max_speed / slow_down)
					if search_velocity:length() > slow_down * max_speed then search_velocity = search_velocity:normalize() * max_speed end
					--vns.setGoal(vns, vector3(), split_marker.orientationQ)
					vns.setGoal(vns, vector3(), quaternion())
					vns.Spreader.emergency_after_core(vns, search_velocity, vector3())
				else
					--vns.setGoal(vns, target, split_marker.orientationQ)
					--if target:length() < 0.3 then
						vns.setGoal(vns, target, quaternion())
						logger("--- NewState: wait")
						switchAndSendNewState(vns, "wait")	
					--end
				end
				-- rotate to align with marker
				local targetXAxis = vector3(1,0,0):rotate(marker.orientationQ)
				local rotateAxis = vector3(1,0,0):cross(targetXAxis):normalize()
				local rotateSpeed = (vector3(1,0,0) - targetXAxis):length() * 0.1
				vns.goal.rotateV3 = rotateAxis * rotateSpeed
			else
				vns.setGoal(vns, vector3(), quaternion())
				vns.Spreader.emergency_after_core(vns, search_velocity, vector3())
			end
		end
	elseif state == "end" then
		--vns.intersectionDetector.switch = true
		if vns.parentR == nil then
			lastScale = vns.scalemanager.scale["drone"]
			-- switch formations based on swarm size
			if vns.scalemanager.scale["drone"] == n_drone then
				vns.setMorphology(vns, structure_full)
				if vns.driver.all_arrive == true then
					logger("all_arrive in end", vns.api.stepCount)
				end
			elseif vns.scalemanager.scale["drone"] == n_left_drone then
				vns.setMorphology(vns, structure_left)
			elseif vns.scalemanager.scale["drone"] == n_right_drone then
				vns.setMorphology(vns, structure_right)
			end

			if vns.scalemanager.scale["drone"] == n_right_drone then
				vns.Spreader.emergency_after_core(vns, vector3(0, 0.5, 0), vector3())
			end
		end
		if vns.scalemanager.scale["drone"] == n_left_drone then
			vns.connector.lastid["drone1"] = nil
		end
	end

end end