-- Allocator -----------------------------------------
------------------------------------------------------
logger.register("Allocator")
local MinCostFlowNetwork = require("MinCostFlowNetwork")
local DeepCopy = require("DeepCopy")
local BaseNumber = require("BaseNumber")
local Transform = require("Transform")

local Allocator = {}

--[[
--	related data
--	vns.allocator.target = {positionV3, orientationQ, robotTypeS, children}
--	vns.allocator.gene
--	vns.allocator.gene_index
--	vns.childrenRT[xx].allocator.match
--]]

function Allocator.create(vns)
	vns.allocator = {
		target = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
			robotTypeS = vns.robotTypeS,
			idN = -1,
		},
		parentGoal = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		mode_switch = "allocate",
		goal_overwrite = nil,
		-- goal overwrite is a hack to let after_core nodes change goal regardless of the parent's command
		-- it will take effective before children allocation, and then set back to nil in step after overwrite goal
		--	{
		--		positionV3.x/y/z, orientationQ               target to change
		--	}
	}
end

function Allocator.reset(vns)
	vns.allocator = {
		target = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
			robotTypeS = vns.robotTypeS,
			idN = -1,
		},
		parentGoal = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		mode_switch = "allocate",
		goal_overwrite = nil,
	}
end

function Allocator.addChild(vns, robotR)
	robotR.allocator = {match = nil}
end

--function Allocator.deleteChild(vns)
--end

function Allocator.addParent(vns)
	vns.mode_switch = "allocate"
end

function Allocator.deleteParent(vns)
	vns.allocator.parentGoal = {
		positionV3 = vector3(),
		orientationQ = quaternion(),
	}
	--vns.Allocator.setMorphology(vns, vns.allocator.gene)
	-- TODO: resetMorphology?
end

function Allocator.setGene(vns, morph)
	vns.allocator.morphIdCount = 0
	vns.allocator.gene_index = {}
	vns.allocator.gene_index[-1] = {
		positionV3 = vector3(),
		orientationQ = quaternion(),
		idN = -1,
		robotTypeS = vns.robotTypeS,
	}
	Allocator.calcMorphScale(vns, morph)
	vns.allocator.gene = morph
	vns.Allocator.setMorphology(vns, morph)
end

function Allocator.setMorphology(vns, morph)
	-- issue a temporary morph if the morph is not valid
	if morph == nil then
		morph = {
			idN = -1,
			positionV3 = vector3(),
			orientationQ = quaternion(),
			robotTypeS = vns.robotTypeS,
		} 
	elseif morph.robotTypeS ~= vns.robotTypeS then 
		morph = {
			idN = -1,
			positionV3 = morph.positionV3,
			orientationQ = morph.orientationQ,
			robotTypeS = vns.robotTypeS,
		} 
	end
	vns.allocator.target = morph
end

function Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, vns.allocator.gene)
end

function Allocator.preStep(vns)
	for idS, childR in pairs(vns.childrenRT) do
		childR.allocator.match = nil
	end
	if vns.parentR ~= nil then
		local inverseOri = quaternion(vns.api.estimateLocation.orientationQ):inverse()
		vns.allocator.parentGoal.positionV3 = (vns.allocator.parentGoal.positionV3 - vns.api.estimateLocation.positionV3):rotate(inverseOri)
		vns.allocator.parentGoal.orientationQ = vns.allocator.parentGoal.orientationQ * inverseOri
	end
end

function Allocator.sendStationary(vns)
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "allocator_stationary")
	end
end

function Allocator.sendAllocate(vns)
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "allocator_allocate")
	end
end

function Allocator.sendKeep(vns)
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "allocator_keep")
		vns.Msg.send(idS, "parentGoal", {
			positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 or vector3()),
			orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ or quaternion()),
		})
	end
end

