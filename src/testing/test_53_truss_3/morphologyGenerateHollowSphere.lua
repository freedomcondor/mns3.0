local baseValueFunction_target = function(base, current, target)
	return (current - target):length()
end

local baseValueFunction_0 = function(base, current, target)
	return 0
end

local function generateLine(n, positionV3, orientationQ, relativePositionV3, relativeOrientationQ, color)
	if n <= 0 then return nil end

	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		color = color,
	}

	if n == 1 then return node end
	node.children = {generateLine(n-1, relativePositionV3, relativeOrientationQ, relativePositionV3, relativeOrientationQ, color)}
	if #node.children == 0 then node.children = nil end
	return node
end

function generateFixLengthCircle(radius, stepLength, positionV3, orientationQ, color)
	if stepLength * 0.5 >= radius then return nil end
	local halfTh = math.asin(stepLength*0.5/radius)
	local th = halfTh * 2
	local N = math.ceil(math.pi * 2 / th)
	local halfN = math.floor(N / 2)
	local halfN2 = N - halfN

	local rotateHalfTh = quaternion(halfTh, vector3(0,0,1))
	local rotateTh = quaternion(halfTh * 2, vector3(0,0,1))

	local node = generateLine(halfN, positionV3, orientationQ, vector3(0, stepLength, 0):rotate(rotateHalfTh), rotateTh, color)
	node.calcBaseValue = baseValueFunction_target

	if node == nil then return nil end
	if node.children == nil then node.children = {} end
	table.insert(node.children, generateLine(halfN2, vector3(0, -stepLength, 0):rotate(rotateHalfTh:inverse()), rotateTh:inverse(), vector3(0, -stepLength, 0):rotate(rotateHalfTh:inverse()), rotateTh:inverse(), color))
	if #node.children == 0 then node.children = nil end

	return node
end

local function generateCircleLayer(radius, stepLength, depth, alpha, positionV3, orientationQ, color)
	local layer_radius = radius * math.cos(alpha)
	-- outer circle
	local node = generateFixLengthCircle(layer_radius, stepLength, positionV3, orientationQ, color)
	if node == nil then return nil end

	-- inner circle
	local inner_circle_radius = (radius - depth) * math.cos(alpha)
	if node.children == nil then node.children = {} end
	table.insert(node.children, generateFixLengthCircle(inner_circle_radius, stepLength, vector3(-depth*math.cos(alpha),0,-depth*math.sin(alpha)), quaternion(), color))
	if #node.children == 0 then node.children = nil end

	return node
end

function generateFixLengthHollowSphere(radius, stepLength, depth, positionV3, orientationQ)
	local node = generateCircleLayer(radius, stepLength, depth, 0, positionV3, orientationQ, color)

	local halfTh = math.asin(stepLength*0.5/radius)
	local th = halfTh * 2

	local alpha = th
	local old_node = node
	local old_alpha = 0
	local old_X = radius
	local old_Z = 0

	while (alpha < math.pi / 2) do
		local new_X = radius * math.cos(alpha)
		local new_Z = radius * math.sin(alpha)
		local sub_node = generateCircleLayer(radius, stepLength, depth, alpha, vector3(new_X - old_X, 0, new_Z - old_Z), quaternion(), color)

		if old_node.children == nil then old_node.children = {} end
		table.insert(old_node.children, sub_node)
		if #old_node.children == 0 then old_node.children = nil end

		old_node = sub_node

		old_alpha = alpha
		old_X = new_X
		old_Z = new_Z
		alpha = alpha + th
	end

	local alpha = -th
	local old_node = node
	local old_alpha = 0
	local old_X = radius
	local old_Z = 0

	while (alpha > -math.pi / 2) do
		local new_X = radius * math.cos(alpha)
		local new_Z = radius * math.sin(alpha)
		local sub_node = generateCircleLayer(radius, stepLength, depth, alpha, vector3(new_X - old_X, 0, new_Z - old_Z), quaternion(), color)

		if old_node.children == nil then old_node.children = {} end
		table.insert(old_node.children, sub_node)
		if #old_node.children == 0 then old_node.children = nil end

		old_node = sub_node

		old_alpha = alpha
		old_X = new_X
		old_Z = new_Z
		alpha = alpha - th
	end

	return node
end
