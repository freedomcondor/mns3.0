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

local structure_search = require("morphology_2")
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
		structure8,
		structure12,
		structure12_rec,
		structure12_tri,
		structure20,
		structure20_toSplit,
	}
}

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure20)
end

function init()
	api.linkRobotInterface(VNS)
	api.init()
	vns = VNS.create("drone")
	reset()

	number = tonumber(string.match(robot.id, "%d+"))
	if number % 3 == 1 then
		api.parameters.droneDefaultStartHeight = 1
	elseif number % 3 == 2 then
		api.parameters.droneDefaultStartHeight = 3.0
	elseif number % 3 == 0 then
		api.parameters.droneDefaultStartHeight = 5.0
	end
	--api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure20)

	bt = BT.create(
		vns.create_vns_node(vns,
			{navigation_node_post_core = {type = "sequence", children = {
				vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
				create_navigation_node(vns),
			}}}
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
	--api.debug.showVirtualFrame(true)
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	api.debug.showMorphologyLines(vns, true)
	vns.logLoopFunctionInfo(vns)
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
state = "form"
count = 0
return function()
	if state == "form" then
		count = count + 1
		if count == 300 then
			if vns.parentR == nil then
				vns.setMorphology(vns, structure20_toSplit)
			end
			state = "split_prepare"
			count = 0
		end
	elseif state == "split_prepare" then
		count = count + 1
		if count == 50 then
			state = "split"
			count = 0
		end
	elseif state == "split" then
		if vns.allocator.target.split == true then
			-- rebellion
			if vns.parentR ~= nil then
				vns.Msg.send(vns.parentR.idS, "dismiss")
				vns.deleteParent(vns)
			end
			vns.Connector.newVnsID(vns, 0.9, 200)
		end

		state = "move_away"
		count = 0
	elseif state == "move_away" then
		if vns.parentR == nil and vns.scalemanager.scale["drone"] == 12 then
			vns.setMorphology(vns, structure12)
		elseif vns.parentR == nil and vns.scalemanager.scale["drone"] == 8 then
			vns.setMorphology(vns, structure8)
		end
		
		if vns.allocator.target.ranger == true then
			vns.setGoal(vns, vector3(), quaternion())
			vns.Spreader.emergency_after_core(vns, vector3(-0.3, 0, 0), vector3())
		end

		count = count + 1
		if count == 150 then
			state = "move_back"
			count = 0
		end
	elseif state == "move_back" then
		if vns.parentR == nil and vns.scalemanager.scale["drone"] == 8 then
			vns.setMorphology(vns, structure8)
		elseif vns.parentR == nil and vns.scalemanager.scale["drone"] == 12 then
			vns.setMorphology(vns, structure12)
		elseif vns.parentR == nil and vns.scalemanager.scale["drone"] == 20 then
			vns.setMorphology(vns, structure20)
		end
	
		if vns.allocator.target.ranger == true then
			vns.setGoal(vns, vector3(), quaternion())
			vns.Spreader.emergency_after_core(vns, vector3(0.3, 0, 0), vector3())
		end
	end
end end