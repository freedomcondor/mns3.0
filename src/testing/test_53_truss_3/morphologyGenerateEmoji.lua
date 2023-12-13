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
				positionV3 = vector3(L*0.3, 0, L*0.5),
				orientationQ = quaternion(),
				color = color,
			}
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(-L*0.3, 0, L*0.5),
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
		calcBaseValue = baseValueFunction_target,
	}
	local leftEye1 = generateEye(2.5, vector3(-1.5, 3.2, 3.3), quaternion(math.pi/2, vector3(0,0,1)) * quaternion(-math.pi/10, vector3(1,0,0)), color)
	local leftEye2 = generateEye(3.3, vector3(0.5, 3, 2.8), quaternion(math.pi/2, vector3(0,0,1)) * quaternion(-math.pi/10, vector3(1,0,0)), color)
	local rightEye1 = generateEye(2.5, vector3(-1.5, -3.2, 3.3), quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(math.pi/10, vector3(1,0,0)), color)
	local rightEye2 = generateEye(3.3, vector3(0.5, -3, 2.8), quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(math.pi/10, vector3(1,0,0)), color)
	local mouth1 = generateMouth(3.0, vector3(-1.5,0,-2.8), quaternion(math.pi/2+math.pi/10, vector3(0,1,0)), color)
	local mouth2 = generateMouth(2.5, vector3(0.5,0,-3.3), quaternion(math.pi/2+math.pi/10, vector3(0,1,0)), color)
	node.children = {leftEye1, leftEye2, rightEye1, rightEye2, mouth1 , mouth2}
	return node
end

function generateSmileFace(positionV3, orientationQ, color)
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		calcBaseValue = baseValueFunction_target,
	}
	local leftEye1 = generateEye(3.3, vector3(0.5,  3, 5.0), quaternion(math.pi/2, vector3(0,0,1)) * quaternion(math.pi-math.pi/10, vector3(1,0,0)), color)
	local leftEye2 = generateEye(2.5, vector3(-1.5, 3.2, 4.5), quaternion(math.pi/2, vector3(0,0,1)) * quaternion(math.pi-math.pi/10, vector3(1,0,0)), color)
	local rightEye1 = generateEye(3.3, vector3(0.5, -3, 5.0), quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(math.pi+math.pi/10, vector3(1,0,0)), color)
	local rightEye2 = generateEye(2.5, vector3(-1.5, -3.2, 4.5), quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(math.pi+math.pi/10, vector3(1,0,0)), color)
	local mouth1 = generateMouth(3.0, vector3(0.5,0,-6), quaternion(-math.pi/2+math.pi/10, vector3(0,1,0)), color)
	local mouth2 = generateMouth(2.5, vector3(-1.5,0,-5.5), quaternion(-math.pi/2+math.pi/10, vector3(0,1,0)), color)
	node.children = {leftEye1, leftEye2, rightEye1, rightEye2, mouth1 , mouth2}
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
	local node = generateFixLengthHollowSphere(15, 4.10, 5, vector3(), quaternion())
	local faceNode = generateSmileFace(vector3(3, 0, 0), quaternion(), "yellow")
	faceNode.priority = 2
	table.insert(node.children, faceNode)
	return node
end
