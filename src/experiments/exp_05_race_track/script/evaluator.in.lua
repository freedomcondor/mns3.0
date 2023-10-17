package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local type = logReader.getFirstLineFromFile("type.txt")
print("experiment type : ", type)

local robotsData = logReader.loadData("./logs")

local firstRecruitStep = logReader.calcFirstRecruitStep(robotsData)
local saveStartStep = firstRecruitStep + 10
print("firstRecruit happens", firstRecruitStep, "data start at", saveStartStep)

-- getFastestSpeed for each step
local fastestSpeeds = {}
local slowestSpeeds = {}
local averageSpeeds = {}
local startStep = 1
local endStep = logReader.getEndStep(robotsData)
for step = saveStartStep + 1, endStep do
	local fastestSpeed = 0
	local slowestSpeed = math.huge
	local averageSum = 0
	local averageN = 0
	for robotName, robotData in pairs(robotsData) do
		local robotSpeed = (robotData[step].positionV3 - robotData[step-1].positionV3):len() / 0.2
		averageSum = averageSum + robotSpeed
		averageN = averageN + 1
		if robotSpeed > fastestSpeed then
			fastestSpeed = robotSpeed
		end
		if robotSpeed < slowestSpeed then
			slowestSpeed = robotSpeed
		end
	end
	table.insert(fastestSpeeds, fastestSpeed)
	table.insert(slowestSpeeds, slowestSpeed)
	table.insert(averageSpeeds, averageSum / averageN)
end

logReader.savePlainData(fastestSpeeds, "result_fastestSpeed_data.txt")
logReader.savePlainData(slowestSpeeds, "result_slowestSpeed_data.txt")
logReader.savePlainData(averageSpeeds, "result_averageSpeed_data.txt")