function Allocator.step(vns)
	vns.api.debug.drawRing(vns.lastcolor or "black", vector3(0,0,0.3), 0.1)
	-- update parentGoal
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "parentGoal")) do
		vns.allocator.parentGoal.positionV3 = vns.parentR.positionV3 +
			vector3(msgM.dataT.positionV3):rotate(vns.parentR.orientationQ)
		vns.allocator.parentGoal.orientationQ = vns.parentR.orientationQ * msgM.dataT.orientationQ 
	end end

	-- receive mode switch command
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "allocator_stationary")) do
		vns.allocator.mode_switch = "stationary"
	end end
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "allocator_keep")) do
		vns.allocator.mode_switch = "keep"
	end end
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "allocator_allocate")) do
		vns.allocator.mode_switch = "allocate"
	end end

	-- stationary mode
	if vns.allocator.mode_switch == "stationary" then
		-- vns.goal.positionV3 and orientationQ remain nil
		if vns.stabilizer.stationary_referencing ~= true then
			vns.goal.positionV3 = vector3()
			vns.goal.orientationQ = quaternion()
		end
		Allocator.sendStationary(vns)
		return 
	end

	-- keep mode
	if vns.allocator.mode_switch == "keep" then
		vns.goal.positionV3 = vns.allocator.parentGoal.positionV3 +
			vector3(vns.allocator.target.positionV3):rotate(vns.allocator.parentGoal.orientationQ)
		vns.goal.orientationQ = vns.allocator.parentGoal.orientationQ * vns.allocator.target.orientationQ
		Allocator.sendKeep(vns)
		return 
	end

	-- allocate mode
	if vns.allocator.mode_switch == "allocate" then
		Allocator.sendAllocate(vns)
	end

	-- if I just handovered a child to parent, then I will receive an outdated allocate command, ignore this cmd
	if vns.parentR ~= nil and vns.parentR.assigner.scale_assign_offset:totalNumber() ~= 0 then
		for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "branches")) do
			msgM.ignore = true
		end
	end

	-- update my target based on parent's cmd
	local flag
	local second_level
	local self_align
	local temporary_goal
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "branches")) do 
	if msgM.ignore ~= true then
		flag = true
		second_level = msgM.dataT.branches.second_level
		self_align = msgM.dataT.branches.self_align

		--logger("receive branches")
		--logger(msgM.dataT.branches)

		if #msgM.dataT.branches == 1 then
			local color = "green"
			vns.lastcolor = color
			vns.api.debug.drawRing(color, vector3(), 0.12)
		elseif #msgM.dataT.branches > 1 then
			local color = "blue"
			vns.lastcolor = color
			vns.api.debug.drawRing(color, vector3(), 0.12)
		end
		if second_level == true then
			local color = "red"
			vns.lastcolor = color
			vns.api.debug.drawRing(color, vector3(0,0,0.01), 0.11)
		end
		for i, received_branch in ipairs(msgM.dataT.branches) do
			-- branches = 
			--	{  1 = {
			--              idN, may be -1
			--              number(the scale)
			--              positionV3 and orientationV3
			--         }
			--     2 = {...}
			--     second_level = nil or true
			--         -- indicates if I'm under a split node
			--     goal = {positionV3, orientationQ} 
			--         -- a goal indicates the location of grand parent
			--         -- happens in the first level split
			--     self_align - nil or true
			--         -- indicates whether this child should ignore second_level parent chase
			--	}
			received_branch.positionV3 = vns.parentR.positionV3 +
				vector3(received_branch.positionV3):rotate(vns.parentR.orientationQ)
			received_branch.orientationQ = vns.parentR.orientationQ * received_branch.orientationQ
			received_branch.robotTypeS = vns.allocator.gene_index[received_branch.idN].robotTypeS -- TODO: consider
		end
		if msgM.dataT.branches.goal ~= nil then
			msgM.dataT.branches.goal.positionV3 = vns.parentR.positionV3 +
				vector3(msgM.dataT.branches.goal.positionV3):rotate(vns.parentR.orientationQ)
			msgM.dataT.branches.goal.orientationQ = vns.parentR.orientationQ * msgM.dataT.branches.goal.orientationQ
			temporary_goal = msgM.dataT.branches.goal
		end

		Allocator.multi_branch_allocate(vns, msgM.dataT.branches)
	end end end

	-- I should have a target (either updated or not), 
	-- a goal for this step
	-- a group of children with match = nil

	-- check vns.allocator.goal_overwrite
	if vns.allocator.goal_overwrite ~= nil then
		local newPositionV3 = vns.goal.positionV3
		local newOrientationQ = vns.goal.orientationQ
		if vns.allocator.goal_overwrite.positionV3.x ~= nil then
			newPositionV3.x = vns.allocator.goal_overwrite.positionV3.x
		end
		if vns.allocator.goal_overwrite.positionV3.y ~= nil then
			logger(robot.id, "positionV3.y", vns.allocator.goal_overwrite.positionV3.y)
			newPositionV3.y = vns.allocator.goal_overwrite.positionV3.y
		end
		if vns.allocator.goal_overwrite.positionV3.z ~= nil then
			newPositionV3.z = vns.allocator.goal_overwrite.positionV3.z
		end
		if vns.allocator.goal_overwrite.orientationQ ~= nil then
			newOrientationQ = vns.allocator.goal_overwrite.orientationQ
		end
		vns.setGoal(vns, newPositionV3, newOrientationQ)
		vns.allocator.goal_overwrite = nil
	end

	--if I'm brain, if no stabilizer than stay still
	--[[
	if vns.parentR == nil and
	   vns.stabilizer ~= nil and
	   vns.stabilizer.allocator_signal == nil and
	   vns.allocator.keepBrainGoal == nil then
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()
	end
	--]]
	--[[
	if vns.parentR == nil and vns.allocator.keepBrainGoal == nil then
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()
	end
	--]]

	-- tell my children my goal
	if flag ~= true and vns.parentR ~= nil then
		local color = "yellow"
		vns.lastcolor = color
		vns.api.debug.drawRing(color, vector3(), 0.12)

		-- if I don't receive branches cmd, update my goal according to parentGoal
		--[[
		vns.goal.positionV3 = vns.allocator.parentGoal.positionV3 + 
			vector3(vns.allocator.target.positionV3):rotate(vns.allocator.parentGoal.orientationQ)
		vns.goal.orientationQ = vns.allocator.parentGoal.orientationQ * vns.allocator.target.orientationQ
		--]]

		-- send my new goal and don't send command for my children, everyone keep still
		-- send my new goal to children
		for idS, robotR in pairs(vns.childrenRT) do
			vns.Assigner.assign(vns, idS, nil)	
			vns.Msg.send(idS, "parentGoal", {
				positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 or vector3()),
				orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ or quaternion()),
			})
		end
		return
	end

	-- if my target is -1, I'm in the process of handing up to grandparent, stop children assign
	-- TODO: what if I'm already in the brain and I have more children 
	-- somethings when topology changing, there will be -1 perturbation shortly, ignore this -1
	---[[
	if vns.allocator.target.idN == -1 and (vns.allocator.extraCount or 0) < 5 then
		second_level = true
	end
	if vns.allocator.target.idN == -1 then
		vns.allocator.extraCount = (vns.allocator.extraCount or 0) + 1
	else
		vns.allocator.extraCount = nil
	end
	--]]

	-- assign better child
	if vns.parentR ~= nil then
		local calcBaseValue = Allocator.calcBaseValue
		if type(vns.allocator.target.calcBaseValue) == "function" then
			calcBaseValue = vns.allocator.target.calcBaseValue
		end
		local myValue = calcBaseValue(vns.allocator.parentGoal.positionV3, vector3(), vns.goal.positionV3)
		--local myValue = Allocator.calcBaseValue(vns.parentR.positionV3, vector3(), vns.goal.positionV3)
		for idS, robotR in pairs(vns.childrenRT) do
			if robotR.allocator.match == nil then
				local value = calcBaseValue(vns.allocator.parentGoal.positionV3, robotR.positionV3, vns.goal.positionV3)
				--local value = Allocator.calcBaseValue(vns.parentR.positionV3, robotR.positionV3, vns.goal.positionV3)
				if robotR.robotTypeS == vns.robotTypeS and value < myValue then
					local send_branches = {}
					send_branches[1] = {
						idN = vns.allocator.target.idN,
						number = vns.allocator.target.scale,
						positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ),
						priority = vns.allocator.target.priority
					}
					send_branches.second_level = second_level
					vns.Msg.send(idS, "branches", {branches = send_branches})
					if second_level ~= true then
						vns.Assigner.assign(vns, idS, vns.parentR.idS)	
					end
					robotR.allocator.match = send_branches
				end
			end
		end
	end

	-- create branches from target children, with goal drifted position
	local branches = {second_level = second_level}
	if vns.allocator.target.children ~= nil then
		for _, branch in ipairs(vns.allocator.target.children) do
			branches[#branches + 1] = {
				idN = branch.idN,
				number = branch.scale,
				-- for brain, vns.goal.positionV3 = nil
				positionV3 = (vns.goal.positionV3) +
					vector3(branch.positionV3):rotate(vns.goal.orientationQ),
				orientationQ = vns.goal.orientationQ * branch.orientationQ, 
				robotTypeS = branch.robotTypeS,
				-- calcBaseValue function
				calcBaseValue = branch.calcBaseValue,
				-- Stabilizer hack -----------------------
				reference = branch.reference,
				priority = branch.priority,
			}

			-- do not drift if self align switch is on
			if vns.allocator.self_align == true and
			   vns.robotTypeS == "drone" and
			   branch.robotTypeS == "pipuck" then
				branches[#branches].positionV3 = branch.positionV3
				branches[#branches].orientationQ = branch.orientationQ
				branches[#branches].self_align = true
			end
		end
	end

	-- Stabilizer hack ------------------------------------------------------
	-- get a reference in branches
	if vns.stabilizer.referencing_robot ~= nil then
		local flag = false
		for _, branch in ipairs(branches) do
			if branch.reference == true then
				branch.robotTypeS = "reference_pipuck"
				flag = true
				branch.number = vns.ScaleManager.Scale:new(branch.number)
				branch.number:dec("pipuck")
				branch.number:inc("reference_pipuck")
				break
			end
		end
		if flag == false then
			for _, branch in ipairs(branches) do
				if branch.robotTypeS == "pipuck" then
					branch.robotTypeS = "reference_pipuck"
					branch.number = vns.ScaleManager.Scale:new(branch.number)
					branch.number:dec("pipuck")
					branch.number:inc("reference_pipuck")
					break
				end
			end
		end
	end
	-- Stabilizer hack ------------------------------------------------------
	-- change reference pipuck to reference_pipuck
	if vns.stabilizer.referencing_robot ~= nil then
		local ref = vns.stabilizer.referencing_robot
		if ref.scalemanager.scale["reference_pipuck"] == nil or
		   ref.scalemanager.scale["reference_pipuck"] == 0 then
			ref.robotTypeS = "reference_pipuck"
			ref.scalemanager.scale:dec("pipuck")
			ref.scalemanager.scale:inc("reference_pipuck")
		end
	end
	-- end Stabilizer hack ------------------------------------------------------

	-- hack branch position to save far away drone
	local goalPositionV2 = vns.goal.positionV3
	if vns.api.parameters.mode_2D == true then goalPositionV2.z = 0 end
	if vns.robotTypeS == "drone" and
	   --goalPositionV2:length() > 0.5 then
	   vns.driver.drone_arrive == false and
	   vns.allocator.pipuck_bridge_switch == true then
		local neighbours = {}
		if vns.parentR ~= nil and vns.parentR.robotTypeS == "drone" then
			neighbours[#neighbours + 1] = vns.parentR
			vns.parentR.parent = true
		end
		---[[
		for idS, robotR in pairs(vns.childrenRT) do
			if robotR.robotTypeS == "drone" then
				neighbours[#neighbours + 1] = robotR
			end
		end
		--]]
		--for idS, robotR in pairs(vns.childrenRT) do
		for idS, robotR in ipairs(neighbours) do
			--local disV2 = vector3(robotR.positionV3)
			--if vns.api.parameters.mode_2D == true then disV2.z = 0 end
			--if robotR.robotTypeS == "drone" and
			--   disV2:length() > vns.Parameters.safezone_drone_drone then
			--if robotR.robotTypeS == "drone" then
				-- this drone needs a pipuck in the middle
				-- get the nearest pipuck
				local dis = math.huge
				local nearestBranch = nil
				for _, branch in ipairs(branches) do
					if branch.robotTypeS == "pipuck" and
					   branch.reference ~= true and
					   (branch.positionV3 - robotR.positionV3):length() < dis and
					   branch.drone_bridge_hack == nil then
						dis = (branch.positionV3 - robotR.positionV3):length()
						nearestBranch = branch
					end
				end
				if nearestBranch ~= nil then
					nearestBranch.positionV3 = robotR.positionV3 * 0.5
					local offset = vector3(robotR.positionV3):normalize():rotate(quaternion(math.pi/2, vector3(0,0,1)))
					               * vns.Parameters.dangerzone_pipuck
					nearestBranch.positionV3 = nearestBranch.positionV3 + offset
					nearestBranch.drone_bridge_hack = true
				end
			--end
		end
	end

	Allocator.allocate(vns, branches)

	-- Stabilizer hack ------------------------------------------------------
	-- change reference pipuck back to pipuck
	if vns.stabilizer.referencing_robot ~= nil then
		local ref = vns.stabilizer.referencing_robot
		if ref.scalemanager.scale["reference_pipuck"] == 1 then
			ref.robotTypeS = "pipuck"
			ref.scalemanager.scale:inc("pipuck")
			ref.scalemanager.scale:dec("reference_pipuck")
		end
	end
	-- end Stabilizer hack ------------------------------------------------------

	-- Stabilizer hack ------------------------------------------------------
	-- stop moving is I'm referenced  TODO: combine with goal_overwrite
	if vns.stabilizer.referencing_me == true then
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()
		if vns.stabilizer.referencing_me_goal_overwrite ~= nil then
			if vns.stabilizer.referencing_me_goal_overwrite.positionV3 ~= nil then
				vns.goal.positionV3 = vns.stabilizer.referencing_me_goal_overwrite.positionV3
			end
			if vns.stabilizer.referencing_me_goal_overwrite.orientationQ ~= nil then
				vns.goal.orientationQ = vns.stabilizer.referencing_me_goal_overwrite.orientationQ
			end
			vns.stabilizer.referencing_me_goal_overwrite = nil
		end
	end
	-- end Stabilizer hack ------------------------------------------------------

	if second_level == true and self_align ~= true and vns.parentR ~= nil then -- parent may be deleted by intersection
		vns.goal.positionV3 = vns.parentR.positionV3
		vns.goal.orientationQ = vns.parentR.orientationQ
	end
	if temporary_goal ~= nil then
		vns.goal.positionV3 = temporary_goal.positionV3
		vns.goal.orientationQ = temporary_goal.orientationQ
	end

	-- send my new goal to children
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "parentGoal", {
			positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 or vector3()),
			orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ or quaternion()),
		})
	end

end

function Allocator.multi_branch_allocate(vns, branches)
	--- Stabilizer hack -------------------
	if vns.stabilizer.referencing_me == true then
		vns.robotTypeS = "reference_pipuck"
	end
	--- end Stabilizer hack -------------------

	local sourceList = {}
	-- create sources from myself
	local tempScale = vns.ScaleManager.Scale:new()
	tempScale:inc(vns.robotTypeS)
	sourceList[#sourceList + 1] = {
		number = tempScale,
		index = {
			positionV3 = vector3(),
			robotTypeS = vns.robotTypeS,
		},
	}

	-- create sources from children
	for idS, robotR in pairs(vns.childrenRT) do
		sourceList[#sourceList + 1] = {
			number = vns.ScaleManager.Scale:new(robotR.scalemanager.scale),
			index = robotR,
		}
	end

	if #sourceList == 0 then return end

	-- create targets from branches
	local targetList = {}
	for _, branchR in ipairs(branches) do
		targetList[#targetList + 1] = {
			number = vns.ScaleManager.Scale:new(branchR.number),
			index = branchR
		}
	end

	-- create a cost matrix
	local originCost = {}
	for i = 1, #sourceList do originCost[i] = {} end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			local targetPosition = vector3(targetList[j].index.positionV3)
			local relativeVector = sourceList[i].index.positionV3 - targetPosition
			if vns.api.parameters.mode_2D == true then relativeVector.z = 0 end
			originCost[i][j] = relativeVector:length()
			if targetList[j].index.priority ~= nil then
				originCost[i][j] = originCost[i][j] * targetList[j].index.priority
			end
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost, "pipuck")
	Allocator.GraphMatch(sourceList, targetList, originCost, "drone")
	if vns.api.parameters.mode_builderbot == true then
		Allocator.GraphMatch(sourceList, targetList, originCost, "builderbot")
	end
	-- Stabilizer hack ----
	Allocator.GraphMatch(sourceList, targetList, originCost, "reference_pipuck")

	--[[
	logger("multi-branch sourceList")
	for i, source in ipairs(sourceList) do
		logger(i, source.index.idS or source.index.idN, source.index.robotTypeS)
		logger("\tposition = ", source.index.positionV3)
		logger("\tnumber")
		logger(source.number, 2)
		logger("\tto")
		for j, to in ipairs(source.to) do
			logger("\t", j, targetList[to.target].index.idS or targetList[to.target].index.idN)
			logger("\t\t\tnumber")
			logger(to.number, 4)
		end
	end
	logger("multi-branch targetList")
	for i, target in ipairs(targetList) do
		logger(i, target.index.idS or target.index.idN, target.index.robotTypeS)
		logger("\tposition = ", target.index.positionV3)
		logger("\tnumber")
		logger(target.number, 2)
		logger("\tfrom")
		for j, from in ipairs(target.from) do
			logger("\t", j, sourceList[from.source].index.idS or sourceList[from.source].index.idN)
			logger("\t\t\tnumber")
			logger(from.number, 4)
		end
	end
	--]]

	--- Stabilizer hack -------------------
	if vns.stabilizer.referencing_me == true then
		vns.robotTypeS = "pipuck"
	end
	--- end Stabilizer hack -------------------

	-- set myself  
	local myTarget = nil
	if #(sourceList[1].to) == 1 then
		myTarget = targetList[sourceList[1].to[1].target]
		local branchID = myTarget.index.idN
		Allocator.setMorphology(vns, vns.allocator.gene_index[branchID])
		vns.goal.positionV3 = myTarget.index.positionV3
		vns.goal.orientationQ = myTarget.index.orientationQ
		---[[ sometimes when topology changes, these maybe a -1 misjudge shortly, ignore this -1
		if branchID == -1 and (vns.allocator.extraCount or 0) < 5 then
			branches.second_level = true
		end
		--]]
	elseif #(sourceList[1].to) == 0 then
		Allocator.setMorphology(vns, vns.allocator.gene_index[-1])
		vns.goal.positionV3 = vns.allocator.parentGoal.positionV3
		vns.goal.orientationQ = vns.allocator.parentGoal.orientationQ
	elseif #(sourceList[1].to) > 1 then
		logger("Impossible! Myself is split in multi_branch_allocation")
	end

	-- handle split children
	-- this means I've already got a multi-branch cmd, I send a second_level multi-branch cmd
	-- if my cmd is first level multi-branch, I handover this child to my parent
	for i = 2, #sourceList do
		if #(sourceList[i].to) > 1 then
			local sourceChild = sourceList[i].index
			local send_branches = {}
			for _, targetItem in ipairs(sourceList[i].to) do
				local target_branch = targetList[targetItem.target]
				send_branches[#send_branches+1] = {
					idN = target_branch.index.idN,
					number = targetItem.number,
					positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.index.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.index.orientationQ),
					priority = target_branch.priority
				}
			end
			send_branches.second_level = true
			-- send temporary goal based on my temporary goal
			-- if I'm a first level split node, send a temporary goal for grand parent location
			if branches.second_level ~= true then
				send_branches.goal = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ),
				}
			end

			vns.Msg.send(sourceChild.idS, "branches", {branches = send_branches})
			if branches.second_level ~= true then
				vns.Assigner.assign(vns, sourceChild.idS, vns.parentR.idS)	
			else
				vns.Assigner.assign(vns, sourceChild.idS, nil)	
			end
			sourceChild.allocator.match = send_branches
		end
	end

	-- handle not my children
	-- for each target that is not my assignment
	for j = 1, #targetList do if targetList[j] ~= myTarget then
		local farthest_id = nil
		local farthest_value = math.huge
		-- for each child that is assigned to the current target
		for i = 2, #sourceList do 
		if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			-- create send branch
			local source_child = sourceList[i].index
			local target_branch = targetList[j].index
			local send_branches = {}
			send_branches[1] = {
				idN = target_branch.idN,
				number = sourceList[i].to[1].number,
				positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.orientationQ),
				priority = target_branch.priority
			}
			-- if I'm a first level split node, send a temporary goal for grand parent location
			if branches.second_level ~= true then
				send_branches.goal = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ),
				}
			end
			--send_branches.second_level = branches.second_level
			send_branches.second_level = true
			vns.Msg.send(source_child.idS, "branches", {branches = send_branches})

			-- calculate farthest value
			local calcBaseValue = Allocator.calcBaseValue
			if type(target_branch.calcBaseValue) == "function" then
				calcBaseValue = target_branch.calcBaseValue
			end
			local value = calcBaseValue(vns.allocator.parentGoal.positionV3, source_child.positionV3, target_branch.positionV3)
			--local value = Allocator.calcBaseValue(vns.parentR.positionV3, source_child.positionV3, target_branch.positionV3)
			if source_child.robotTypeS == vns.allocator.gene_index[target_branch.idN].robotTypeS and 
			   value < farthest_value then
				farthest_id = i
				farthest_value = value
			end

			-- mark
			source_child.allocator.match = send_branches
		end end

		-- assign
		-- for each child that is assigned to the current target
		for i = 2, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			local source_child_id = sourceList[i].index.idS
			if i == farthest_id then
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child_id, vns.parentR.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			elseif farthest_id ~= nil then
				if branches.second_level ~= true then
					--vns.Assigner.assign(vns, source_child_id, sourceList[farthest_id].index.idS)	-- can't hand up and hand among siblings at the same time
					vns.Assigner.assign(vns, source_child_id, vns.parentR.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			elseif farthest_id == nil then -- the children are all different type, no farthest one is chosen
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child_id, vns.parentR.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			end
		end end
	end end
end

function Allocator.allocate(vns, branches)
	-- create sources from children
	local sourceList = {}
	local sourceSum = vns.ScaleManager.Scale:new()
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.allocator.match == nil then
			sourceList[#sourceList + 1] = {
				number = vns.ScaleManager.Scale:new(robotR.scalemanager.scale),
				index = robotR,
			}
			sourceSum = sourceSum + robotR.scalemanager.scale
		end
	end

	if #sourceList == 0 then return end

	-- create targets from branches
	local targetList = {}
	local targetSum = vns.ScaleManager.Scale:new()
	for _, branchR in ipairs(branches) do
		targetList[#targetList + 1] = {
			number = vns.ScaleManager.Scale:new(branchR.number),
			index = branchR
		}
		targetSum = targetSum + branchR.number
	end

	-- add parent as a target
	local diffSum = sourceSum - targetSum
	for i, v in pairs(diffSum) do
		if diffSum[i] ~= nil and diffSum[i] < 0 then
			diffSum[i] = 0
		end
	end
	if diffSum:totalNumber() > 0 and vns.parentR ~= nil then
		targetList[#targetList + 1] = {
			number = diffSum,
			index = {
				idN = -1,
				positionV3 = vns.parentR.positionV3,
				orientationQ = vns.parentR.orientationQ,
			}
		}
	elseif diffSum:totalNumber() > 0 and vns.parentR == nil then
		targetList[#targetList + 1] = {
			number = diffSum,
			index = {
				idN = -1,
				positionV3 = vector3(),
				orientationQ = quaternion(),
			}
		}
	end

	-- create a cost matrix
	local originCost = {}
	for i = 1, #sourceList do originCost[i] = {} end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			local targetPosition = vector3(targetList[j].index.positionV3)
			local relativeVector = sourceList[i].index.positionV3 - targetPosition
			if vns.api.parameters.mode_2D == true then relativeVector.z = 0 end
			originCost[i][j] = relativeVector:length()
			if targetList[j].index.priority ~= nil then
				originCost[i][j] = originCost[i][j] * targetList[j].index.priority
			end
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost, "pipuck")
	Allocator.GraphMatch(sourceList, targetList, originCost, "drone")
	if vns.api.parameters.mode_builderbot == true then
		Allocator.GraphMatch(sourceList, targetList, originCost, "builderbot")
	end
	-- Stabilizer hack ----
	Allocator.GraphMatch(sourceList, targetList, originCost, "reference_pipuck")

	--[[
	logger("sourceList")
	for i, source in ipairs(sourceList) do
		logger(i, source.index.idS or source.index.idN, source.index.robotTypeS)
		logger("\tposition = ", source.index.positionV3)
		logger("\tnumber")
		logger(source.number, 2)
		logger("\tto")
		for j, to in ipairs(source.to) do
			logger("\t", j, targetList[to.target].index.idS or targetList[to.target].index.idN)
			logger("\t\t\tnumber")
			logger(to.number, 4)
		end
	end
	logger("targetList")
	for i, target in ipairs(targetList) do
		logger(i, target.index.idS or target.index.idN, target.index.robotTypeS)
		logger("\tposition = ", target.index.positionV3)
		logger("\tnumber")
		logger(target.number, 2)
		logger("\tfrom")
		for j, from in ipairs(target.from) do
			logger("\t", j, sourceList[from.source].index.idS or sourceList[from.source].index.idN)
			logger("\t\t\tnumber")
			logger(from.number, 4)
		end
	end
	--]]

	-- handle split children  -- TODO if one of the split branches is -1
	for i = 1, #sourceList do
		if #(sourceList[i].to) > 1 then
			local sourceChild = sourceList[i].index
			local send_branches = {}
			for _, targetItem in ipairs(sourceList[i].to) do
				local target_branch = targetList[targetItem.target]
				send_branches[#send_branches+1] = {
					idN = target_branch.index.idN,
					number = targetItem.number,
					positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.index.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.index.orientationQ),
					priority = target_branch.priority
				}
			end
			send_branches.second_level = branches.second_level

			vns.Msg.send(sourceChild.idS, "branches", {branches = send_branches})
			vns.Assigner.assign(vns, sourceChild.idS, nil)	
			sourceChild.allocator.match = send_branches
		end
	end

	-- handle rest of the children
	-- for each target that is not the parent
	for j = 1, #targetList do if targetList[j].index.idN ~= -1 then
		local farthest_id = nil
		local farthest_value = math.huge
		-- for each child that is assigned to the current target
		for i = 1, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			-- create send branch
			local source_child = sourceList[i].index
			local target_branch = targetList[j].index
			local send_branches = {}
			send_branches[1] = {
				idN = target_branch.idN,
				number = sourceList[i].to[1].number,
				positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.orientationQ),
				priority = target_branch.priority
			}
			send_branches.second_level = branches.second_level
			send_branches.self_align = target_branch.self_align
			vns.Msg.send(source_child.idS, "branches", {branches = send_branches})

			-- calculate farthest value
			local calcBaseValue = Allocator.calcBaseValue
			if type(target_branch.calcBaseValue) == "function" then
				calcBaseValue = target_branch.calcBaseValue
			end
			local value = calcBaseValue(vns.goal.positionV3, source_child.positionV3, target_branch.positionV3)
			--local value = Allocator.calcBaseValue(vector3(), source_child.positionV3, target_branch.positionV3)

			if source_child.robotTypeS == vns.allocator.gene_index[target_branch.idN].robotTypeS and 
			   value < farthest_value then
				farthest_id = i
				farthest_value = value
			end

			-- mark
			source_child.allocator.match = send_branches
		end end

		-- assign
		-- for each child that is assigned to the current target
		for i = 1, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			local source_child_id = sourceList[i].index.idS
			if i == farthest_id then
				vns.Assigner.assign(vns, source_child_id, nil)	
			elseif farthest_id ~= nil then
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child_id, sourceList[farthest_id].index.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			end
		end end
	end end

	-- handle extra children     -- TODO: may set second level
	-- for each target that is the parent
	for j = 1, #targetList do if targetList[j].index.idN == -1 then
		for i = 1, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			local source_child = sourceList[i].index
			local target_branch = targetList[j].index
			local send_branches = {}
			send_branches[1] = {
				--idN = vns.allocator.target.idN,
				idN = target_branch.idN, --(-1)
				number = sourceList[i].to[1].number,
				positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.orientationQ),
				priority = target_branch.priority
			}
			send_branches.second_level = branches.second_level
			-- stop children handing over for extre children
			--send_branches.second_level = true 

			vns.Msg.send(source_child.idS, "branches", {branches = send_branches})
			if vns.parentR ~= nil then
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child.idS, vns.parentR.idS)	
				end
			else
				vns.Assigner.assign(vns, source_child.idS, nil)	
			end
			source_child.allocator.match = send_branches
		end end
	end end
