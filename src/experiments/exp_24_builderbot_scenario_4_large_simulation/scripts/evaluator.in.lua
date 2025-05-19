package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu_code/?.lua"

logger = require("Logger")
local logReader = require("logReader")
logger.enable()

-- Read logs
local robotsData = logReader.loadData("./logs", {"drone", "pipuck"})

-- calculate average velocity
local averageVelocity = {}
-- calculate swarm size
local swarmSize = 0
for robotName, robotData in pairs(robotsData) do
	swarmSize = swarmSize + 1
end

local startStep = @CMAKE_DATA_START_STEP@
local endStep = logReader.getEndStep(robotsData)

for i = startStep, endStep do
	local sumVelocity = vector3()
	for idS, robotData in pairs(robotsData) do
		local deltaPosition = robotData[i].positionV3 - robotData[i-1].positionV3
		sumVelocity = sumVelocity + deltaPosition
	end
	averageVelocity[i] = sumVelocity * (1 / swarmSize)
	averageVelocity[i] = averageVelocity[i] / 0.2
end

logReader.savePlainData(averageVelocity, "average_velocity.log", startStep, endStep)