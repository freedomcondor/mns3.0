if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require("morphology")

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
	vns.setGene(vns, structure)
	--[[
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
		}}
	--]]
	bt = BT.create(vns.create_vns_node(vns, {
		navigation_node_post_core = {type = "sequence", children = {
			vns.Learner.create_learner_node(vns),
		}}
	}))

	if robot.id == "pipuck2" then
		vns.learner.knowledges["move_forward"] = {hash = 1, rank = 1, node = [[
			function()
				vns.Spreader.emergency_after_core(vns, vector3(0.02,0,0), vector3())
				return false, true
			end
		]]}
	end
end

function step()
	logger(robot.id, api.stepCount, robot.system.time, "----------------------------")
	logger(robot.radios.wifi.recv)
	api.preStep()
	vns.preStep(vns)

	bt()

	if robot.id == "pipuck2" then
		vns.Learner.spreadKnowledge(vns, "move_forward", vns.learner.knowledges["move_forward"])
	end

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})
	--api.debug.showSeenRobots(vns, {drawOrientation = true})
	logger("seenBlocks")
	logger(vns.avoider.blocks)
	
	if vns.parentR == nil then
		local dis = math.huge
		local nearest_block = nil
		for i, block in ipairs(vns.avoider.blocks) do
			if block.positionV3:length() < dis then
				dis = block.positionV3:length()
				nearest_block = block
			end
		end

		if nearest_block ~= nil then
			local dir = vector3(nearest_block.positionV3):normalize()
			vns.Spreader.emergency_after_core(vns, dir * 0.05, vector3())
			vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(nearest_block.positionV3), true)
		end
	end
end

function destroy()
	vns.destroy()
	api.destroy()
end
