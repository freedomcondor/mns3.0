package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
local logReader = require("logReader")
local recruitLogReader = require("RecruitLogReader")
logger.enable()

-- Read type
local experimentType = logReader.getFirstLineFromFile("type.txt")
print("experiment type : ", experimentType)

-- Read logs
--local robotsData = logReader.loadData("./logs", {"pipuck", "builderbot"})
local robotsData = logReader.loadData("./logs", {"pipuck"})

logReader.saveSoNSNumber(robotsData, "SoNSNumber.dat")
logReader.saveAverageSoNSSize(robotsData, "SoNSSize.dat")

logReader.saveStateSize(robotsData, "wait_to_forward", "result_wait_to_forward_size.dat")
logReader.saveStateSize(robotsData, "forward", "result_forward_size.dat")
logReader.saveStateSize(robotsData, "wait_to_forward_2", "result_wait_to_forward_2_size.dat")
logReader.saveStateSize(robotsData, "forward_2", "result_forward_2_size.dat")
logReader.saveStateSize(robotsData, "wait_for_obstacle_clearance", "result_wait_for_obstacle_clearance_size.dat")
logReader.saveStateSize(robotsData, "push", "result_push_size.dat")

logReader.saveLearnerLength(robotsData, "learner_length.dat")

-- calculate non-push average goal distance
local f = io.open("non_push_average_error.dat", "w")
local g = io.open("push_average_error.dat", "w")
for step = 1, logReader.getEndStep(robotsData) do
	-- for all robots, check state
	local size = 0
	local sum_error = 0

	local push_size = 0
	local push_sum_error = 0

	for robotName, robotData in pairs(robotsData) do
		if robotData[step].state ~= "push" then
			size = size + 1
			sum_error = sum_error + robotData[step].originGoalPositionV3:len()
		else
			push_size = push_size + 1
			push_sum_error = push_sum_error + robotData[step].originGoalPositionV3:len()
		end
	end

	local average = sum_error / size
	f:write(tostring(average).."\n")

	local average_push_error = 0
	if push_size ~= 0 then
		average_push_error = push_sum_error / push_size
	end
	g:write(tostring(average_push_error).."\n")
end
io.close(f)
print("save non_push_average_error finish")

-- read recruit logs
--recruitRobotsData = recruitLogReader.loadData("logs_recruit")
--recruitResultData = recruitLogReader.sumData(recruitRobotsData)
--recruitLogReader.saveData(recruitResultData, "recruit.dat")