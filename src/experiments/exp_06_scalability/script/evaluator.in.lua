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

n_side       = math.ceil(n_drone ^ (1/3))

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
local stage3Step = logReader.checkIDFirstAppearStep(robotsData, structure_full.idN, stage2Step) - n_side * 10

print("stage2 start at", stage2Step)
print("stage3 start at", stage3Step)

os.execute("echo " .. tostring(stage2Step - saveStartStep) .. " > formationSwitch.txt")
os.execute("echo " .. tostring(stage3Step - saveStartStep) .. " >> formationSwitch.txt")

logReader.calcSegmentData(robotsData, geneIndex, saveStartStep, stage2Step-1)
logReader.calcSegmentData(robotsData, geneIndex, stage2Step, stage3Step-1)
logReader.calcSegmentData(robotsData, geneIndex, stage3Step)

minimum_distances = logReader.calcMinimumDistances(robotsData)
logReader.savePlainData(minimum_distances, "result_minimum_distances.txt", saveStartStep)

logReader.saveData(robotsData, "result_data.txt", "error", saveStartStep)
logReader.saveEachRobotData(robotsData, "result_each_robot_error", "error", saveStartStep)