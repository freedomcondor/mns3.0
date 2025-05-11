if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")
Transform = require("Transform")

logger.enable("DroneConnector")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

line_block_type = tonumber(robot.params.line_block_type)
obstacle_block_type = tonumber(robot.params.obstacle_block_type)

state = "wait_to_forward"
substate = nil
stateCount = 0

local structure1 = require("morphology1")
--local structure2 = require("morphology2")
--local structure3 = require("morphology3")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1,
		--structure2,
		--structure3,
	}
}

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

--	api.debug.show_all = true
end

function reset()
	vns.reset(vns)
	--if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.idN = 0
	vns.setGene(vns, gene)
	--[[
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
		}}
	--]]
	bt = BT.create(vns.create_vns_node(vns, {
		connector_recruit_only_necessary = gene.children,
		navigation_node_post_core = create_navigation_node(vns),
	}))

	api.debug.recordSwitch = true
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

	vns.logLoopFunctionInfo(vns)

	-- show type blocks
	local type1 = line_block_type
	local type2 = obstacle_block_type
	for i, block in ipairs(vns.avoider.blocks) do
		--if block.type == type1 then
		--	vns.api.debug.drawRing("red", vns.api.virtualFrame.V3_VtoR(block.positionV3), 0.1, true)
		--elseif block.type == type2 then
		--	vns.api.debug.drawRing("green", vns.api.virtualFrame.V3_VtoR(block.positionV3), 0.1, true)
		--end
	end
end

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
	local function sendChilrenNewState(vns, newState, newSubstate)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState, substate = newSubstate})
		end
	end

	function newState(vns, _newState, _newSubstate)
		stateCount = 0
		state = _newState
		substate = _newSubstate
	end

	local function switchAndSendNewState(vns, _newState, _newSubstate)
		newState(vns, _newState, _newSubstate)
		sendChilrenNewState(vns, _newState, _newSubstate)
	end

return function()
	stateCount = stateCount + 1
	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state, msgM.dataT.substate)
	end end

	reference_block = nil
	local reference_block_acc = Transform.createAccumulator()
	-- spread reference block
	for id, block in ipairs(vns.avoider.blocks) do if block.type == reference_block_type then
		Transform.addAccumulator(reference_block_acc, block)
	end end
	if reference_block_acc.n ~= 0 then
		reference_block = Transform.averageAccumulator(reference_block_acc)
	end

	-- receive reference block
	if vns.parentR ~= nil and reference_block == nil then
		for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "downstream_reference")) do
			reference_block = {
				positionV3 = vns.parentR.positionV3 + vector3(msgM.dataT.reference_block.positionV3):rotate(vns.parentR.orientationQ),
				orientationQ = vns.parentR.orientationQ * msgM.dataT.reference_block.orientationQ,
			}
			break
		end 
	end

	-- spread reference block to children
	if reference_block ~= nil then
		for idS, robotR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "downstream_reference",{
				reference_block = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(reference_block.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(reference_block.orientationQ),
				}
			})
		end
	end

	--if reference_block ~= nil then
	--	vns.api.debug.drawArrow("red", vector3(0,0,0), vns.api.virtualFrame.V3_VtoR(reference_block.positionV3), true)
	--end
end end
