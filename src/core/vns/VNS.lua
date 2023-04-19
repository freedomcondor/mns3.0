local VNS = {VNSCLASS = true}
VNS.__index = VNS

VNS.Msg = require("Message")
VNS.Parameters = require("Parameters")

VNS.DroneConnector = require("DroneConnector")
VNS.PipuckConnector = require("PipuckConnector")
VNS.Connector = require("Connector")
--VNS.DroneConnectKeeper = require("DroneConnectKeeper")
VNS.ScaleManager = require("ScaleManager")
VNS.Assigner = require("Assigner")
VNS.Allocator = require("Allocator")
VNS.Avoider = require("Avoider")
VNS.Spreader = require("Spreader")
VNS.BrainKeeper = require("BrainKeeper")
VNS.CollectiveSensor = require("CollectiveSensor")
VNS.IntersectionDetector = require("IntersectionDetector")
VNS.Neuron = require("Neuron")
VNS.Learner = require("Learner")
VNS.Stabilizer = require("Stabilizer")

VNS.Driver= require("Driver")

VNS.Modules = {
	VNS.DroneConnector,
	VNS.PipuckConnector,
	VNS.Connector,
--	VNS.DroneConnectKeeper,
	VNS.Assigner,

	VNS.ScaleManager,
	VNS.Stabilizer,

	VNS.Allocator,
	VNS.IntersectionDetector,

	VNS.Avoider,
	VNS.Spreader,
	VNS.CollectiveSensor,
	VNS.BrainKeeper,

	VNS.Neuron,
	VNS.Learner,

	VNS.Driver,
}

--[[
--	vns = {
--		idS
--		idN
--		robotTypeS
--		scale
--		
--		parentR
--		childrenRT
--
--	}
--]]

function VNS.create(myType)

	-- a robot =  {
	--     idS,
	--     positionV3, 
	--     orientationQ,
	--     robotTypeS = "drone",
	-- }

	local vns = {}
	vns.robotTypeS = myType

	setmetatable(vns, VNS)

	for i, module in ipairs(VNS.Modules) do
		if type(module.create) == "function" then
			module.create(vns)
		end
	end

	VNS.reset(vns)
	return vns
end

function VNS.reset(vns)
	vns.parentR = nil
	vns.childrenRT = {}

	vns.idS = VNS.Msg.myIDS()
	vns.idN = robot.random.uniform()

	for i, module in ipairs(VNS.Modules) do
		if type(module.reset) == "function" then
			module.reset(vns)
		end
	end
end

function VNS.destroy(vns)
	--TODO
end

function VNS.preStep(vns)
	VNS.Msg.preStep()
	for i, module in ipairs(VNS.Modules) do
		if type(module.preStep) == "function" then
			module.preStep(vns)
		end
	end
end

function VNS.postStep(vns)
	for i = #VNS.Modules, 1, -1 do
		local module = VNS.Modules[i]
		if type(module.postStep) == "function" then
			module.postStep(vns)
		end
	end
	vns.Msg.postStep(vns.api.stepCount)
end

function VNS.addChild(vns, robotR)
	for i, module in ipairs(VNS.Modules) do
		if type(module.addChild) == "function" then
			module.addChild(vns, robotR)
		end
	end
end
function VNS.deleteChild(vns, idS)
	for i = #VNS.Modules, 1, -1 do
		local module = VNS.Modules[i]
		if type(module.deleteChild) == "function" then
			module.deleteChild(vns, idS)
		end
	end
end

function VNS.addParent(vns, robotR)
	for i, module in ipairs(VNS.Modules) do
		if type(module.addParent) == "function" then
			module.addParent(vns, robotR)
		end
	end
end
function VNS.deleteParent(vns)
	for i = #VNS.Modules, 1, -1 do
		local module = VNS.Modules[i]
		if type(module.deleteParent) == "function" then
			module.deleteParent(vns)
		end
	end
end

function VNS.setGene(vns, morph)
	for i, module in ipairs(VNS.Modules) do
		if type(module.setGene) == "function" then
			module.setGene(vns, morph)
		end
	end
end

function VNS.setMorphology(vns, morph)
	for i, module in ipairs(VNS.Modules) do
		if type(module.setMorphology) == "function" then
			module.setMorphology(vns, morph)
		end
	end
end

function VNS.resetMorphology(vns)
	for i, module in ipairs(VNS.Modules) do
		if type(module.resetMorphology) == "function" then
			module.resetMorphology(vns)
		end
	end
end

function VNS.setGoal(vns, positionV3, orientationQ)
	for i, module in ipairs(VNS.Modules) do
		if type(module.setGoal) == "function" then
			module.setGoal(vns, positionV3, orientationQ)
		end
	end
end

