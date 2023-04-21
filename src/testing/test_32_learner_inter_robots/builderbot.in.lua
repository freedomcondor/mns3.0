if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/builderbot-utils/?.lua"
	assert(loadfile(                "@CMAKE_CURRENT_BINARY_DIR@/simu_code/builderbot-utils/init.lua"))()
else
	package.path = package.path .. ";~/builderbot-utils/?.lua"
	assert(loadfile("~/builderbot-utils/init.lua"))()
end

--assert(loadfile("builderbot-utils/init.lua"))()

logger = require("Logger")
logger.register("main")
logger.enable()
pairs = require("AlphaPairs")

local api = require("builderbotAPI")
robot.vns_api = api
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")
--local BT = require("BehaviorTree")

Transform = require("Transform")

----- data
local bt
local structure = require("morphology")

data = api.builderbot_utils_data -- for data editor check

local rules = {
	selection_method = 'nearest_win',
	list = {
		-- pickup a type 0 (black) block
		-- turn the block type 4 (blue) when picking up it
		{
			rule_type = 'pickup',
			structure = {
				{
					index = vector3(0, 0, 0),
					type = 0
				},
			},
			target = {
				reference_index = vector3(0, 0, 0),
				offset_from_reference = vector3(0, 0, 0),
				type = 4,
			},
		},
		-- place a block in front of a type 1 (pink) block
		-- turn the block type 1 (pink) when placing it
		{
			rule_type = 'place',
			structure = {
				{
					index = vector3(0, 0, 0),
					type = 1,
				},
			},
			target = {
				reference_index = vector3(0, 0, 0),
				offset_from_reference = vector3(1, 0, 0),
				type = 1
			},
		},
	}, -- end of rule.list
 } -- end of rules

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("builderbot")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	--if vns.idS == "builderbot21" then vns.idN = 1 end
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)

	robot.lift_system.set_position(robot.api.constants.lift_system_upper_limit)

	bt = BT.create
	{type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.Learner.create_learner_node(vns),
		vns.Learner.create_knowledge_node(vns, "execute_rescue"),
		{type = "selector*", children = {
			{type = "sequence", children = {
				function() 
					--return false, false
					if #api.builderbot_utils_data.blocks ~= 0 then
						return false, false
					end
					return false, true 
				end,
				vns.Driver.create_driver_node(vns),
			}},
			{type = "sequence*", children = {
				robot.nodes.create_pick_up_behavior_node(data, rules),
				--robot.nodes.create_place_behavior_node(data, rules),
			}},
		}}
	}}

	vns.learner.knowledges["rescue"] = {hash = 3, rank = 3, node = string.format([[
		function()
			local childID = "%s"
			if vns.childrenRT[childID] ~= nil and
			   data.target ~= nil then
				vns.Msg.send(childID, "obstacle", {
					obstacle = {
						positionV3 = vns.api.virtualFrame.V3_VtoR(data.target.positionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(data.target.orientationQ),
					}
				})
			end
			return false, true
		end
	]], robot.id)}

	vns.learner.knowledges["execute_rescue"] = {hash = 1, rank = 1, node = [[
		function()
			if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "obstacle")) do
				local target = {
					positionV3 = msgM.dataT.obstacle.positionV3,
					orientationQ = msgM.dataT.obstacle.orientationQ,
				}
				Transform.AxBisC(vns.parentR, target, target)

				vns.setGoal(vns, target.positionV3, target.orientationQ)
			end end
			return false, true
		end
	]]}
end

function step()
	logger(robot.id, api.stepCount, "----------------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	if vns.learner.knowledges["rescue"] ~= nil then
		vns.Learner.spreadKnowledge(vns, "rescue", vns.learner.knowledges["rescue"])
	end

	vns.postStep(vns)
	api.postStep()
	api.debug.showVirtualFrame()
	api.debug.showChildren(vns, {drawOrientation = false})
end

function destroy()
	api.destroy()
end
