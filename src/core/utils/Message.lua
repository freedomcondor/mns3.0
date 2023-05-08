-----------------------------------------------------------
-- 	Weixu Zhu
-- 		zhuweixu_harry@126.com
--
-- 	Version 1.1 : 
-- 		add function for Vector3 and Quaternion recover
-- 	Version 2.0 :  
-- 		upgrade message searching problem
-- 	Version 3.0 :  
-- 		for vns2.0, delete vector3 and quaternion
-- 	Version 4.0 :  
--		send only one message per step
-----------------------------------------------------------
local Message = {}

Message.list = {}
--[[
	ListArranged = true / nil
	"cmdname" = {list}
--]]

Message.waitToSend = {}
--[[
	"destiny name" = {
		1 = {cmdS, dataT}
		2 = {}
	}
--]]

function Message.preStep()
	Message.waitToSend = {}
	Message.list = {}
	Message.arrange()
end

function Message.postStep(stepCount)
	--[[ send one big table --- out dated
	Message.sendTable{
		fromS = Message.myIDS(),
		message = Message.waitToSend,
		stepCount = stepCount,
		sendtime = robot.system.time, 
	}
	--]]
	---[[ send table to each
	for toIDS, list in pairs(Message.waitToSend) do
		local msgTable = {}
		msgTable[toIDS] = { -- toS as an extra key is for ARGoS to easily read the target of the message
			toS = toIDS,
			fromS = Message.myIDS(),
			message = list,
			stepCount = stepCount,
			sendTime = robot.system.time,
		}
		Message.sendTable(msgTable)
	end
	--]]
end

function Message.arrange()
	--[[ receive one big table --- out dated
	for iN, msgFromEachRobot in ipairs(Message.getTablesAT()) do
		for toS, msgArray in pairs(msgFromEachRobot.message) do
			if toS == Message.myIDS() or toS == "ALLMSG" then
				for jN, msgM in ipairs(msgArray) do
					msgM.fromS = msgFromEachRobot.fromS
					msgM.toS = toS
					if Message.list[msgM.cmdS] == nil then
						Message.list[msgM.cmdS] = {}
					end
					Message.list[msgM.cmdS][#Message.list[msgM.cmdS] + 1] = msgM
					-- for ALLMSG
					if Message.list["ALLMSG"] == nil then
						Message.list["ALLMSG"] = {}
					end
					Message.list["ALLMSG"][#Message.list["ALLMSG"] + 1] = msgM
				end
			end
		end
	end
	--]]

	---[[ receive small tables
	for iN, msgArray_with_key in ipairs(Message.getTablesAT()) do
		local msgArray
		for i, v in pairs(msgArray_with_key) do
			msgArray = v
			break
		end
		if msgArray.toS == Message.myIDS() or msgArray.toS == "ALLMSG" then
			for jN, msgM in ipairs(msgArray.message) do
				msgM.fromS = msgArray.fromS
				msgM.toS = msgArray.toS
				if Message.list[msgM.cmdS] == nil then
					Message.list[msgM.cmdS] = {}
				end
				Message.list[msgM.cmdS][#Message.list[msgM.cmdS] + 1] = msgM
				-- for ALLMSG
				if Message.list["ALLMSG"] == nil then
					Message.list["ALLMSG"] = {}
				end
				Message.list["ALLMSG"][#Message.list["ALLMSG"] + 1] = msgM
			end
		end
	end
	--]]
end

function Message.send(toIDS, cmdS, dataT)
	if Message.waitToSend[toIDS] == nil then
		Message.waitToSend[toIDS] = {}
	end

	Message.waitToSend[toIDS][#Message.waitToSend[toIDS] + 1] = {
		cmdS = cmdS,
		dataT = dataT,
	}
end

function Message.getAM(fromS, cmdS)
	local listAM = {}
	local i = 0
	local searchList = Message.list[cmdS] or {}

	for iN, msgM in ipairs(searchList) do
		if msgM.toS == Message.myIDS() or msgM.toS == "ALLMSG" then
		if fromS == "ALLMSG" or fromS == msgM.fromS then
		if cmdS == "ALLMSG" or cmdS == msgM.cmdS then
			i = i + 1
			listAM[i] = msgM
		end end end
	end
	return listAM
end

function Message.myIDS()
	print("Message.myIDS() needs to be implement")
end

function Message.sendTable(table)
	print("Message.sendTable() needs to be implement")
end

function Message.getTablesAT()
	print("Message.getTablesAT() needs to be implement")
end

return Message