function VNS.getNeighbours(vns)
	local neighbours = {}
	for idS, robotR in pairs(vns.childrenRT) do
		neighbours[idS] = robotR
	end
	if vns.parentR ~= nil then
		neighbours[vns.parentR.idS] = vns.parentR
	end
	return neighbours
end

---- Print Debug Info ------------------------------------------
VNS.debug = {}
function VNS.debug.logInfo(vns, option, indent_str)
	if option == nil then option = {ALL = true} end
	if indent_str == nil then indent_str = "" end

	logger(indent_str .. robot.id, vns.api.stepCount, "-----------------------") 
	vns.debug.logVNSInfo(vns, option, indent_str)
	logger(indent_str .. "    parent : ") 
	if vns.parentR ~= nil then
		vns.debug.logRobot(vns.parentR, option, indent_str .. "        ")
	end
	logger(indent_str .. "    children : ") 
	for _, childR in pairs(vns.childrenRT) do
		vns.debug.logRobot(childR, option, indent_str .. "        ")
	end
end

function VNS.debug.logVNSInfo(vns, option, indent_str)
	if option == nil then option = {ALL = true} end
	if indent_str == nil then indent_str = "" end

	if option.ALL == true or option.idN == true then
		logger(indent_str .. "    idN              = ", vns.idN) 
	end
	if option.ALL == true or option.idS == true then
		logger(indent_str .. "    idS              = ", vns.idS) 
	end
	if option.ALL == true or option.robotTypeS   == true then
		logger(indent_str .. "    robotTypeS       = ", vns.robotTypeS) 
	end
	if option.ALL == true or option.target == true and vns.allocator.target ~= nil then
		logger(indent_str .. "    allocator.target = ", vns.allocator.target.idN) 
	end
	if option.ALL == true or option.goal == true then
		logger(indent_str .. "    goal.positionV3  = ", vns.goal.positionV3) 
		logger(indent_str .. "         orientationQ : X = ", vector3(1,0,0):rotate(vns.goal.orientationQ)) 
		logger(indent_str .. "                        Y = ", vector3(0,1,0):rotate(vns.goal.orientationQ)) 
		logger(indent_str .. "                        Z = ", vector3(0,0,1):rotate(vns.goal.orientationQ)) 
		logger(indent_str .. "         transV3     = ", vns.goal.transV3) 
		logger(indent_str .. "         rotateV3    = ", vns.goal.rotateV3) 
	end
	if option.ALL == true or option.scale == true then 
		logger(indent_str .. "    scale       : ")
		for typeS, number in pairs(vns.scalemanager.scale) do
			logger(indent_str .. "                   " .. typeS, number)
		end
	end
	if option.ALL == true or option.connector == true then 
		logger(indent_str .. "    connector.waitingRobots : ")
		for idS, robotR in pairs(vns.connector.waitingRobots) do
			logger(indent_str .. "                           " .. idS, robotR.waiting_count)
		end
		logger(indent_str .. "    connector.waitingParents: ")
		for idS, robotR in pairs(vns.connector.waitingParents) do
			logger(indent_str .. "                           " .. idS, robotR.waiting_count)
		end
	end
end

function VNS.debug.logRobot(robotR, option, indent_str)
	if option == nil then option = {ALL = true} end
	if indent_str == nil then indent_str = "" end

	logger(indent_str .. robotR.idS)
	if option.ALL == true or option.robotTypeS   == true then
		logger(indent_str .. "    robotTypeS       = ", robotR.robotTypeS) 
	end
	if option.ALL == true or option.positionV3   == true then
		logger(indent_str .. "    positionV3       = ", robotR.positionV3) 
	end
	if option.ALL == true or option.orientationQ == true then
		logger(indent_str .. "    orientationQ : X = ", vector3(1,0,0):rotate(robotR.orientationQ))
		logger(indent_str .. "                   Y = ", vector3(0,1,0):rotate(robotR.orientationQ))
		logger(indent_str .. "                   Z = ", vector3(0,0,1):rotate(robotR.orientationQ))
	end
	if option.ALL == true or option.scale == true then 
		logger(indent_str .. "    scale       : ")
		for typeS, number in pairs(robotR.scalemanager.scale) do
			logger(indent_str .. "                   " .. typeS, number)
		end
	end
	if (option.ALL == true or option.connector == true) and robotR.connector ~= nil then
		logger(indent_str .. "    connector.unseen_count    = ", robotR.connector.unseen_count)
		logger(indent_str .. "             .heartbeat_count = ", robotR.connector.heartbeat_count)
	end
	-- parent doesn't have these: 
	if (option.ALL == true or option.assigner == true) and robotR.assigner.targetS ~= nil then 
		logger(indent_str .. "    assigner.targetS = ", robotR.assigner.targetS)
	end
	if (option.ALL == true or option.allocator == true) and robotR.allocator ~= nil then 
		if robotR.allocator.match ~= nil then
			logger(indent_str .. "    allocator      = ")
			for _, branch in ipairs(robotR.allocator.match) do
				logger(indent_str .. "                       " .. branch.idN)
			end
		else
			logger(indent_str .. "    allocator      = nil")
		end
	end
