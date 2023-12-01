local baseValueFunction_target = function(base, current, target)
	return (current - target):length()
end

local baseValueFunction_0 = function(base, current, target)
	return 0
end

local function generateLine(n, positionV3, orientationQ, relativePositionV3, relativeOrientationQ)
	if n <= 0 then return nil end
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
	}

	if n > 1 then
		node.children = {generateLine(n-1, relativePositionV3, relativeOrientationQ, relativePositionV3, relativeOrientationQ)}
	end

	return node
end

local function generateSpine(m, n, positionV3, orientationQ, relativeX, relativeY)
	if m <= 0 then return nil end

	local node = generateLine(n, positionV3, orientationQ, relativeY, quaternion())
	if node.children ~= nil then
		table.insert(node.children, generateLine(n-1, -relativeY, quaternion(), -relativeY, quaternion()))
	end
	node.calcBaseValue = baseValueFunction_target

	if m > 1 then
		if node.children == nil then node.children = {} end
		table.insert(node.children, generateSpine(m-1, n, relativeX, quaternion(), relativeX, relativeY))
	end

	return node
end

function generateSpineBottomBrainCube(l, m, n, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	if l <= 0 then return nil end

	local node = generateSpine(m, n, positionV3, orientationQ, relativeX, relativeY)
	if node.children ~= nil then
		table.insert(node.children, generateSpine(m-1, n, -relativeX, quaternion(), -relativeX, relativeY))
	end
	node.calcBaseValue = baseValueFunction_target

	if l > 1 then
		if node.children == nil then node.children = {} end
		table.insert(node.children, generateSpineBottomBrainCube(l-1, m, n, relativeZ, quaternion(), relativeX, relativeY, relativeZ))
	end

	return node
end

function generateSpineCenterBrainCube(l, m, n, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	local node = generateSpineBottomBrainCube(l, m, n, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	if node ~= nil then
		if node.children == nil then node.children = {} end
		table.insert(node.children, generateSpineBottomBrainCube(l - 1, m, n, -relativeZ, quaternion(), relativeX, relativeY, -relativeZ))
	end
	return node
end