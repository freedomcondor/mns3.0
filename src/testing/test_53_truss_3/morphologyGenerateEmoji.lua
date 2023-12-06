require("morphologyGenerateHollowSphere")

local baseValueFunction_target = function(base, current, target)
	return (current - target):length()
end

local baseValueFunction_0 = function(base, current, target)
	return 0
end

function generateEye(L, positionV3, orientationQ, color)
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		calcBaseValue = baseValueFunction_target,
		color = color,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L, 0, 0),
			orientationQ = quaternion(),
			color = color,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(L*0.3, 0, L),
				orientationQ = quaternion(),
				color = color,
			}
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(-L*0.3, 0, L),
			orientationQ = quaternion(),
			color = color,
		}
	}}
	return node
end

function generateMouth(L, positionV3, orientationQ, color)
	-- orientation heading down
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		color = color,
		calcBaseValue = baseValueFunction_target,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L*0.2, L, 0),
			orientationQ = quaternion(),
			color = color,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(L/math.sqrt(2), L/math.sqrt(2), 0),
				orientationQ = quaternion(),
				color = color,
			}
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(L*0.2, -L, 0),
			orientationQ = quaternion(),
			color = color,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(L/math.sqrt(2), -L/math.sqrt(2), 0),
				orientationQ = quaternion(),
				color = color,
			}
		}},
	}}
	return node
end

function generateAngryFace(positionV3, orientationQ, color)
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
	}
	local leftEye = generateEye(2.5, vector3(0, 3, 3), quaternion(math.pi/2, vector3(0,0,1)) * quaternion(-math.pi/10, vector3(1,0,0)), color)
	local rightEye = generateEye(2.5, vector3(0, -3, 3), quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(math.pi/10, vector3(1,0,0)), color)
	local mouth = generateMouth(2.5, vector3(0,0,-3), quaternion(math.pi/2+math.pi/10, vector3(0,1,0)), color)
	node.children = {leftEye, rightEye, mouth}
	return node
end

function generateSmileFace(positionV3, orientationQ, color)
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
	}
	local leftEye = generateEye(2.5, vector3(0, 3, 4), quaternion(math.pi/2, vector3(0,0,1)) * quaternion(math.pi-math.pi/10, vector3(1,0,0)), color)
	local rightEye = generateEye(2.5, vector3(0, -3, 4), quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(math.pi+math.pi/10, vector3(1,0,0)), color)
	local mouth = generateMouth(2.5, vector3(0,0,-6), quaternion(-math.pi/2+math.pi/10, vector3(0,1,0)), color)
	node.children = {leftEye, rightEye, mouth}
	return node
end

function generateAngry()
	local node = generateFixLengthHollowSphere(15, 4.05, 5, vector3(), quaternion())
	local faceNode = generateAngryFace(vector3(3, 0, 0), quaternion(), "yellow")
	faceNode.priority = 2
	table.insert(node.children, faceNode)
	return node
end

function generateSmile()
	local node = generateFixLengthHollowSphere(15, 4.05, 5, vector3(), quaternion())
	local faceNode = generateSmileFace(vector3(3, 0, 0), quaternion(), "yellow")
	faceNode.priority = 2
	table.insert(node.children, faceNode)
	return node
end
