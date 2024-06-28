--require("lfs")
vector3 = require('Vector3')
quaternion = require('Quaternion')

logReader = {}
function logReader.getFirstLineFromFile(file)
	local f = io.open(file, "r")
	local word
	for file in f:lines() do 
		word = file
		break
	end
	io.close(f)
	return word
end

function logReader.getCSVList(dir, typelist)
	-- create a typelist index
	-- from {"drone", "pipuck"} to {drone = true, pipuck = true}
	if typelist == nil then typelist = {"drone", "pipuck"} end
	local typelistIndex = {}
	for i, v in ipairs(typelist) do
		typelistIndex[v] = true
	end
	-- ls dir > fileList.txt and read fileList.txt
	-- so that we don't have to depend on lfs to get files in a dir
	os.execute("ls " .. dir .. " > fileList.txt")
	local f = io.open("fileList.txt", "r")
	local robotNameList = {}
	for file in f:lines() do 
		-- drone11.log for example
		local name, ext = string.match(file, "([^.]+).([^.]+)")
		-- name = drone11, ext = log
		local robot, number = string.match(name, "(%a+)(%d+)")
		-- robot = drone, number = 11
		if ext == "log" and typelistIndex[robot] == true then table.insert(robotNameList, name) end
	end
	io.close(f)
	os.execute("rm fileList.txt")
	return robotNameList
	--[[
	local robotNameList = {}
	for file in lfs.dir(dir) do
		name, ext = string.match(file, "([^.]+).([^.]+)")
		if ext == "csv" then table.insert(robotNameList, name) end
	end
	return robotNameList
	--]]
end

function logReader.readLine(str)
	-- read line and return a structure table
	local strList = {};
	string.gsub(str, '[^,]+', function(w) table.insert(strList, w) end);
	local stepData = {
		--stepCount = tonumber(strList[1]),
		positionV3 = vector3(tonumber(strList[1]),
		                     tonumber(strList[2]),
		                     tonumber(strList[3])
		                    ),
		-- order of euler angles are z, y, x
		orientationQ = (quaternion(1,0,0, tonumber(strList[6]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[5]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[4]) * math.pi / 180)
		               ) *
		               (quaternion(1,0,0, tonumber(strList[9]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[8]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[7]) * math.pi / 180)
		               ),
		goalPositionV3 = vector3(tonumber(strList[10]),
		                         tonumber(strList[11]),
		                         tonumber(strList[12])
		                        ),
		goalOrientationQ = (quaternion(1,0,0, (tonumber(strList[15]) or 0) * math.pi / 180) *
		                    quaternion(0,1,0, (tonumber(strList[14]) or 0) * math.pi / 180) *
		                    quaternion(0,0,1, (tonumber(strList[13]) or 0) * math.pi / 180)
		                   ),
		targetID = tonumber(strList[16]),
		brainID = strList[17],
		parentID = strList[18],
		state = strList[19],
		learnerLength = strList[20],
	}
	stepData.originGoalPositionV3 = stepData.goalPositionV3
	stepData.originGoalOrientationQ = stepData.goalOrientationQ

	stepData.goalPositionV3 = stepData.positionV3 + stepData.orientationQ:toRotate(stepData.goalPositionV3)
	stepData.goalOrientationQ = stepData.orientationQ * stepData.goalOrientationQ

	return stepData
end

