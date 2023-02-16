local DeepCopy = require("DeepCopy")

local CollectiveSensor = {}

function CollectiveSensor.create(vns)
	vns.collectivesensor = {}
end

function CollectiveSensor.preStep(vns)
	vns.collectivesensor.receiveList = {}
	vns.collectivesensor.sendList = {}
end

function CollectiveSensor.addToSendList(vns, object)
	local object = DeepCopy(object)

	-- convert vectors from V to R
	for i, v in pairs(object) do
		--[[
		logger("i = ", i)
		logger("v = ", getmetatable(v))
		logger("vector3 = ", getmetatable(vector3()))
		logger("whether a vector3 = ", getmetatable(v) == getmetatable(vector3()))
		--]]
		if type(v) == "userdata" and getmetatable(v) == getmetatable(vector3()) then
			--logger("I converted a vector3")
			object[i] = vns.api.virtualFrame.V3_VtoR(object[i])
		end
		if type(v) == "userdata" and getmetatable(v) == getmetatable(quaternion()) then
			--logger("I converted a quaternion")
			object[i] = vns.api.virtualFrame.Q_VtoR(object[i])
		end
	end

	table.insert(vns.collectivesensor.sendList, object)
end

function CollectiveSensor.postStep(vns)
	-- send vns.collectivesensor.reportList
	if vns.parentR ~= nil and vns.collectivesensor.sendList ~= nil then
		vns.Msg.send(vns.parentR.idS, "sensor_report", {reportList = vns.collectivesensor.sendList})
	end
end

function CollectiveSensor.step(vns)
	for idS, robotR in pairs(vns.childrenRT) do 
		for _, msgM in ipairs(vns.Msg.getAM(idS, "sensor_report")) do
			-- for each object in a list
			for i, object in pairs(msgM.dataT.reportList) do
				for j, v in pairs(object) do
					if type(v) == "userdata" and getmetatable(v) == getmetatable(vector3()) then
						--[[
						object[j] = vns.api.virtualFrame.V3_RtoV(
							vector3(v):rotate(vns.api.virtualFrame.Q_VtoR(robotR.orientationQ)) + 
							vns.api.virtualFrame.V3_VtoR(robotR.positionV3)
						)							  
						--]]
						object[j] = 
							vector3(v):rotate(robotR.orientationQ) + robotR.positionV3
					end
					if type(v) == "userdata" and getmetatable(v) == getmetatable(quaternion()) then
						object[j] = 
							robotR.orientationQ
							* v
						--[[
						object[j] = vns.api.virtualFrame.Q_RtoV(
							vns.api.virtualFrame.Q_VtoR(robotR.orientationQ)
							* v
						)							  
						--]]
					end
				end

				--[[
				-- check existed
				local flag = 0
				for 
				--]]

				table.insert(vns.collectivesensor.receiveList, object)
			end
		end
	end
end

function CollectiveSensor.reportAll(vns)
	for i, ob in pairs(vns.avoider.obstacles) do
		CollectiveSensor.addToSendList(vns, ob)
	end
	for i, ob in pairs(vns.collectivesensor.receiveList) do
		local flag = true
		for j, existing_ob in pairs(vns.collectivesensor.sendList) do
			if existing_ob.positionV3 ~= nil and
			   ob.positionV3 ~= nil and
			   (existing_ob.positionV3 - ob.positionV3):length() < 0.01 then
				flag = false
				break
			end
		end
		if flag == true then
			CollectiveSensor.addToSendList(vns, ob)
		end
	end
end

------ behaviour tree ---------------------------------------
function CollectiveSensor.create_collectivesensor_node_reportAll(vns)
	return function()
		if vns.robotTypeS == "drone" then
		CollectiveSensor.step(vns)
		CollectiveSensor.reportAll(vns)
		end
		return false, true
	end
end

function CollectiveSensor.create_collectivesensor_node(vns)
	return function()
		if vns.robotTypeS == "drone" then
			CollectiveSensor.step(vns)
		end
		return false, true
	end
end

return CollectiveSensor
