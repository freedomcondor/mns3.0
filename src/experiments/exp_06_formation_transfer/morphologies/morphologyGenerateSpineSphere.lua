local baseValueFunction_target = function(base, current, target)
	return (current - target):length()
end

local baseValueFunction_0 = function(base, current, target)
	return 0
end

local function generateFixLengthLine(Length, positionV3, orientationQ, relativePositionV3, relativeOrientationQ)
	local stepLength = relativePositionV3:length()
	if Length < 0 then return nil end
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
	}

	node.children = {generateFixLengthLine(Length - stepLength, relativePositionV3, relativeOrientationQ, relativePositionV3, relativeOrientationQ)}
	if #node.children == 0 then node.children = nil end

	return node
end

local function generateSpineSemiCircle(Length, Radius, positionV3, orientationQ, relativeX, relativeY)
	local stepLengthX = relativeX:length()
	local stepLengthY = relativeY:length()
	if Length < 0 then return nil end

	local YLength = math.sqrt(Radius^2-(Radius-Length)^2)
	local node = generateFixLengthLine(YLength, positionV3, orientationQ, relativeY, quaternion())
	if node.children ~= nil then
		table.insert(node.children, generateFixLengthLine(YLength - stepLengthY, -relativeY, quaternion(), -relativeY, quaternion()))
	end
	node.calcBaseValue = baseValueFunction_target

	if node.children == nil then node.children = {} end
	table.insert(node.children, generateSpineSemiCircle(Length - stepLengthX, Radius, relativeX, quaternion(), relativeX, relativeY))
	if #node.children == 0 then node.children = nil end

	return node
end

local function generateSpineCircle(Radius, positionV3, orientationQ, relativeX, relativeY)
	local stepLengthX = relativeX:length()
	local node = generateSpineSemiCircle(Radius, Radius, positionV3, orientationQ, relativeX, relativeY)
	if node.children == nil then node.children = {} end
	table.insert(node.children, generateSpineSemiCircle(Radius - stepLengthX, Radius, -relativeX, quaternion(), -relativeX, relativeY))
	if #node.children == 0 then node.children = nil end
	return node
end

function generateSpineSemiSphere(Length, Radius, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	local stepLengthZ = relativeZ:length()
	if Length < 0 then return nil end

	local circleRadius = math.sqrt(Radius^2-(Radius-Length)^2)
	local node = generateSpineCircle(circleRadius, relativeZ, quaternion(), relativeX, relativeY)
	node.calcBaseValue = baseValueFunction_target

	if node.children == nil then node.children = {} end
	table.insert(node.children, generateSpineSemiSphere(Length - stepLengthZ, Radius, relativeZ, quaternion(), relativeX, relativeY, relativeZ))
	if #node.children == 0 then node.children = nil end

	return node
end

function generateSpineCenterBrainSphere(Radius, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	local stepLengthZ = relativeZ:length()
	local node = generateSpineSemiSphere(Radius, Radius, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	if node.children == nil then node.children = {} end
	table.insert(node.children, generateSpineSemiSphere(Radius - stepLengthZ, Radius, -relativeZ, quaternion(), relativeX, relativeY, -relativeZ))
	if #node.children == 0 then node.children = nil end
	return node
end

function generateSpineBottomBrainSphere(Radius, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	local stepLengthZ = relativeZ:length()
	local node = generateSpineSemiSphere(Radius * 2, Radius, positionV3, orientationQ, relativeX, relativeY, relativeZ)
	return node
end