RecruitLogReader = {}

function RecruitLogReader.getCSVList(dir, typelist)
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
		if ext == "recruitlog" and typelistIndex[robot] == true then table.insert(robotNameList, name) end
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

function RecruitLogReader.readLine(str)
	-- read line and return a structure table
	local strList = {};
	string.gsub(str, '[^,]+', function(w) table.insert(strList, w) end);
	local stepData = {
		drone = tonumber(strList[1]),
		pipuck = tonumber(strList[2]),
		builderbot = tonumber(strList[3]),
	}

	return stepData
end

function RecruitLogReader.loadData(dir, typelist)
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
	local robotNameList = RecruitLogReader.getCSVList(dir, typelist)
	-- for each robot
	local robotsData = {}
	local stepNumber = nil
	for i, robotName in ipairs(robotNameList) do
		-- open file
		local filename = dir .. "/" .. robotName .. ".recruitlog"
		--print("loading " .. filename)
		local f = io.open(filename, "r")
		if f == nil then print("load file " .. filename .. " error") return end
		-- for each line
		robotData = {}
		local count = 0
		for l in f:lines() do 
			count = count + 1
			--print("reading line", count)
			table.insert(robotData, RecruitLogReader.readLine(l)) 
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

function RecruitLogReader.getEndStep(robotsData)
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	return length
end

function RecruitLogReader.sumData(robotsData, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then 
		endStep = RecruitLogReader.getEndStep(robotsData)
	end

	local sumResult = {}
	-- calc data
	print("startStep = ", startStep)
	print("endStep = ", endStep)
	for step = startStep, endStep do
		sumResult[step] = { drone = 0, pipuck = 0, builderbot = 0, }
		for robotName, robotData in pairs(robotsData) do
			sumResult[step].drone      = sumResult[step].drone      + robotData[step].drone
			sumResult[step].pipuck     = sumResult[step].pipuck     + robotData[step].pipuck
			sumResult[step].builderbot = sumResult[step].builderbot + robotData[step].builderbot
		end
	end
	return sumResult
end

function RecruitLogReader.saveData(sumResult, saveFile, startStep, endStep)
	local startStep = startStep or 1
	local endStep = endStep or #sumResult
	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		f:write(tostring(sumResult[step].drone)..", ")
		f:write(tostring(sumResult[step].pipuck)..", ")
		f:write(tostring(sumResult[step].builderbot).."\n")
	end
	io.close(f)
end

return RecruitLogReader