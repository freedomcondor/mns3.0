local L = 1.5

function generate_man(head_orientation, arm_orientation, leg_orientation)
	local body, head_joint_node, left_shoulder_joint_node, right_shoulder_joint_node, legs_joint_node = generate_man_body()
	table.insert(head_joint_node.children, generate_man_head(vector3(0,0,L/2), head_orientation))
	table.insert(left_shoulder_joint_node.children, generate_man_limb(L, quaternion(math.pi/2, vector3(0,1,0)) * arm_orientation, L*1.2, quaternion() * arm_orientation))
	table.insert(right_shoulder_joint_node.children, generate_man_limb(L, quaternion(math.pi/2, vector3(0,1,0)), L*1.2, quaternion()))
	table.insert(legs_joint_node.children, generate_man_limb(L, quaternion(math.pi/6, vector3(0,0,1)) * leg_orientation, L*1.6, quaternion(-math.pi/6, vector3(0,0,1))*leg_orientation))
	table.insert(legs_joint_node.children, generate_man_limb(L, quaternion(-math.pi/6, vector3(0,0,1)), L*1.6, quaternion(math.pi/6, vector3(0,0,1))))
	return body
end

function generate_man_head(positionV3, orientationQ)
	local node = 
	{	robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, L/2, L/2*math.sqrt(3)),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, -L/2, L/2*math.sqrt(3)),
			orientationQ = quaternion(),
		},
	}}

	return node
end

function generate_man_limb(L_1, orientationQ_1, L_2, orientationQ_2)
	local node ={
		robotTypeS = "drone",
		positionV3 = vector3(L_1, 0, 0):rotate(orientationQ_1),
		orientationQ = orientationQ_1,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L_2, 0, 0):rotate(orientationQ_2),
			orientationQ = orientationQ_2,
		}
	}}
	return node
end

function generate_man_body()
	local left_shoulder = {
		robotTypeS = "drone",
		positionV3 = vector3(0, -L, 0),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
		children = {},
	}
	local right_shoulder = {
		robotTypeS = "drone",
		positionV3 = vector3(0, L, 0),
		orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
		children = {},
	}
	local waist_bottom = {
		robotTypeS = "drone",
		positionV3 = vector3(0, 0, -L),
		orientationQ = quaternion(math.pi/2, vector3(0,1,0)),
		children = {},
	}
	local waist_top = {
		robotTypeS = "drone",
		positionV3 = vector3(0, 0, -L),
		orientationQ = quaternion(),
		children = {waist_bottom},
	}
	local node = 
	{	robotTypeS = "drone",
		positionV3 = vector3(),
		orientationQ = quaternion(),
		children = {
			left_shoulder,
			right_shoulder,
			waist_top,
	}}

	return node, node, left_shoulder, right_shoulder, waist_bottom
end