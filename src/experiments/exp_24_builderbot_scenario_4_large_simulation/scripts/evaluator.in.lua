package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local type = logReader.getFirstLineFromFile("type.txt")
print("experiment type : ", type)

require("morphologyGenerateCube")
require("screenGenerator")
require("trussGenerator")
local structure
if type == "polyhedron_12" then
	structure = require("morphology_polyhedron_12")
elseif type == "polyhedron_20" then
	structure = require("morphology_polyhedron_20")
elseif type == "cube_27" then
	structure = generate_cube_morphology(27)
elseif type == "cube_64" then
	structure = generate_cube_morphology(64)
elseif type == "cube_125" then
	structure = generate_cube_morphology(125)
elseif type == "screen_64" then
	structure = generate_screen_square(8)
elseif type == "donut_48" then
	nodes = 48 / 4
	structure = create_horizontal_truss_chain(nodes, 5, vector3(5, 0,0), quaternion(2*math.pi/nodes, vector3(0,0,1)), vector3(), quaternion(), true)
elseif type == "donut_64" then
	nodes = 64 / 4
	structure = create_horizontal_truss_chain(nodes, 5, vector3(5, 0,0), quaternion(2*math.pi/nodes, vector3(0,0,1)), vector3(), quaternion(), true)
elseif type == "donut_80" then
	nodes = 80 / 4
	structure = create_horizontal_truss_chain(nodes, 5, vector3(5, 0,0), quaternion(2*math.pi/nodes, vector3(0,0,1)), vector3(), quaternion(), true)
end

local geneIndex = logReader.calcMorphID(structure)

local robotsData = logReader.loadData("./logs")

local firstRecruitStep = logReader.calcFirstRecruitStep(robotsData)
local saveStartStep = firstRecruitStep + 10
print("firstRecruit happens", firstRecruitStep, "data start at", saveStartStep)

logReader.calcSegmentData(robotsData, geneIndex)
minimum_distances = logReader.calcMinimumDistances(robotsData)
logReader.savePlainData(minimum_distances, "result_minimum_distances.txt", saveStartStep)

logReader.saveData(robotsData, "result_data.txt", "error", saveStartStep)
logReader.saveEachRobotData(robotsData, "result_each_robot_error", "error", saveStartStep)