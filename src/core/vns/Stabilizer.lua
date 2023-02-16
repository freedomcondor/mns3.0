-- stabilizer -----------------------------------------
------------------------------------------------------
logger.register("Stabilizer")
local Transform = require("Transform")

local Stabilizer = {}

function Stabilizer.create(vns)
	vns.stabilizer = {}
end

function Stabilizer.reset(vns)
	vns.stabilizer = {}
end

function Stabilizer.preStep(vns)
	vns.stabilizer.referencing_robot = nil
	vns.stabilizer.referencing_me = nil
	vns.stabilizer.stationary_referencing = nil
end

function Stabilizer.addParent(vns)
	for i, ob in ipairs(vns.avoider.obstacles) do
		ob.stabilizer = nil
	end
end

function Stabilizer.deleteParent(vns)
	for i, ob in ipairs(vns.avoider.obstacles) do
		ob.stabilizer = nil
	end
end

function Stabilizer.postStep(vns)
	-- effect only for brain
	if vns.parentR ~= nil then return end

	-- estimate location of the new step 
	local input_transV3 = vns.goal.transV3
	local input_rotateV3 = vns.goal.rotateV3

	-- calculate new goal
	local newGoal = {}
	newGoal.positionV3 = input_transV3 * vns.api.time.period

	local axis = vector3(input_rotateV3):normalize()
	if input_rotateV3:length() == 0 then axis = vector3(0,0,1) end
	newGoal.orientationQ = 
		quaternion(input_rotateV3:length() * vns.api.time.period, axis)

	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer ~= nil then
			-- I should be at newGoal, I see ob.stabilizer, I should see ob as X, newGoal x X = ob.stabilizer
			Transform.AxCisB(newGoal, ob.stabilizer, ob.stabilizer)
		end
	end
end

function Stabilizer.setGoal(vns, positionV3, orientationQ)
	local newGoal = {positionV3 = positionV3, orientationQ = orientationQ}
	for i, ob in ipairs(vns.avoider.obstacles) do
		-- I should be at newGoal, I see ob, this ob should be at my X, newGoal x X = ob
		ob.stabilizer = {}
		Transform.AxCisB(newGoal, ob, ob.stabilizer)
	end
end

