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
local robotsData = logReader.loadData("./logs", {"pipuck", "builderbot"})

logReader.saveSoNSNumber(robotsData, "SoNSNumber.dat")
logReader.saveAverageSoNSSize(robotsData, "SoNSSize.dat")

logReader.saveStateSize(robotsData, "wait_to_forward", "result_wait_to_forward_size.dat")
logReader.saveStateSize(robotsData, "forward", "result_forward_size.dat")
logReader.saveStateSize(robotsData, "wait_to_forward_2", "result_wait_to_forward_2_size.dat")
logReader.saveStateSize(robotsData, "forward_2", "result_forward_2_size.dat")
logReader.saveStateSize(robotsData, "wait_for_obstacle_clearance", "result_wait_for_obstacle_clearance_size.dat")
logReader.saveStateSize(robotsData, "push", "result_push_size.dat")

logReader.saveLearnerLength(robotsData, "learner_length.dat")

-- read recruit logs
recruitRobotsData = recruitLogReader.loadData("logs_recruit")
recruitResultData = recruitLogReader.sumData(recruitRobotsData)
recruitLogReader.saveData(recruitResultData, "recruit.dat")