package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

-- Experiment_type is discrete or continuous
local Experiment_type = logReader.getFirstLineFromFile("type.txt")
print("experiment type : ", Experiment_type)

require("morphologyGenerateCube")
local structure = generate_cube_morphology(64)

local geneIndex = logReader.calcMorphID(structure)

local robotsData = logReader.loadData("./logs")

-- calculate distance to goals
local_errors = {}
for step = 1, logReader.getEndStep(robotsData) do
	local total_distances = 0
	local n = 0
	for robotName, robotData in pairs(robotsData) do
		local goalPosition = robotData[step].goalPositionV3
		local currentPosition = robotData[step].positionV3
		local distance = (robotData[step].goalPositionV3 -
		                  robotData[step].positionV3
		                 ):len()
		
		robotData[step].goalError = distance
		total_distances = total_distances + distance
		n = n + 1
	end
	local_errors[step] = total_distances / n
end

logReader.savePlainData(local_errors, "result_local_errors_average.txt")
logReader.saveData(robotsData, "result_local_errors.txt", "goalError")
logReader.saveEachRobotData(robotsData, "result_eachRobotGoalError", "goalError")