function Stabilizer.step(vns)
	if vns.allocator.mode_switch ~= "stationary" then
		-- clear stationary_stabilizer information
		for idS, robotR in pairs(vns.childrenRT) do 
			if robotR.stationary_stabilizer ~= nil then
				robotR.stationary_stabilizer = nil
			end
		end
	end
	-- If I'm not the brain, and it is stationary mode don't do anything
	if vns.parentR ~= nil and vns.allocator.mode_switch ~= "stationary" then
		if vns.robotTypeS == "pipuck" then
			Stabilizer.pipuckListenRequest(vns)
		end
		return
	end
	-- If I'm a drone brain and I haven't fully taken off, don't do anything
	--if vns.robotTypeS == "drone" and vns.api.actuator.flight_preparation.state ~= "navigation" then return end
	-- If I'm a pipuck brain, I don't need stabilizer
	if vns.robotTypeS == "pipuck" then return end

	-- I'm the brain run stabilizer, and set vns.goal
	-- for each obstacle with a stabilizer, average its offset as a new goal
	local offsetAcc = Transform.createAccumulator()

	local flag = false
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer ~= nil and ob.unseen_count == vns.api.parameters.obstacle_unseen_count then
			flag = true
			-- add offset (choose the nearest)
			local offset = {positionV3 = vector3(), orientationQ = quaternion()}
			-- I see ob, I should see ob at ob.stabilizer, I should be at X, X x ob.stablizer = ob
			Transform.CxBisA(ob, ob.stabilizer, offset)
			-- add offset into offsetAcc
			Transform.addAccumulator(offsetAcc, offset)
			ob.stabilizer.offset = offset
		end
	end

	-- if stationary mode then also count pipucks as reference
	if vns.allocator.mode_switch == "stationary" and flag == false then
		for idS, robotR in pairs(vns.childrenRT) do if robotR.robotTypeS == "pipuck" then
			if robotR.stationary_stabilizer ~= nil and robotR.connector.unseen_count == vns.Parameters.connector_unseen_count then
				flag = true
				-- add offset (choose the nearest)
				local offset = {positionV3 = vector3(), orientationQ = quaternion()}
				-- I see ob, I should see ob at ob.stabilizer, I should be at X, X x ob.stablizer = ob
				Transform.CxBisA(robotR, robotR.stationary_stabilizer, offset)
				-- add offset into offsetAcc
				Transform.addAccumulator(offsetAcc, offset)
				robotR.stationary_stabilizer.offset = offset
			end
		end end
	elseif vns.allocator.mode_switch == "stationary" and flag == true then
		for idS, robotR in pairs(vns.childrenRT) do if robotR.robotTypeS == "pipuck" then
			if robotR.stationary_stabilizer ~= nil then
				robotR.stationary_stabilizer = nil
			end
		end end
	end

	-- filter wrong case (sometimes obstacles are too close, they may be messed up with each other)
	-- check with average and subtrack from acc
	flag = false -- flag for valid reference obstacles
	local averageOffset = Transform.averageAccumulator(offsetAcc)
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer ~= nil and ob.unseen_count == vns.api.parameters.obstacle_unseen_count then
			if (ob.stabilizer.offset.positionV3 - averageOffset.positionV3):length() > vns.api.parameters.obstacle_match_distance / 2 then
				Transform.subAccumulator(offsetAcc, ob.stabilizer.offset)
				ob.stabilizer = nil
			else
				flag = true
			end
			ob.offset = nil
		end
	end

	-- check if there are pipucks as a valid reference and mark flag
	if vns.allocator.mode_switch == "stationary" then
		for idS, robotR in pairs(vns.childrenRT) do if robotR.robotTypeS == "pipuck" then
			if robotR.stationary_stabilizer ~= nil and robotR.connector.unseen_count == vns.Parameters.connector_unseen_count then
				flag = true
				break
			end
		end end
	end

	local obstacle_flag = false
	for i, ob in ipairs(vns.avoider.obstacles) do
		obstacle_flag = true
		break
	end

	-- check
	local colorflag = false -- flag for whether to show circle or not
	local offset = {positionV3 = vector3(), orientationQ = quaternion()}
	if flag == true and vns.stabilizer.force_pipuck_reference ~= true then
		-- average offsetAcc into offset
		Transform.averageAccumulator(offsetAcc, offset)
		vns.goal.positionV3 = offset.positionV3
		vns.goal.orientationQ = offset.orientationQ
		colorflag = true
		--vns.allocator.keepBrainGoal = true
		vns.stabilizer.lastReference = nil
		if vns.allocator.mode_switch == "stationary" then
			vns.stabilizer.stationary_referencing = true
		end
	---[[
	elseif obstacle_flag == true and vns.stabilizer.force_pipuck_reference ~= true then
		-- There are obstacles, I just don't see them, wait to see them, set offset as the current goal
		offset.positionV3 = vns.goal.positionV3 
		offset.orientationQ = vns.goal.orientationQ
	elseif obstacle_flag == false or vns.stabilizer.force_pipuck_reference == true then
	--]]
	--else
		-- set a pipuck as reference
		local offset = Stabilizer.robotReference(vns)
		if offset == nil then
			offset = {}
			offset.positionV3 = vns.goal.positionV3
			offset.orientationQ = vns.goal.orientationQ
		else
			vns.goal.positionV3 = offset.positionV3
			vns.goal.orientationQ = offset.orientationQ
			colorflag = true
		end
	end

	-- for each new obstacle without a stabilizer, set a stabilizer
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer == nil then
			-- I should be at offset, I see ob, this ob should be at my X, offset x X = ob
			ob.stabilizer = {}
			Transform.AxCisB(offset, ob, ob.stabilizer)
		end
	end

	-- if stationary mode then also count pipucks as reference
	if vns.allocator.mode_switch == "stationary" then
		for idS, robotR in pairs(vns.childrenRT) do if robotR.robotTypeS == "pipuck" then
			if robotR.stationary_stabilizer == nil then
				robotR.stationary_stabilizer = {}
				Transform.AxCisB(offset, robotR, robotR.stationary_stabilizer)
			end
		end end
	end

	---[[
	if colorflag then
		local color = "255,0,255,0"
		vns.api.debug.drawArrow(color,
		                        vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
		                        vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 + vector3(0.1,0,0):rotate(vns.goal.orientationQ))
		                       )
		vns.api.debug.drawRing(color,
		                       vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
		                       0.1
		                      )
	end
	--]]
end

function Stabilizer.getReferenceChild(vns)
	-- get a reference pipuck
	---[[
	if vns.childrenRT[vns.Parameters.stabilizer_preference_robot] ~= nil then
		-- check preference
		return vns.childrenRT[vns.Parameters.stabilizer_preference_robot]
	--]]
	elseif vns.childrenRT[vns.stabilizer.lastReference] ~= nil then
	--if vns.childrenRT[vns.stabilizer.lastReference] ~= nil then
		return vns.childrenRT[vns.stabilizer.lastReference]
	else
		-- get the nearest to reference pipuck in morphology
		-- get the reference pipuck in morphology
		local reference_position = nil
		if vns.allocator.target.children ~= nil then
			local flag = false
			for _, branch in ipairs(vns.allocator.target.children) do
				if branch.reference == true then
					reference_position = branch.positionV3
					flag = true
					break
				end
			end
			if flag == false then
				for _, branch in ipairs(vns.allocator.target.children) do
					if branch.robotTypeS == "pipuck" then
						reference_position = branch.positionV3
						break
					end
				end
			end
		end

		if reference_position == nil then return end

		local nearestDis = math.huge
		local ref = nil
		for idS, robotR in pairs(vns.childrenRT) do
			local locV3 = robotR.positionV3 - reference_position
			if vns.api.parameters.mode_2D == true then locV3.z = 0 end
			local dis = locV3:length()
			if robotR.robotTypeS == "pipuck" and dis < nearestDis then
				nearestDis = dis
				ref = robotR
			end
		end
		if ref ~= nil then
			vns.stabilizer.lastReference = ref.idS
		end
		return ref
	end
