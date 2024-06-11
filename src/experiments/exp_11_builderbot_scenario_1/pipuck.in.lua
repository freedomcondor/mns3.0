if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

logger.enable()

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

--local state
--local type_number_in_memory = 0
type_number_in_memory = 0

local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		structure2,
		structure3,
	}
}

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure1)
	bt = BT.create(vns.create_vns_node(vns, {
		connector_recruit_only_necessary = gene.children,
		navigation_node_pre_core = create_consensus_node(vns),
		navigation_node_post_core = create_navigation_node(vns),
	}))

	state = "consensus"
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_consensus_node(vns)
return function()
	if state ~= "consensus" then return false, true end
	local range = 0.5
	-- check neighbour blocks
	local types_index = {}
	for id, block in pairs(vns.avoider.blocks) do
		if block.positionV3:length() < range then
			vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(block.positionV3), true)

			-- check type exist
			if types_index[block.type] == nil then
				types_index[block.type] = true
			end
		end
	end
	local type_number = 0
	for i, v in pairs(types_index) do
		type_number = type_number + 1
	end

	-- receive consensus
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "consensus")) do
		if msgM.dataT.type_number > type_number then
			type_number = msgM.dataT.type_number
		end
	end

	if type_number_in_memory < type_number then type_number_in_memory = type_number end

	-- draw type_number
	for i = 1, type_number_in_memory do
		vns.api.debug.drawRing("black", vector3(0,0,0.15 + 0.06 * i), 0.04, true)
	end

	-- send to neighbour pipucks
	for id, robot in pairs(vns.connector.seenRobots) do
		if robot.positionV3:length() < range then
			vns.api.debug.drawArrow("blue", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(robot.positionV3), true)

			vns.Msg.send(id, "consensus", {type_number = type_number_in_memory})
		end
	end
	
	return false, true
end end

function create_navigation_node(vns)
return function()
	local range = 0.7
	if state == "consensus" and vns.parentR == nil then
		vns.Parameters.avoider_brain_exception = false
		vns.Parameters.dangerzone_block = 0.2
		local desired_distance = 0.3

		vns.Spreader.emergency_after_core(vns, vector3(0.01, 0, 0), vector3())

		for id, robot in pairs(vns.connector.seenRobots) do
			if robot.positionV3:length() < range then
				local dir = vector3(robot.positionV3):normalize()
				local speed = (robot.positionV3:length() - desired_distance) * 0.03
				if speed > 0.03 then speed = 0.03 end
				local velocity = dir * speed
				vns.Spreader.emergency_after_core(vns, velocity, vector3())
				--vns.api.debug.drawArrow("blue", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(robot.positionV3), true)
			end
		end

		-- state switch
		for id, robot in pairs(vns.connector.seenRobots) do
			if robot.robotTypeS == "builderbot" and robot.positionV3:length() < 1.0 then
				if type_number_in_memory == 1 then
					vns.setMorphology(vns, structure2)
				elseif type_number_in_memory == 2 then
					vns.setMorphology(vns, structure3)
				end
				vns.Parameters.avoider_brain_exception = true
				vns.idN = vns.idN + 1
				state = "start_mns"
			end
		end
	elseif state == "start_mns" then
	end
	return false, true
end end
