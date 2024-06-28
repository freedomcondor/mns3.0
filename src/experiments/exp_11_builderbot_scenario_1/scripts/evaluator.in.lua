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
local robotsData = logReader.loadData("./logs", {"drone", "pipuck", "builderbot"})

logReader.saveSoNSNumber(robotsData, "SoNSNumber.dat")
logReader.saveAverageSoNSSize(robotsData, "SoNSSize.dat")

logReader.saveStateSize(robotsData, "consensus_0", "consensus_0_size.dat")
logReader.saveStateSize(robotsData, "consensus_1", "consensus_1_size.dat")
logReader.saveStateSize(robotsData, "consensus_2", "consensus_2_size.dat")
logReader.saveStateSize(robotsData, "consensus_3", "consensus_3_size.dat")
logReader.saveStateSize(robotsData, "start_push", "start_push_size.dat")

logReader.saveLearnerLength(robotsData, "learner_length.dat")

-- read recruit logs
recruitRobotsData = recruitLogReader.loadData("logs_recruit")
recruitResultData = recruitLogReader.sumData(recruitRobotsData)
recruitLogReader.saveData(recruitResultData, "recruit.dat")