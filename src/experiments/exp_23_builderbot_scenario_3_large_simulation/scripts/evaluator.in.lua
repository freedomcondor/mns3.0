package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
local logReader = require("logReader")
local recruitLogReader = require("RecruitLogReader")
logger.enable()

-- Read logs
local robotsData = logReader.loadData("./logs", {"drone", "pipuck", "builderbot"})

logReader.saveSoNSNumber(robotsData, "SoNSNumber.dat")
logReader.saveAverageSoNSSize(robotsData, "SoNSSize.dat")

logReader.saveStateSize(robotsData, "forward",       "result_forward_size.dat")
logReader.saveStateSize(robotsData, "meet_obstacle", "result_meet_obstacle_size.dat")
logReader.saveStateSize(robotsData, "send_help",     "result_send_help_size.dat")
logReader.saveStateSize(robotsData, "wait_to_help",  "result_wait_to_help_size.dat")
logReader.saveStateSize(robotsData, "helping",       "result_helping_size.dat")
logReader.saveStateSize(robotsData, "move_left",     "result_move_left_size.dat")
logReader.saveStateSize(robotsData, "forward_2",     "result_forward_2_size.dat")

logReader.saveLearnerLength(robotsData, "learner_length.dat")

-- read recruit logs
recruitRobotsData = recruitLogReader.loadData("logs_recruit")
recruitResultData = recruitLogReader.sumData(recruitRobotsData)
recruitLogReader.saveData(recruitResultData, "recruit.dat")