end

function Stabilizer.pipuckListenRequest(vns)
	-- listen to referencing pipuck, avoid it harder in avoider
	vns.stabilizer.referencing_pipuck_neighbour = nil
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "I_am_referenced_pipuck")) do
		vns.stabilizer.referencing_pipuck_neighbour = msgM.fromS
	end

	for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "stabilizer_request")) do
		vns.stabilizer.referencing_me = true
		vns.stabilizer.referencing_me_count_down = vns.Parameters.reference_count_down
	end

	if vns.stabilizer.referencing_me_count_down ~= nil then
		if vns.stabilizer.referencing_me_count_down > 0 then
			vns.stabilizer.referencing_me_count_down =
				vns.stabilizer.referencing_me_count_down - 1
			vns.stabilizer.referencing_me = true
		else
			vns.stabilizer.referencing_me = nil
		end
	end

	if vns.stabilizer.referencing_me == true then
		-- tell other pipuck I'm referenced, so that they know to avoid me harder
		for idS, robotR in pairs(vns.connector.seenRobots) do
			if robotR.robotTypeS == "pipuck" then
				vns.Msg.send(idS, "I_am_referenced_pipuck")
			end
		end

		-- calculate where my parent should be related to me
		local parentTransform = {}
		if vns.allocator.target == nil or vns.allocator.target.idN == -1 then
			return
			--parentTransform.positionV3 = vector3()
			--parentTransform.orientationQ = quaternion()
		else
			if vns.stabilizer.referencing_me_goal_overwrite ~= nil then
				local myGoal = {positionV3 = vector3(), orientationQ = quaternion()}
				if vns.stabilizer.referencing_me_goal_overwrite.positionV3 ~= nil then
					myGoal.positionV3 = vns.stabilizer.referencing_me_goal_overwrite.positionV3
				end
				if vns.stabilizer.referencing_me_goal_overwrite.orientationQ ~= nil then
					myGoal.orientationQ = vns.stabilizer.referencing_me_goal_overwrite.orientationQ
				end
				Transform.AxCisB(vns.allocator.target, myGoal, parentTransform)
			else
				Transform.AxCis0(vns.allocator.target, parentTransform)
			end
		end

		vns.Msg.send(vns.parentR.idS, "stabilizer_reply", {
			parentTransform = {
				positionV3 = vns.api.virtualFrame.V3_VtoR(parentTransform.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(parentTransform.orientationQ),
			},
		})

		-- The goal of referencing pipuck will be over written in Allocator
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()

		if vns.stabilizer.referencing_me_goal_overwrite ~= nil then
			if vns.stabilizer.referencing_me_goal_overwrite.positionV3 ~= nil then
				vns.goal.positionV3 = vns.stabilizer.referencing_me_goal_overwrite.positionV3
			end
			if vns.stabilizer.referencing_me_goal_overwrite.orientationQ ~= nil then
				vns.goal.orientationQ = vns.stabilizer.referencing_me_goal_overwrite.orientationQ
			end
			--vns.stabilizer.referencing_me_goal_overwrite = nil
		end

		local color = "255,0,255,0"
		vns.api.debug.drawRing(color,
		                       vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 + vector3(0,0,0.1)),
		                       0.1
		                      )
	end
end

function Stabilizer.robotReference(vns)
	local refRobot = Stabilizer.getReferenceChild(vns)
	if refRobot == nil then return nil end

	vns.stabilizer.referencing_robot = refRobot

	local color = "255,0,255,0"
	vns.api.debug.drawArrow(color,
	                        vns.api.virtualFrame.V3_VtoR(vector3()),
	                        vns.api.virtualFrame.V3_VtoR(refRobot.positionV3)
	                       )

	logger("try referencing", refRobot.idS)
	vns.Msg.send(refRobot.idS, "stabilizer_request")
	for _, msgM in ipairs(vns.Msg.getAM(refRobot.idS, "stabilizer_reply")) do
		logger("get referencing reply from", refRobot.idS)
		local offset = msgM.dataT.parentTransform
		Transform.AxBisC(refRobot, offset, offset)
		-- TODO: check?

		return offset
	end
end

------ behaviour tree ---------------------------------------
function Stabilizer.create_stabilizer_node(vns)
	return function()
		Stabilizer.step(vns)
		return false, true
	end
end

return Stabilizer
