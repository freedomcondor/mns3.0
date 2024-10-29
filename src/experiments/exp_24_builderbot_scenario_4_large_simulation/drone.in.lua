if robot.params.simulation == "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu_code/?.lua"
end

logger = require("Logger")
logger.register("main")
pairs = require("AlphaPairs")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")

local socket = require("socket")
local client = socket.tcp()
client:settimeout(0.2)
client_connected = nil

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor

local structure = require("morphology")
local gene = {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure,
	}
}

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

--	api.debug.show_all = true
	api.debug.recordSwitch = true
end

function reset()
	vns.reset(vns)
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure)

	bt = BT.create(vns.create_vns_node(vns, {
		connector_recruit_only_necessary = gene.children,
		navigation_node_post_core = create_navigation_node(vns),
	}))
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
end

local log_file

function destroy()
	vns.destroy()
	api.destroy()
end

function create_navigation_node(vns)
return function()
	if vns.parentR == nil then
		-- create a file log
		if vns.api.stepCount == @CMAKE_DATA_START_STEP@ then
			logger("creating log_file")
			log_file = io.open("joystick.log", "w")
			logger("log_file = ", log_file)
			log_file:close()
		end

		-- connect to server
		if client_connected == nil then
			client_connected = client:connect("localhost", 8080)
			print("trying to connect, client_connected = ", client_connected)
		end

		-- send velocity request to server
		if client_connected ~= nil then
			client:send("request_velocity " .. robot.id .. "\n")
			local response, err = client:receive()
			if not err then
				print("receive from server: ", response)
				local axis0_str, axis1_str = response:match("([^,]+),([^,]+)")
				local axis0_raw = tonumber(axis0_str)
				local axis1_raw = tonumber(axis1_str)

				logger("log_file = ", log_file)
				if log_file ~= nil then
					local write_str = tostring(-axis1_raw) .. "," .. tostring(-axis0_raw)-- .. "\n"
					os.execute("echo \"" .. write_str .. "\" >> joystick.log")
				end

				local range = 32767
				x_input = - axis1_raw / range;
				y_input = - axis0_raw / range;

				local speed = 0.05

				vns.Spreader.emergency_after_core(vns, vector3(x_input * speed, y_input * speed, 0), vector3())
			else
				print("receive from error: ", err)
				if err == "closed" then
					client:close()
					client_connected = nil
				end
			end
		end

		-- if obstacle in sight, align with it
		if vns.avoider.obstacles[1] ~= nil then
			vns.setGoal(vns, vns.goal.positionV3, vns.avoider.obstacles[1].orientationQ)
		end
	end

	return false, true   -- do not go to forward node
end end