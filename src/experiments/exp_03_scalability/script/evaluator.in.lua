package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local type = logReader.getFirstLineFromFile("type.txt")
print("experiment type : ", type)

require("morphologyGenerateTetrahedron")
require("morphologyGenerateCube")

local n_drone
local n_left_drone
if type == "cube_27" then
	n_drone = 27
	n_left_drone = 8
elseif type == "cube_64" then
	n_drone = 64
	n_left_drone = 27
elseif type == "cube_125" then
	n_drone = 125
	n_left_drone = 64
elseif type == "cube_216" then
	n_drone = 216
	n_left_drone = 125
end

local n_right_drone = n_drone - n_left_drone

n_side = math.ceil(n_drone ^ (1/3))

local structure_full = generate_cube_morphology(n_drone, n_left_drone)
local structure_left = generate_cube_morphology(n_left_drone)
local structure_right, n_right_side = generate_tetrahedron_morphology(n_right_drone)

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure_full,
		structure_left,
		structure_right,
	}
}

local geneIndex = logReader.calcMorphID(gene)

local robotsData = logReader.loadData("./logs")

local firstRecruitStep = logReader.calcFirstRecruitStep(robotsData)
local saveStartStep = firstRecruitStep + 10
print("firstRecruit happens", firstRecruitStep, "data start at", saveStartStep)

local stage2Step = logReader.checkIDFirstAppearStep(robotsData, structure_right.idN, saveStartStep)
local stage3Step = logReader.checkIDFirstAppearStep(robotsData, structure_full.idN, stage2Step)
-- check carefully for the combine time, by checking the first recruit between two groups.
-- the first recruited robot will have targetID -1
local stableStep = math.floor((stage2Step + stage3Step) / 2)
local stage3Step = logReader.checkIDFirstAppearStep(robotsData, -1, stableStep) - 5

print("stage2 start at", stage2Step)
print("stage3 start at", stage3Step)

os.execute("echo " .. tostring(stage2Step - saveStartStep) .. " > formationSwitch.txt")
os.execute("echo " .. tostring(stage3Step - saveStartStep) .. " >> formationSwitch.txt")

-- divide group
local groups = logReader.divideIntoGroups(robotsData, stage3Step-1, {structure_left.idN, structure_right.idN})

print("How many groups", #groups)

logReader.calcSegmentData(robotsData, geneIndex, saveStartStep, stage2Step-1)
logReader.calcSegmentData(groups[1], geneIndex, stage2Step, stage3Step-1)
logReader.calcSegmentData(groups[2], geneIndex, stage2Step, stage3Step-1)
logReader.calcSegmentData(robotsData, geneIndex, stage3Step)

minimum_distances = logReader.calcMinimumDistances(robotsData)
logReader.savePlainData(minimum_distances, "result_minimum_distances.txt", saveStartStep)

logReader.saveData(robotsData, "result_data_1.txt", "error", saveStartStep, stage2Step-1)
logReader.saveEachRobotData(robotsData, "result_each_robot_error_1", "error", saveStartStep, stage2Step-1)

logReader.saveData(groups[1], "result_data_2_left.txt", "error", stage2Step, stage3Step-1)
logReader.saveEachRobotData(groups[1], "result_each_robot_error_2_left", "error", stage2Step, stage3Step-1)

logReader.saveData(groups[2], "result_data_2_right.txt", "error", stage2Step, stage3Step-1)
logReader.saveEachRobotData(groups[2], "result_each_robot_error_2_right", "error", stage2Step, stage3Step-1)

logReader.saveData(robotsData, "result_data_3.txt", "error", stage3Step)
logReader.saveEachRobotData(robotsData, "result_each_robot_error_3", "error", stage3Step)

logReader.saveSoNSNumber(robotsData, "SoNSNumber.txt", saveStartStep)