local RecruitLogger = {
	file = nil
}

function RecruitLogger:init(robotID)
	os.execute("mkdir -p logs_recruit")
	self.file = io.open("logs_recruit/" .. robotID .. ".recruitlog", "w")
	if self.file == nil then
		print("create recruit log file wrong")
	end
end

function RecruitLogger:destroy()
	self.file:close()
end

function RecruitLogger:step(waitToSend)
	recruitRequirement = {
		drone = 0,
		pipuck = 0,
		builderbot = 0,
	}
	for destinyID, messages in pairs(waitToSend) do
		for id, message in ipairs(messages) do
			if message.cmdS == "recruit" then
				if type(message.dataT.assign_only_or_requirement) == "table" then
					recruitRequirement["drone"] = recruitRequirement["drone"] +
					                              (message.dataT.assign_only_or_requirement["drone"] or 0)
					recruitRequirement["pipuck"] = recruitRequirement["pipuck"] +
					                               (message.dataT.assign_only_or_requirement["pipuck"] or 0)
					recruitRequirement["builderbot"] = recruitRequirement["builderbot"] +
					                                   (message.dataT.assign_only_or_requirement["builderbot"] or 0)
				end
			end
		end
	end

	self.file:write(tostring(recruitRequirement["drone"]) .. ", ")
	self.file:write(tostring(recruitRequirement["pipuck"]) .. ", ")
	self.file:write(tostring(recruitRequirement["builderbot"]) .. "\n")
	self.file:flush()
end

return RecruitLogger