function logReader.loadData(dir, typelist)
	-- read typelist example: {"drone", "pipuck"}
	-- read all drone*.log and pipuck*.log files, and return a table
	-- {
	--      drone1 = {
	--                  1 = {stepCount, positionV3 ...}
	--                  2 = {stepCount, positionV3 ...}
	--               }
	--      drone2 = { 
	--                  1 = {stepCount, positionV3 ...}
	--                  2 = {stepCount, positionV3 ...}
	--               }
	-- } 
	--
	local robotNameList = logReader.getCSVList(dir, typelist)
	-- for each robot
	local robotsData = {}
	local stepNumber = nil
	for i, robotName in ipairs(robotNameList) do
		-- open file
		local filename = dir .. "/" .. robotName .. ".log"
		--print("loading " .. filename)
		local f = io.open(filename, "r")
		if f == nil then print("load file " .. filename .. " error") return end
		-- for each line
		robotData = {}
		local count = 0
		for l in f:lines() do 
			count = count + 1
			--print("reading line", count)
			table.insert(robotData, logReader.readLine(l)) 
		end
		-- close file
		io.close(f)
		-- tune stepNumber
		if i == 1 then
			stepNumber = count
		elseif count + 1 == stepNumber then
			print(robotName, "less 1 step")
			table.insert(robotData, robotData[#robotData])
		elseif count == stepNumber + 1 then
			print(robotName, "more 1 step")
			robotData[#robotData] = nil
		elseif count ~= stepNumber then
			print(robotName, "something wrong: count = ", count, "stepNumber = ", stepNumber)
		end
		-- record data
		robotsData[robotName] = robotData
		--[[
		for i, v in ipairs(robotData) do
			print("step", i)
			print("\tstepCount", v.stepCount)
			print("\tpositionV3", v.positionV3)
			print("\torientationQ", v.orientationQ)
			print("\ttargetID", v.targetID)
			print("\tbrainID", v.brainID)
		end
		--]]
	end
	print("load data finish")
	return robotsData
end

function logReader.getEndStep(robotsData)
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	return length
end

function logReader.smoothRobotData(stepTable, window)
	--stepTable = {
	--      1 = {positionV3, orientationQ, goalPositionV3, goalOrientationQ}
	--      2 = {positionV3, orientationQ, goalPositionV3, goalOrientationQ}
	--}
	local smoothedData = {}
	local posAcc = vector3(0,0,0)
	local posAcc_n = 0
	local goalAcc = vector3(0,0,0)
	local goalAcc_n = 0
	for i, stepData in ipairs(stepTable) do
		smoothedData[i] = {
			orientationQ     = quaternion:createFromHardValue(vector3(stepTable[i].orientationQ.v), stepTable[i].orientationQ.w),
			goalOrientationQ = quaternion:createFromHardValue(vector3(stepTable[i].goalOrientationQ.v), stepTable[i].goalOrientationQ.w),
			targetID = stepTable[i].targetID,
			brainID  = stepTable[i].brainID,
		}

		posAcc  = posAcc  + stepTable[i].positionV3
		goalAcc = goalAcc + stepTable[i].goalPositionV3
		posAcc_n  = posAcc_n  + 1
		goalAcc_n = goalAcc_n + 1

		if i - window > 0 then
			posAcc  = posAcc  - stepTable[i - window].positionV3
			goalAcc = goalAcc - stepTable[i - window].goalPositionV3
			posAcc_n  = posAcc_n  - 1
			goalAcc_n = goalAcc_n - 1
		end

		smoothedData[i].positionV3     = posAcc  * (1.0 / posAcc_n)
		smoothedData[i].goalPositionV3 = goalAcc * (1.0 / goalAcc_n)
	end
	return smoothedData
end

function logReader.smoothData(robotsData, window)
	for robotName, stepTable in pairs(robotsData) do
		if robotName == "drone1" then
			logger(robotName)
			logger("before")
			logger(robotsData[robotName][1000])
		end
		robotsData[robotName] = logReader.smoothRobotData(stepTable, window)
		if robotName == "drone1" then
			logger("after")
			logger(robotsData[robotName][1000])
		end
	end
end

function logReader.calcFirstRecruitStep(robotsData, saveFile)
	local SoNSs = nil
	local step = 0
	while true do
		step = step + 1

		local brainIndex = {}
		for robotName, robotData in pairs(robotsData) do
			if robotData[step] == nil then
				return step - 1
			end
			if robotData[step].failed == nil then
				local brainID = robotData[step].brainID
				brainIndex[brainID] = true
			end
		end
		-- count brainIndex
		local count = 0
		for id, value in pairs(brainIndex) do
			count = count + 1
		end

		if SoNSs == nil then
			SoNSs = count
		else
			if SoNSs ~= count then
				return step
			end
		end
	end
end

function logReader.saveStateSize(robotsData, state, saveFile, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then
		endStep = logReader.getEndStep(robotsData)
	end

	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		-- for all robots, check state
		local size = 0
		for robotName, robotData in pairs(robotsData) do
			if robotData[step].failed == nil and
			   robotData[step].state == state then
				size = size + 1
			end
		end
		f:write(tostring(size).."\n")
	end
	io.close(f)
	print("save state size finish, state: ", state)
end

function logReader.saveAverageSoNSSize(robotsData, saveFile, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then
		endStep = logReader.getEndStep(robotsData)
	end

	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		-- put all brain to brainIndex
		local brainIndex = {}
		for robotName, robotData in pairs(robotsData) do
			if robotData[step].failed == nil then
				local brainID = robotData[step].brainID
				if brainIndex[brainID] == nil then
					brainIndex[brainID] = 1
				else
					brainIndex[brainID] = brainIndex[brainID] + 1
				end
			end
		end
		-- average brainIndex
		local total = 0
		local number = 0
		for brainID, value in pairs(brainIndex) do
			number = number + 1
			total = total + value
		end
		local average = total / number
		f:write(tostring(average).."\n")
	end
	io.close(f)
	print("save average SoNS size finish")
end

function logReader.saveLearnerLength(robotsData, saveFile, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then
		endStep = logReader.getEndStep(robotsData)
	end

	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		-- for all robots, sum learner length
		local length = 0
		for robotName, robotData in pairs(robotsData) do
			if robotData[step].failed == nil then
				length = length + robotData[step].learnerLength
			end
		end
		f:write(tostring(length).."\n")
	end
	io.close(f)
	print("save learner length finish")
end

function logReader.saveSoNSNumber(robotsData, saveFile, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then 
		endStep = logReader.getEndStep(robotsData)
	end

	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		-- put all brain to brainIndex
		local brainIndex = {}
		for robotName, robotData in pairs(robotsData) do
			if robotData[step].failed == nil then
				local brainID = robotData[step].brainID
				brainIndex[brainID] = true
			end
		end
		-- count brainIndex
		local count = 0
		for id, value in pairs(brainIndex) do
			count = count + 1
		end
		f:write(tostring(count).."\n")
	end
	io.close(f)
	print("save SoNSNumber finish")
end

function logReader.markFailedRobot(robotsData, endStep)
	for robotName, robotData in pairs(robotsData) do
		if robotData[endStep].originGoalPositionV3:XYequ(robotData[endStep-1].originGoalPositionV3) == true and
		   robotData[endStep-1].originGoalPositionV3:XYequ(robotData[endStep-2].originGoalPositionV3) == true and
		   robotData[endStep-2].originGoalPositionV3:XYequ(robotData[endStep-3].originGoalPositionV3) == true and
		   robotData[endStep].originGoalOrientationQ == robotData[endStep-1].originGoalOrientationQ and
		   robotData[endStep-1].originGoalOrientationQ == robotData[endStep-2].originGoalOrientationQ and
		   robotData[endStep-2].originGoalOrientationQ == robotData[endStep-3].originGoalOrientationQ and
		   ((robotData[endStep].originGoalPositionV3 ~= vector3() 
		     and
		     robotData[endStep].originGoalOrientationQ ~= quaternion()
		    ) 
		    or 
		    robotData[endStep].brainID ~= robotName
		   ) then
			robotData[endStep].failed = true
			print(robotName, "failed at", endStep)
		end
	end
end

function logReader.saveFailedRobot(robotsData, saveFile)
	-- fill start and end if not provided
	local startStep = startStep or 1
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	local endStep = endStep or length

	local f = io.open(saveFile, "w")
	for robotName, robotData in pairs(robotsData) do
		if robotData[endStep].failed == true then
			f:write(robotName .."\n")
		end
	end
	io.close(f)
	print("save failed robot finish")
end

function logReader.calcSegmentData(robotsData, geneIndex, startStep, endStep)
	logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(robotsData, geneIndex, false, true, startStep, endStep)
end

function logReader.calcSegmentDataWithFailureCheck(robotsData, geneIndex, startStep, endStep)
	logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(robotsData, geneIndex, true, true, startStep, endStep)
end

function logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(robotsData, geneIndex, failureCheckOption, goalReferenceOption, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then 
		endStep = logReader.getEndStep(robotsData)
	end

	if failureCheckOption == true then
		logReader.markFailedRobot(robotsData, endStep)
	end
	-- count last frame swarm size
	for robotName, robotData in pairs(robotsData) do
		robotData[endStep].swarmSize = 0
	end
	for robotName, robotData in pairs(robotsData) do
		if robotData[endStep].failed == nil then
			local brainName = robotData[endStep].brainID
			if robotsData[brainName] == nil then
				print(robotName, "'s brain is", brainName)
			end
			robotsData[brainName][endStep].swarmSize = robotsData[brainName][endStep].swarmSize + 1
		end
	end
	-- after count,  robotsData["Drone1"][endStep].swarmSize = size
	-- but non-brain robotsData["pipuck5"][endStep].swarmSize = 0

	-- calc data
	for step = startStep, endStep do
		for robotName, robotData in pairs(robotsData) do
			local brainName = robotData[endStep].brainID
			local brainData = robotsData[brainName]
			robotData[step].swarmSize = brainData[endStep].swarmSize 
			robotData[step].failed = robotData[endStep].failed
			if robotData[step].failed == true then robotData[step].swarmSize = 0 end

			-- the predator, targetID == nil, consider its error is always 0
			local targetRelativePositionV3 = geneIndex[robotData[endStep].targetID or 1].globalPositionV3
			--local targetGlobalPositionV3 = brainData[step].positionV3 +
			--                               brainData[step].orientationQ:toRotate(targetRelativePositionV3)
			local targetGlobalPositionV3 = brainData[step].goalPositionV3 +
			                               brainData[step].goalOrientationQ:toRotate(targetRelativePositionV3)
			if goalReferenceOption == false then
				targetGlobalPositionV3 = brainData[step].positionV3 +
				                         brainData[step].orientationQ:toRotate(targetRelativePositionV3)
			end

			local disV3 = targetGlobalPositionV3 - robotData[step].positionV3
			--local disV3 = targetGlobalPositionV3 - robotData[step].goalPositionV3
			disV3.z = 0
			robotData[step].error = disV3:len()
			--[[
			if step == endStep then
				print("robotName = ", robotName)
				print("brainPosition = ", brainData[step].positionV3)
				print("brainOrientationQ = X", brainData[step].orientationQ:toRotate(vector3(1,0,0)))
				print("                    Y", brainData[step].orientationQ:toRotate(vector3(0,1,0)))
				print("                    Z", brainData[step].orientationQ:toRotate(vector3(0,0,1)))
				print("targetRelativePositionV3 = ", targetRelativePositionV3)
				print("targetGlobalPositionV3 = ", targetGlobalPositionV3)
				print("myPosition = ", robotData[step].positionV3)
				print("disV3 = ", disV3)
				print("dis = ", disV3:len())
			end
			--]]
		end
	end
	print("calcSegmentData finish")
end

function logReader.calcSegmentLowerBound(robotsData, geneIndex, parameters, startStep, endStep)
	logReader.calcSegmentNewLowerBound(robotsData, geneIndex, parameters, startStep, endStep)

	local time_period = parameters.time_period;
	local default_speed = parameters.default_speed;
	local slowdown_dis = parameters.slowdown_dis;
	local stop_dis = parameters.stop_dis;
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then 
		local length
		for robotName, stepTable in pairs(robotsData) do
			length = #stepTable
			break
		end
		endStep = length
	end

	for step = startStep, endStep do
		for robotName, robotData in pairs(robotsData) do
			if step == startStep then
				robotData[step].lowerBoundError = robotData[step].error
			else
				local lowerBoundDis = robotData[step-1].lowerBoundError
				local speed = default_speed;
				if lowerBoundDis < stop_dis then
					speed = 0;
				elseif lowerBoundDis < slowdown_dis then
					speed = default_speed * lowerBoundDis / slowdown_dis;
				end

				if lowerBoundDis > 0 then
					lowerBoundDis = lowerBoundDis - time_period * speed;
				end
				robotData[step].lowerBoundError = lowerBoundDis
			end
		end
	end
end

function logReader.calcSegmentNewLowerBound(robotsData, geneIndex, parameters, startStep, endStep)
	local time_period = parameters.time_period;
	local default_speed = parameters.default_speed;
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then
		local length
		for robotName, stepTable in pairs(robotsData) do
			length = #stepTable
			break
		end
		endStep = length
	end

	for step = startStep, endStep do
		for robotName, robotData in pairs(robotsData) do
			if step == startStep then
				robotData[step].newLowerBoundError = robotData[step].error
			else
				local lowerBoundDis = robotData[step-1].newLowerBoundError
				local speed = default_speed;

				if lowerBoundDis > 0 then
					lowerBoundDis = lowerBoundDis - time_period * speed;
				end
				robotData[step].newLowerBoundError = lowerBoundDis
			end
		end
	end
end

function logReader.calcSegmentLowerBoundErrorInc(robotsData, geneIndex, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then 
		local length
		for robotName, stepTable in pairs(robotsData) do
			length = #stepTable
			break
		end
		endStep = length
	end


	for step = startStep, endStep do
		for robotName, robotData in pairs(robotsData) do
			if robotData[step].error == nil or
			   robotData[step].lowerBoundError == nil then
				print("error: error or lowerBoundError is nil")
			end
			robotData[step].lowerBoundInc = 
				robotData[step].error -
				robotData[step].lowerBoundError
		end
	end
end

function logReader.calcMinimumDistances(robotsData)
	local startStep = 1
	local endStep = logReader.getEndStep(robotsData)
	local distances = {}
	for step = startStep, endStep do
		local step_distance = math.huge
		for robotName1, robotData1 in pairs(robotsData) do
			for robotName2, robotData2 in pairs(robotsData) do
				if robotName1 ~= robotName2 then
					local dis = (robotData1[step].positionV3 - robotData2[step].positionV3):len()
					if dis < step_distance then step_distance = dis end
				end
			end
		end
		table.insert(distances, step_distance)
	end
	return distances
end

function logReader.savePlainData(plainData, saveFile, startStep, endStep)
	local startStep = startStep or 1
	local endStep = endStep or #plainData
	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		f:write(tostring(plainData[step]).."\n")
	end
	io.close(f)
end

function logReader.saveData(robotsData, saveFile, attribute, startStep, endStep)
	if attribute == nil then attribute = 'error' end
	if attribute == "lowerBoundError" then
		logReader.saveData(robotsData, "result_new_lowerbound_data.txt", "newLowerBoundError", startStep, endStep)
	end
	-- fill start and end if not provided
	local startStep = startStep or 1
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	local endStep = endStep or length

	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		local error = 0
		local n = 0
		for robotName, robotData in pairs(robotsData) do
			if robotData[step].failed == nil then
				error = error + robotData[step][attribute]
				n = n + 1
			end
		end
		error = error / n
		f:write(tostring(error).."\n")
	end
	io.close(f)
	print("save data finish")
end

function logReader.saveDataAveragedBySwarmSize(robotsData, saveFile, attribute, startStep, endStep)
	if attribute == nil then attribute = 'error' end
	-- fill start and end if not provided
	local startStep = startStep or 1
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	local endStep = endStep or length

	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		local error = 0
		for robotName, robotData in pairs(robotsData) do
			if robotData[step].failed == nil then
				error = error + robotData[step][attribute] / robotData[step].swarmSize
			end
		end
		f:write(tostring(error).."\n")
	end
	io.close(f)
	print("save data finish")
end

function logReader.saveEachRobotData(robotsData, saveFolder, attribute, startStep, endStep)
	logReader.saveEachRobotDataWithFailurePlaceHolder(robotsData, saveFolder, attribute, nil, startStep, endStep)
end

function logReader.saveEachRobotDataWithFailurePlaceHolder(robotsData, saveFolder, attribute, failPlaceHolder, startStep, endStep)
	if attribute == nil then attribute = 'error' end
	-- fill start and end if not provided
	local startStep = startStep or 1
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	local endStep = endStep or length

	os.execute("mkdir -p " .. saveFolder)
	for robotName, robotData in pairs(robotsData) do
		local pathName = saveFolder .. "/" .. robotName .. ".txt"
		local f = io.open(pathName, "w")
		for step = startStep, endStep do
			if robotData[step].failed == nil then
				f:write(tostring(robotData[step][attribute]).."\n")
			else
				--f:write(tostring(failPlaceHolder or 5.0).."\n")
				f:write(tostring(failPlaceHolder or robotData[step][attribute]).."\n")
			end
		end
		io.close(f)
	end
end

function logReader.saveEachRobotDataAveragedBySwarmSize(robotsData, saveFolder, attribute, startStep, endStep)
	if attribute == nil then attribute = 'error' end
	-- fill start and end if not provided
	local startStep = startStep or 1
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	local endStep = endStep or length

	os.execute("mkdir " .. saveFolder)
	for robotName, robotData in pairs(robotsData) do
		local pathName = saveFolder .. "/" .. robotName .. ".txt"
		local f = io.open(pathName, "w")
		for step = startStep, endStep do
			local data
			if robotData[step].failed == true then 
				data = 0
			else 
				data = robotData[step][attribute] / robotData[step].swarmSize
			end
			f:write(tostring(data).."\n")
		end
		io.close(f)
	end
end

------------------------------------------------------------------------
-- to fill each node in the gene with an id and its global position
--   input:  gene =   drone         output:  gene = drone id=1, globalPosition=xx
--                    /   \                         /   \
--                   /     \                       /     \
--               pipuck   drone                pipuck 2  drone 3
--
--   geneIndex = [1, 2, 3] pointing to matching branch
function logReader.calcMorphID(gene)
	local globalContainer = {id = 0}
	local geneIndex = {}
	gene.globalPositionV3 = vector3()
	gene.globalOrientationQ = quaternion()
	logReader.calcMorphChildrenID(gene, globalContainer, geneIndex)

	-- sometimes a robot may have -1 as target
	geneIndex[-1] = {
		globalPositionV3 = vector3(),
		globalOrientationQ = quaternion(),
	}

	return geneIndex
end

function logReader.calcMorphChildrenID(morph, globalContainer, geneIndex)
	globalContainer.id = globalContainer.id + 1
	morph.idN = globalContainer.id
	geneIndex[morph.idN] = morph

	if morph.children ~= nil then
		for i, child in ipairs(morph.children) do
			child.globalPositionV3 = morph.globalPositionV3 + morph.globalOrientationQ:toRotate(child.positionV3)
			child.globalOrientationQ = morph.globalOrientationQ * child.orientationQ
			logReader.calcMorphChildrenID(child, globalContainer, geneIndex)
		end
	end
end

function logReader.checkIDFirstAppearStep(robotsData, ID, startStep, specificRobotName)
	-- get end step
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end

	if startStep == nil then startStep = 1 end
	for i = startStep, length do
		for robotName, robotData in pairs(robotsData) do
			if robotData[i].targetID == ID then
				if specificRobotName == nil or specificRobotName == robotName then
					return i, robotName
				end
			end
		end
	end

	return length
end

function logReader.checkIDLastDisAppearStep(robotsData, ID, endStep, specificRobotName)
	-- get end step
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end

	if endStep == nil then endStep = length end
	for i = endStep, 1, -1 do
		-- check ID exists
		local flag = false
		for robotName, robotData in pairs(robotsData) do
			if robotData[i].targetID == ID then
				if specificRobotName == nil or specificRobotName == robotName then
					flag = true
					break
				end
			end
		end
		if flag == false then
			local disappearStep = i
			if disappearStep ~= endStep then
				disappearStep = disappearStep + 1
			end
			return disappearStep
		end
	end

	return length
end
------------------------------------------------------------------------

function logReader.divideIntoGroups(robotsData, stableStep, IDMarkersTable)
	local groups = {}
	for i, IDMarker in ipairs(IDMarkersTable) do
		table.insert(groups, {})
	end

	for robotName, robotData in pairs(robotsData) do
		for i, IDMarker in ipairs(IDMarkersTable) do
			local brainName = robotData[stableStep].brainID
			if robotsData[brainName][stableStep].targetID == IDMarker then
				groups[i][robotName] = robotData
			end
		end
	end

	return groups
end

return logReader
