if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require("morphology")

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

	if robot.id == "drone1" then
		api.parameters.droneDefaultStartHeight = 1
	end
	if robot.id == "drone2" then
		api.parameters.droneDefaultStartHeight = 4.0
	end

	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)

	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = create_navigation_node(vns)}
		)
	)
end

function step()
	--logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
return function()
	if vns.parentR == nil then
		local marker
		for i, ob in ipairs(vns.avoider.obstacles) do
			if ob.type == 100 then
				marker = ob
			end
		end

		if marker ~= nil then
			vns.setGoal(vns, marker.positionV3 + vector3(0,0,1), marker.orientationQ)
		end
	end

	return false, true
end end