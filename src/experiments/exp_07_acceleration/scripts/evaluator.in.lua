package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local type = logReader.getFirstLineFromFile("type.txt")
print("experiment type : ", type)

require("morphologyGenerateCube")
local structure
if type == "cube_27" then
	structure = generate_cube_morphology(27)
elseif type == "cube_64" then
	structure = generate_cube_morphology(64)
elseif type == "cube_125" then
	structure = generate_cube_morphology(125)
elseif type == "cube_216" then
	structure = generate_cube_morphology(216)
elseif type == "cube_512" then
	structure = generate_cube_morphology(512)
elseif type == "cube_1000" then
	structure = generate_cube_morphology(1000)
end

local geneIndex = logReader.calcMorphID(structure)

local robotsData = logReader.loadData("./logs")

local firstRecruitStep = logReader.calcFirstRecruitStep(robotsData)
local saveStartStep = firstRecruitStep + 10
print("firstRecruit happens", firstRecruitStep, "data start at", saveStartStep)

logReader.calcSegmentData(robotsData, geneIndex)
logReader.saveData(robotsData, "result_data.txt", "error", saveStartStep)
logReader.saveEachRobotData(robotsData, "result_each_robot_error", "error", saveStartStep)


-- calculate distance to goals
local_errors = {}
for step = saveStartStep, logReader.getEndStep(robotsData) do
	local total_distances = 0
	local n = 0
	for robotName, robotData in pairs(robotsData) do
		local goalPosition = robotData[step].goalPositionV3
		local currentPosition = robotData[step].positionV3
		local distance = (robotData[step].goalPositionV3 -
		                  robotData[step].positionV3
		                 ):len()
		total_distances = total_distances + distance
		n = n + 1
	end
	local_errors[step] = total_distances / n
end

logReader.savePlainData(local_errors, "result_local_errors.txt", saveStartStep, endStep)
