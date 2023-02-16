-- ScaleManager --------------------------------------
------------------------------------------------------

local ScaleManager = {}

--[[
--	related data
--	vns.scalemanager = {
--		scale
--		depth
--	}
--	vns.parentR.scalemanager = {
--		scale
--	}
--	vns.childrenRT[xxx] = {
--		scale
--		depth
--	}
--]]

ScaleManager.Scale = require("Scale")

function ScaleManager.create(vns)
	vns.scalemanager = {}
end

function ScaleManager.reset(vns)
	vns.scalemanager.scale = ScaleManager.Scale:new(vns.robotTypeS)
	vns.scalemanager.depth = 1
end

function ScaleManager.addChild(vns, robotR)
	robotR.scalemanager = {
		scale = ScaleManager.Scale:new(robotR.robotTypeS),
		depth = 1,
		lastSendScale = nil,
	}
end

--function ScaleManager.deleteChild(vns, idS)
--end

function ScaleManager.addParent(vns, robotR)
	robotR.scalemanager = {
		-- scale is set when receive scale command from parent
		scale = nil,
		lastSendScale = nil,
	}
end

--function ScaleManager.deleteParent(vns, idS)
--end

--function ScaleManager.preStep(vns)
--end

function ScaleManager.step(vns)
	-- receive scale from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "scale")) do
		vns.parentR.scalemanager.scale = ScaleManager.Scale:new(msgM.dataT.scale)
	end end
	-- receive scale from children
	for idS, robotR in pairs(vns.childrenRT) do 
		for _, msgM in ipairs(vns.Msg.getAM(idS, "scale")) do
			robotR.scalemanager.scale = ScaleManager.Scale:new(msgM.dataT.scale)
			robotR.scalemanager.depth = msgM.dataT.depth
		end 
	end

	-- add assign_offset
	-- and check assign_offset minus
	for idS, robotR in pairs(vns.childrenRT) do 
		if robotR.assigner.scale_assign_offset ~= nil then
			robotR.scalemanager.scale = robotR.scalemanager.scale + robotR.assigner.scale_assign_offset
		end
		-- sometimes scale_assign_offset may give a false large number when multiple assigns happen parallely
		for typeS, number in pairs(robotR.scalemanager.scale) do
			if number < 0 then robotR.scalemanager.scale[typeS] = 0 end
		end
		if robotR.scalemanager.scale[robotR.robotTypeS] == nil or
		   robotR.scalemanager.scale[robotR.robotTypeS] < 1 then
			robotR.scalemanager.scale[robotR.robotTypeS] = 1
		end
	end
	if vns.parentR ~= nil and vns.parentR.assigner.scale_assign_offset ~= nil then
		vns.parentR.scalemanager.scale = vns.parentR.scalemanager.scale + vns.parentR.assigner.scale_assign_offset
		for typeS, number in pairs(vns.parentR.scalemanager.scale) do
			if number < 0 then vns.parentR.scalemanager.scale[typeS] = 0 end
		end
		if vns.parentR.scalemanager.scale[vns.parentR.robotTypeS] == nil or
		   vns.parentR.scalemanager.scale[vns.parentR.robotTypeS] < 1 then
			vns.parentR.scalemanager.scale[vns.parentR.robotTypeS] = 1
		end
	end

	-- sum up scale
	local sumScale = ScaleManager.Scale:new()
		-- add myself
	sumScale:inc(vns.robotTypeS)
		-- add parent
	if vns.parentR ~= nil then sumScale = sumScale + vns.parentR.scalemanager.scale end
		-- add children
	for idS, robotR in pairs(vns.childrenRT) do 
		sumScale = sumScale + robotR.scalemanager.scale
	end
	vns.scalemanager.scale = sumScale

	-- sum up depth
	local maxdepth = 0
	for idS, robotR in pairs(vns.childrenRT) do 
		if robotR.scalemanager.depth > maxdepth then maxdepth = robotR.scalemanager.depth end
	end
	vns.scalemanager.depth = maxdepth + 1

	-- report scale
	local toReport
	if vns.parentR ~= nil then
		toReport = sumScale - vns.parentR.scalemanager.scale
		if toReport ~= vns.parentR.scalemanager.lastSendScale or
		   vns.scalemanager.depth ~= vns.parentR.scalemanager.lastSendDepth or 
		   vns.api.stepCount % 100 == 0 then
			vns.Msg.send(vns.parentR.idS, "scale", {scale = toReport, depth = vns.scalemanager.depth})
			vns.parentR.scalemanager.lastSendScale = toReport
			vns.parentR.scalemanager.lastSendDepth = vns.scalemanager.depth
		end
	end
	for idS, robotR in pairs(vns.childrenRT) do
		toReport = sumScale - robotR.scalemanager.scale
		if toReport ~= robotR.scalemanager.lastSendScale or 
		   vns.api.stepCount % 100 == 0 then
			vns.Msg.send(idS, "scale", {scale = toReport})
			robotR.scalemanager.lastSendScale = toReport
		end
	end
end

function ScaleManager.create_scalemanager_node(vns)
	return function()
		ScaleManager.step(vns)
		return false, true
	end
end

return ScaleManager
