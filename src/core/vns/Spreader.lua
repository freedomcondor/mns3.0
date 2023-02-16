-- Spreader -----------------------------------------
------------------------------------------------------
local Spreader = {}

function Spreader.create(vns)
	vns.spreader = {}
end

function Spreader.reset(vns)
	vns.spreader.spreading_speed = {positionV3 = vector3(), orientationV3 = vector3(), flag = nil,}
end

function Spreader.preStep(vns)
	local chillRate = 0.1
	vns.spreader.spreading_speed.positionV3 = vns.spreader.spreading_speed.positionV3 * chillRate
	vns.spreader.spreading_speed.orientationV3 = vns.spreader.spreading_speed.orientationV3 * chillRate
	vns.spreader.spreading_speed.flag = nil
end

function Spreader.emergency_after_core(vns, transV3, rotateV3, flag)
	Spreader.emergency(vns, transV3, rotateV3, flag, true)
end

function Spreader.emergency(vns, transV3, rotateV3, flag, after_core)
	vns.spreader.spreading_speed.positionV3 = vns.spreader.spreading_speed.positionV3 + transV3
	vns.spreader.spreading_speed.orientationV3 = vns.spreader.spreading_speed.orientationV3 + rotateV3
	flag = flag or vns.spreader.spreading_speed.flag
	vns.spreader.spreading_speed.flag = flag

	if after_core == true then
		vns.goal.transV3 = 
			vns.goal.transV3 + transV3
		vns.goal.rotateV3 = 
			vns.goal.rotateV3 + rotateV3
	end

	-- message from children, send to parent
	if vns.parentR ~= nil then
		vns.Msg.send(vns.parentR.idS, "emergency", {
			transV3 = vns.api.virtualFrame.V3_VtoR(transV3), 
			rotateV3 = vns.api.virtualFrame.V3_VtoR(rotateV3), 
			flag = flag,
		})
	end

	for idS, childR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "emergency", {
			transV3 = vns.api.virtualFrame.V3_VtoR(transV3), 
			rotateV3 = vns.api.virtualFrame.V3_VtoR(rotateV3), 
			flag = flag,
		})
	end
end

function Spreader.step(vns, surpress_or_not)
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "emergency")) do
		if vns.childrenRT[msgM.fromS] ~= nil or 
		   vns.parentR ~= nil and vns.parentR.idS == msgM.fromS then -- else continue
		
		local fromRobotR = vns.childrenRT[msgM.fromS] or vns.parentR

		local transV3 = vns.api.virtualFrame.V3_RtoV(
			vector3(msgM.dataT.transV3):rotate(
				vns.api.virtualFrame.Q_VtoR(fromRobotR.orientationQ)
			)
		)
		local rotateV3 = vns.api.virtualFrame.V3_RtoV(
			vector3(msgM.dataT.rotateV3):rotate(
				vns.api.virtualFrame.Q_VtoR(fromRobotR.orientationQ)
			)
		)
		local flag = msgM.dataT.flag

		vns.spreader.spreading_speed.positionV3 = vns.spreader.spreading_speed.positionV3 + transV3
		vns.spreader.spreading_speed.orientationV3 = vns.spreader.spreading_speed.orientationV3 + rotateV3
		flag = flag or vns.spreader.spreading_speed.flag
		vns.spreader.spreading_speed.flag = flag

		-- message from children, send to parent
		if vns.childrenRT[msgM.fromS] ~= nil then
			if vns.parentR ~= nil then
				vns.Msg.send(vns.parentR.idS, "emergency", {
					transV3 = vns.api.virtualFrame.V3_VtoR(transV3), 
					rotateV3 = vns.api.virtualFrame.V3_VtoR(rotateV3), 
					flag = flag,
				})
			end
		end

		for idS, childR in pairs(vns.childrenRT) do
			if idS ~= msgM.fromS then
				vns.Msg.send(idS, "emergency", {
					transV3 = vns.api.virtualFrame.V3_VtoR(transV3), 
					rotateV3 = vns.api.virtualFrame.V3_VtoR(rotateV3), 
					flag = flag,
				})
			end
		end
	end end

	if surpress_or_not == true then
		vns.goal.transV3 = vns.spreader.spreading_speed.positionV3
		vns.goal.rotateV3 = vns.spreader.spreading_speed.orientationV3
	else
		vns.goal.transV3 = 
			vns.goal.transV3 + vns.spreader.spreading_speed.positionV3
		vns.goal.rotateV3 = 
			vns.goal.rotateV3 + vns.spreader.spreading_speed.orientationV3
	end
end

function Spreader.create_spreader_node(vns)
	return function()
		Spreader.step(vns)
	end
end

return Spreader
