local Transform = require("Transform")

local SensorUpdater = {}

function SensorUpdater.updateObstacles(vns, seenObstacles, memObstacles)
	vns.avoider.seenObstacles = seenObstacles
	local offset = {positionV3 = vns.api.estimateLocation.positionV3, orientationQ = vns.api.estimateLocation.orientationQ}
	-- match seenObstacles TODO: hungarian
	for i, seenOb in ipairs(seenObstacles) do
		local nearestDis = math.huge
		local nearestOb = nil
		for j, memOb in ipairs(memObstacles) do
			-- I used to see memOb, I now should be offset(estimated), I should see memOb at X.   offset x X = memOb
			local estimate_memOb = Transform.AxCisB(offset, memOb)
			local dis = (estimate_memOb.positionV3 - seenOb.positionV3):length()
			if dis < nearestDis and dis < vns.api.parameters.obstacle_match_distance and memOb.type == seenOb.type and memOb.matched == nil then
				nearestDis = dis
				nearestOb = memOb
			end
		end
		-- check nearestOb
		if nearestOb == nil then
			-- add seenOb to memObstacles
			seenOb.matched = true
			seenOb.unseen_count = vns.api.parameters.obstacle_unseen_count
			memObstacles[#memObstacles + 1] = seenOb
		else
			-- Update nearestOb
			-- TODO : better log offset (average)
			Transform.CxBisA(seenOb, nearestOb, offset)
			nearestOb.positionV3 = seenOb.positionV3
			nearestOb.orientationQ = seenOb.orientationQ
			nearestOb.matched = true
			nearestOb.unseen_count = vns.api.parameters.obstacle_unseen_count
		end
	end

	-- calculator offset

	-- check unseen memObstacles
	for i, memOb in pairs(memObstacles) do
		if memOb.matched == nil then
			memOb.unseen_count = memOb.unseen_count - 1
			if memOb.unseen_count < 0 then
				memObstacles[i] = nil
			else
				Transform.AxBisC(offset, memOb, memOb)
			end
		end
	end

	-- sort memObstacles to 1,2,3,...,n and 
	-- remove matched
	local tempMemObstacles = {}
	for i, memOb in pairs(memObstacles) do
		tempMemObstacles[#tempMemObstacles + 1] = memOb
	end
	for i, memOb in pairs(memObstacles) do
		memObstacles[i] = nil
	end
	for i, memOb in ipairs(tempMemObstacles) do
		memOb.matched = nil
		memObstacles[i] = memOb
	end
end

function SensorUpdater.updateObstaclesByRealFrame(vns, seenObstacles, memObstacles)
	vns.avoider.seenObstacles = seenObstacles
	--local offset = {positionV3 = vns.api.estimateLocation.positionV3, orientationQ = vns.api.estimateLocation.orientationQ}
	local offset = {positionV3 = vector3(), orientationQ = quaternion()}
	-- match seenObstacles TODO: hungarian
	for i, seenOb in ipairs(seenObstacles) do
		local nearestDis = math.huge
		local nearestOb = nil
		for j, memOb in ipairs(memObstacles) do
			-- I used to see memOb, I now should be offset(estimated), I should see memOb at X.   offset x X = memOb
			local estimate_memOb_inReal = Transform.AxCisB(offset, memOb.locationInRealFrame)
			local dis = (estimate_memOb_inReal.positionV3 - seenOb.locationInRealFrame.positionV3):length()
			if dis < nearestDis and dis < vns.api.parameters.obstacle_match_distance and memOb.type == seenOb.type and memOb.matched == nil then
				nearestDis = dis
				nearestOb = memOb
			end
		end
		-- check nearestOb
		if nearestOb == nil then
			-- add seenOb to memObstacles
			seenOb.matched = true
			seenOb.unseen_count = vns.api.parameters.obstacle_unseen_count
			memObstacles[#memObstacles + 1] = seenOb
		else
			-- Update nearestOb
			-- TODO : better log offset (average)
			Transform.CxBisA(seenOb, nearestOb, offset)
			nearestOb.positionV3 = seenOb.positionV3
			nearestOb.orientationQ = seenOb.orientationQ
			nearestOb.locationInRealFrame = seenOb.locationInRealFrame
			nearestOb.matched = true
			nearestOb.unseen_count = vns.api.parameters.obstacle_unseen_count
		end
	end

	-- calculator offset

	-- check unseen memObstacles
	for i, memOb in pairs(memObstacles) do
		if memOb.matched == nil then
			memOb.unseen_count = memOb.unseen_count - 1
			if memOb.unseen_count < 0 then
				memObstacles[i] = nil
			else
				Transform.AxBisC(offset, memOb, memOb)
			end
		end
	end

	-- sort memObstacles to 1,2,3,...,n and 
	-- remove matched
	local tempMemObstacles = {}
	for i, memOb in pairs(memObstacles) do
		tempMemObstacles[#tempMemObstacles + 1] = memOb
	end
	for i, memOb in pairs(memObstacles) do
		memObstacles[i] = nil
	end
	for i, memOb in ipairs(tempMemObstacles) do
		memOb.matched = nil
		memObstacles[i] = memOb
	end
end

return SensorUpdater