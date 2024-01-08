package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

-- Read type
local experimentType = logReader.getFirstLineFromFile("type.txt")
print("experiment type : ", experimentType)

-- Read morphologies
local structure_search = require("morphology_2")
local structure4 = require("morphology_4")
local structure8 = require("morphology_8")
local structure12 = require("morphology_12")
local structure12_rec = require("morphology_12_rec")
local structure12_tri = require("morphology_12_tri")
local structure20 = require("morphology_20")
local structure20_toSplit = require("morphology_20_toSplit")

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_search,
		structure4,
		structure8,
		structure12,
		structure12_rec,
		structure12_tri,
		structure20,
		structure20_toSplit,
	}
}

local geneIndex = logReader.calcMorphID(gene)

-- Read logs
local robotsData = logReader.loadData("./logs")


-- check key steps
local firstRecruitStep = logReader.calcFirstRecruitStep(robotsData)
local saveStartStep = firstRecruitStep + 10
print("firstRecruit happens", firstRecruitStep, "data start at", saveStartStep) 

-- split step
local stageSplitStep = logReader.checkIDFirstAppearStep(robotsData, structure20_toSplit.idN, saveStartStep)
print("splitStep = ", stageSplitStep)

-- combine step
local smallCircleStep = logReader.checkIDFirstAppearStep(robotsData, structure12.idN, stageSplitStep)
local bigCircleAgainStep = logReader.checkIDFirstAppearStep(robotsData, structure20.idN, smallCircleStep)

splitStableStep = math.floor((smallCircleStep + bigCircleAgainStep) / 2)
print("stableSplitStep = ", splitStableStep)

local combineStep = logReader.checkIDFirstAppearStep(robotsData, -1, splitStableStep) - 5
print("combineStep = ", combineStep)

-- divide group
local groups = logReader.divideIntoGroups(robotsData, splitStableStep, {structure12.idN, structure8.idN})

-- print verify groups
print("group number = ", #groups)

  -- count group 1
local count = 0
for i, v in pairs(groups[1]) do
	count = count + 1
end
print("group 1 has ", count, "robots")

  -- count group 2
local count = 0
for i, v in pairs(groups[2]) do
	count = count + 1
end
print("group 2 has ", count, "robots")

------- calc errors

-- before split
logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(robotsData, geneIndex, false, false, saveStartStep, stageSplitStep-1)
logReader.saveData(robotsData, "result_data_1.txt", "error", saveStartStep, stageSplitStep-1)
logReader.saveEachRobotData(robotsData, "result_each_robot_error_1", "error", saveStartStep, stageSplitStep-1)

-- after split right
logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(groups[2], geneIndex, false, false, stageSplitStep, combineStep-1)
logReader.saveData(groups[2], "result_data_2_right.txt", "error", stageSplitStep, combineStep-1)
logReader.saveEachRobotData(groups[2], "result_each_robot_error_2_right", "error", stageSplitStep, combineStep-1)

-- combine
logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(robotsData, geneIndex, false, false, combineStep)
logReader.saveData(robotsData, "result_data_3.txt", "error", combineStep)
logReader.saveEachRobotData(robotsData, "result_each_robot_error_3", "error", combineStep)


-- calculate split left based experiment type at last
if experimentType == "left" then
	local changeToCircle = logReader.checkIDFirstAppearStep(robotsData, structure12.idN, stageSplitStep)

	logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(groups[1], geneIndex, false, false, stageSplitStep, changeToCircle-1)
	logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(groups[1], geneIndex, false, false, changeToCircle, combineStep-1)

	logReader.saveData(groups[1], "result_data_2_left.txt", "error", stageSplitStep, combineStep-1)
	logReader.saveEachRobotData(groups[1], "result_each_robot_error_2_left", "error", stageSplitStep, combineStep-1)
elseif experimentType == "right" then
	local changeToTriangle = logReader.checkIDFirstAppearStep(robotsData, structure12_tri.idN, stageSplitStep)
	local changeToCircle = logReader.checkIDFirstAppearStep(robotsData, structure12.idN, changeToTriangle)

	logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(groups[1], geneIndex, false, false, stageSplitStep, changeToTriangle-1)
	logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(groups[1], geneIndex, false, false, changeToTriangle, changeToCircle-1)
	logReader.calcSegmentDataWithFailureCheckAndGoalReferenceOption(groups[1], geneIndex, false, false, changeToCircle, combineStep-1)

	logReader.saveData(groups[1], "result_data_2_left.txt", "error", stageSplitStep, combineStep-1)
	logReader.saveEachRobotData(groups[1], "result_each_robot_error_2_left", "error", stageSplitStep, combineStep-1)
end

-- getFastestSpeed for each step
--[[
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
--]]