end

function VNS.logLoopFunctionInfoHW(vns)
	local targetID = -2
	if vns.allocator.target ~= nil then
		targetID = vns.allocator.target.idN
	end

	local parentID = nil
	if vns.parentR ~= nil then
		parentID = vns.parentR.idS
	end
	VNS.Msg.sendTable{
		toS = "LOGINFO",
		stepCount = vns.api.stepCount,
		virtualFrameQ = vns.api.virtualFrame.orientationQ,
		goalPositionV3 = vns.goal.positionV3,
		goalOrientationQ = vns.goal.orientationQ,
		targetID = targetID,
		vnsID = vns.idS,
		parentID = parentID
	}
end

function VNS.logLoopFunctionInfo(vns)
	if robot.params.hardware == true then
		return VNS.logLoopFunctionInfoHW(vns)
	end
	if robot.debug == nil or robot.debug.write == nil then return end

	-- log virtual frame
	local str = tostring(vns.api.virtualFrame.orientationQ)

	-- log goal position
	str = str .. "," .. tostring(vns.goal.positionV3)
	-- log goal orientation
	str = str .. "," .. tostring(vns.goal.orientationQ)

	-- log target
	if vns.allocator.target == nil then
		str = str .. ",-2"
	else
		str = str .. "," .. tostring(vns.allocator.target.idN)
	end


	-- log brain name
	str = str .. "," .. tostring(vns.idS)

	-- log parent name
	if vns.parentR ~= nil then
		str = str .. "," .. tostring(vns.parentR.idS)
	else
		str = str .. "," .. tostring(nil)
	end

	robot.debug.write(str)
end

---- Behavior Tree Node ------------------------------------------
function VNS.create_preconnector_node(vns)
	local pre_connector_node
	if vns.robotTypeS == "drone" then
		return VNS.DroneConnector.create_droneconnector_node(vns)
	elseif vns.robotTypeS == "pipuck" then
		return VNS.PipuckConnector.create_pipuckconnector_node(vns)
	elseif vns.robotTypeS == "builderbot" then
		return VNS.PipuckConnector.create_pipuckconnector_node(vns) -- TODO
	end
end

function VNS.create_vns_core_node(vns, option)
	-- option = {
	--      connector_no_recruit = true or false or nil,
	--      connector_no_parent_ack = true or false or nil,
	--      specific_name = "drone1"
	--      specific_time = 150
	--          -- If I am stabilizer_preference_robot then ack to only drone1 for 150 steps
	-- }
	if option == nil then option = {} end
	if robot.id == vns.Parameters.stabilizer_preference_robot then
		option.specific_name = vns.Parameters.stabilizer_preference_brain
		option.specific_time = vns.Parameters.stabilizer_preference_brain_time
	end
	return 
	{type = "sequence", children = {
		--vns.create_preconnector_node(vns),
		vns.Connector.create_connector_node(vns, 
			{	no_recruit = option.connector_no_recruit,
				no_parent_ack = option.connector_no_parent_ack,
				specific_name = option.specific_name,
				specific_time = option.specific_time,
			}),
		--vns.DroneConnectKeeper.create_droneconnectkeeper_node(vns),
		vns.Assigner.create_assigner_node(vns),
		vns.ScaleManager.create_scalemanager_node(vns),
		vns.Stabilizer.create_stabilizer_node(vns),
		vns.Allocator.create_allocator_node(vns),
		vns.IntersectionDetector.create_intersectiondetector_node(vns),
		vns.Avoider.create_avoider_node(vns, {
			drone_pipuck_avoidance = option.drone_pipuck_avoidance
		}),
		vns.Spreader.create_spreader_node(vns),
		vns.BrainKeeper.create_brainkeeper_node(vns),
		--vns.CollectiveSensor.create_collectivesensor_node(vns),
		--vns.Driver.create_driver_node(vns),
	}}
end

function VNS.create_vns_node(vns, option)
	-- option = {
	--      connector_no_recruit = true or false or nil,
	--      connector_no_parent_ack = true or false or nil,
	--      driver_waiting
	-- }
	if option == nil then option = {} end

	local children_node = {
		vns.create_preconnector_node(vns)
	}
	if option.navigation_node_pre_core ~= nil then
		table.insert(children_node, option.navigation_node_pre_core)
	end
	table.insert(children_node, vns.create_vns_core_node(vns, option))
	if option.navigation_node_post_core ~= nil then
		table.insert(children_node, option.navigation_node_post_core)
	end
	table.insert(children_node,
		vns.Driver.create_driver_node(vns, {waiting = option.driver_waiting})
	)

	return { 
		type = "sequence", children = children_node
	}
end

return VNS