end

-------------------------------------------------------------------------------
function Allocator.GraphMatch(sourceList, targetList, originCost, type)
	-- create a enhanced cost matrix
	-- and orderlist, to sort everything in originCost
	local orderList = {}
	local count = 0
	for i = 1, #sourceList do
		for j = 1, #targetList do
			count = count + 1
			orderList[count] = originCost[i][j]
		end
	end

	-- sort orderlist
	for i = 1, #orderList - 1 do
		for j = i + 1, #orderList do
			if orderList[i] > orderList[j] then
				local temp = orderList[i]
				orderList[i] = orderList[j]
				orderList[j] = temp
			end
		end
	end

	-- calculate sum for sourceList
	local sourceSum = 0
	for i = 1, #sourceList do
		sourceSum = sourceSum + (sourceList[i].number[type] or 0)
	end
	-- create a reverse index
	local reverseIndex = {}
	for i = 1, #orderList do reverseIndex[orderList[i]] = i end
	-- create an enhanced cost matrix
	local cost = {}
	for i = 1, #sourceList do
		cost[i] = {}
		for j = 1, #targetList do
			--cost[i][j] = (sourceSum + 1) ^ reverseIndex[originCost[i][j]]
			if (sourceSum + 1) ^ (#orderList + 1) > 2 ^ 31 then
				--cost[i][j] = BaseNumber:createWithInc(sourceSum + 1, reverseIndex[originCost[i][j]])
				cost[i][j] = originCost[i][j] * originCost[i][j]
			else
				--cost[i][j] = (sourceSum + 1) ^ reverseIndex[originCost[i][j]]
				cost[i][j] = originCost[i][j] * originCost[i][j]
			end
			---[[
			if sourceList[i].index.robotTypeS ~= targetList[j].index.robotTypeS or
			   sourceList[i].index.robotTypeS ~= type then
				if (sourceSum + 1) ^ (#orderList + 1) > 2 ^ 31 then
					--cost[i][j] = cost[i][j] + BaseNumber:createWithInc(sourceSum + 1, #orderList + 1)
					cost[i][j] = cost[i][j] + 2 ^ 31
				else
					--cost[i][j] = cost[i][j] + (sourceSum + 1) ^ (#orderList + 1)
					cost[i][j] = cost[i][j] + (sourceSum + 1) ^ (#orderList + 1)
				end
			end
			--]]
		end
	end

	-- create a flow network
	local C = {}
	local n = 1 + #sourceList + #targetList + 1
	for i = 1, n do C[i] = {} end
	-- 1, start
	-- 2 to #sourceList+1  source
	-- #sourceList+2 to #sourceList + #targetList + 1  target
	-- #sourceList + #target + 2   end
	local sumSource = 0
	for i = 1, #sourceList do
		C[1][1 + i] = sourceList[i].number[type] or 0
		sumSource = sumSource + C[1][1 + i]
		if C[1][1 + i] == 0 then C[1][1 + i] = nil end
	end
	if sumSource == 0 then
		return
	end

	for i = 1, #targetList do
		C[#sourceList+1 + i][n] = targetList[i].number[type]
		if C[#sourceList+1 + i][n] == 0 then C[#sourceList+1 + i][n] = nil end
	end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			C[1 + i][#sourceList+1 + j] = math.huge
		end
	end
	
	local W = {}
	local n = 1 + #sourceList + #targetList + 1
	for i = 1, n do W[i] = {} end

	for i = 1, #sourceList do
		W[1][1 + i] = 0
	end
	for i = 1, #targetList do
		W[#sourceList+1 + i][n] = 0
	end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			W[1 + i][#sourceList+1 + j] = cost[i][j]
		end
	end

	local LuaStackScaleLimit = 11 -- assuming max slots is 255, then C and W each can't be higher than 121
	local F
	if n > LuaStackScaleLimit then
		F = MinCostFlowNetwork(C, W)
	else
		local F_argos
		for i = 1, n do
			for j = 1, n do
				if C[i][j] == nil then C[i][j] = -1 end
				if W[i][j] == nil then W[i][j] = math.huge end
			end
		end

		F_argos = ARGoSMinCostFlowNetwork(C, W)

		F = {}
		for i = 1, n do
			F[i] = {}
			for j = 1, n do
				if (F_argos[i][j] ~= -1) then F[i][j] = F_argos[i][j] end
			end
		end
	end

	for i = 1, #sourceList do
		if sourceList[i].to == nil then
			sourceList[i].to = {}
		end
	end
	for j = 1, #targetList do
		if targetList[j].from == nil then
			targetList[j].from = {}
		end
	end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			if F[1 + i][#sourceList+1 + j] ~= nil and
			   F[1 + i][#sourceList+1 + j] ~= 0 then
				-- set sourceTo
				local exist = false
				-- see whether this target has already exist
				for k, sourceTo in ipairs(sourceList[i].to) do
					if sourceTo.target == j then
						sourceTo.number[type] = F[1 + i][#sourceList+1 + j]
						exist = true
						break
					end
				end
				if exist == false then
					local newNumber = vns.ScaleManager.Scale:new()
					newNumber[type] = F[1 + i][#sourceList+1 + j]
					sourceList[i].to[#(sourceList[i].to) + 1] = 
						{
							number = newNumber,
							target = j,
						}
				end
				-- set targetFrom
				exist = false
				-- see whether this source has already exist
				for k, targetFrom in ipairs(targetList[j].from) do
					if targetFrom.source == i then
						targetFrom.number[type] = F[1 + i][#sourceList+1 + j]
						exist = true
						break
					end
				end
				if exist == false then
					local newNumber = vns.ScaleManager.Scale:new()
					newNumber[type] = F[1 + i][#sourceList+1 + j]
					targetList[j].from[#(targetList[j].from) + 1] = 
						{
							number = newNumber,
							source = i,
						}
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
function Allocator.calcBaseValue_vertical(base, current, target)
	local base_target_V3 = target - base
	local base_current_V3 = current - base
	if vns.api.parameters.mode_2D == true then
		base_target_V3.z = 0
		base_current_V3.z = 0
	end
	return base_current_V3:dot(base_target_V3:normalize())
end

function Allocator.calcBaseValue_oval(base, current, target)
	local base_target_V3 = target - base
	local base_current_V3 = current - base
	if vns.api.parameters.mode_2D == true then
		base_target_V3.z = 0
		base_current_V3.z = 0
	end
	local dot = base_current_V3:dot(base_target_V3:normalize())
	if dot < 0 then 
		return dot 
	else
		local x = dot
		local x2 = dot ^ 2
		local l = base_current_V3:length()
		local y2 = l ^ 2 - x2
		elliptic_distance2 = x2 + (1/4) * y2
		return elliptic_distance2
	end
end

--Allocator.calcBaseValue = Allocator.calcBaseValue_vertical
Allocator.calcBaseValue = Allocator.calcBaseValue_oval

-------------------------------------------------------------------------------
function Allocator.calcMorphScale(vns, morph)
	Allocator.calcMorphChildrenScale(vns, morph)
	Allocator.calcMorphParentScale(vns, morph)
end

function Allocator.calcMorphChildrenScale(vns, morph, level, parentTransform)
	-- calc global transform
	if parentTransform == nil then
		parentTransform = {positionV3 = vector3(), orientationQ = quaternion()}
	end
	local globalTransform = Transform.AxBisC(parentTransform, morph)
	morph.globalPositionV3 = globalTransform.positionV3
	morph.globalOrientationQ = globalTransform.orientationQ

	-- calc ID count
	vns.allocator.morphIdCount = vns.allocator.morphIdCount + 1
	morph.idN = vns.allocator.morphIdCount 
	level = level or 1
	morph.level = level
	vns.allocator.gene_index[morph.idN] = morph

	-- sum scale
	local sum = vns.ScaleManager.Scale:new()
	if morph.children ~= nil then
		for i, branch in ipairs(morph.children) do
			sum = sum + Allocator.calcMorphChildrenScale(vns, branch, level + 1, globalTransform)
		end
	end
	if sum[morph.robotTypeS] == nil then
		sum[morph.robotTypeS] = 1
	else
		sum[morph.robotTypeS] = sum[morph.robotTypeS] + 1
	end
	morph.scale = sum
	return sum
end

function Allocator.calcMorphParentScale(vns, morph)
	if morph.parentScale == nil then
		morph.parentScale = vns.ScaleManager.Scale:new()
	end
	local sum = morph.parentScale + morph.scale
	if morph.children ~= nil then
		for i, branch in ipairs(morph.children) do
			branch.parentScale = sum - branch.scale
		end
		for i, branch in ipairs(morph.children) do
			Allocator.calcMorphParentScale(vns, branch)
		end
	end
end

-------------------------------------------------------------------------------
function Allocator.create_allocator_node(vns)
	return function()
		Allocator.step(vns)
		return false, true
	end
end

return Allocator
