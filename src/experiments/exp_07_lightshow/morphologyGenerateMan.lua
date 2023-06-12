local L = 3

function generate_man(head_orientation, arm_orientation, leg_orientation)
	local body, head_joint_node, left_shoulder_joint_node, right_shoulder_joint_node, left_leg_joint_node, right_leg_joint_node = generate_man_body()
	joint_insert(head_joint_node.children, generate_man_head(vector3(0,0,L/2), head_orientation))
	joint_insert(left_shoulder_joint_node.children, generate_man_limb(L, quaternion(math.pi/2, vector3(0,1,0)) * arm_orientation, L*1.2, quaternion() * arm_orientation))
	joint_insert(right_shoulder_joint_node.children, generate_man_limb(L, quaternion(math.pi/2, vector3(0,1,0)), L*1.2, quaternion()))
	joint_insert(left_leg_joint_node.children, generate_man_limb(L, quaternion(-math.pi/6, vector3(0,0,1)) * leg_orientation, L*1.6, quaternion(math.pi/6, vector3(0,0,1))*leg_orientation))
	joint_insert(right_leg_joint_node.children, generate_man_limb(L, quaternion(math.pi/6, vector3(0,0,1)), L*1.6, quaternion(-math.pi/6, vector3(0,0,1))))
	return body
end

function joint_insert(joint_node, children)
	for id, child in ipairs(children) do
		table.insert(joint_node, child)
	end
end

-- Head --------------------------------------------------------
local baseValueFunction = function(base, current, target)
	local base_target_V3 = target - base
	local base_current_V3 = current - base
	local dot = base_current_V3:dot(base_target_V3:normalize())
	if dot < 0 then 
		return dot 
	else
		local x = dot
		local x2 = dot ^ 2
		local l = base_current_V3:length()
		local y2 = l ^ 2 - x2
		elliptic_distance2 = (1/4) * x2 + y2
		return elliptic_distance2
	end
end

local dis = L/2
local height = dis * 1.5

function generate_man_head(positionV3, orientationQ)
	local children = {
	{	robotTypeS = "drone",
		id = "rec12",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		drawLines = {vector3(dis, 0, 0), vector3(0, dis, 0), vector3(0, -dis, 0), vector3(0, 0, height)},

		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, 0, 0),
			orientationQ = quaternion(),
			drawLines = {vector3(0, dis, 0), vector3(0, -dis, 0), vector3(0, 0, height)},
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, dis, 0),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			drawLines = {vector3(dis, 0, 0), vector3(0, 0, height)},
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(dis, 0, 0),
				orientationQ = quaternion(),
				drawLines = {vector3(0, 0, height)},
			},
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, -dis, 0),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			drawLines = {vector3(dis, 0, 0), vector3(0, 0, height)},
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(dis, 0, 0),
				orientationQ = quaternion(),
				drawLines = {vector3(0, 0, height)},
			},
		}},
		
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, height),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			drawLines = {vector3(dis, 0, 0), vector3(0, dis, 0), vector3(0, -dis, 0)},
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(dis, 0, 0),
				orientationQ = quaternion(),
				drawLines = {vector3(0, dis, 0), vector3(0, -dis, 0)},
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(0, dis, 0),
				orientationQ = quaternion(),
				calcBaseValue = baseValueFunction,
				drawLines = {vector3(dis, 0, 0)},
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(dis, 0, 0),
					orientationQ = quaternion(),
				},
			}},
			{	robotTypeS = "drone",
				positionV3 = vector3(0, -dis, 0),
				orientationQ = quaternion(),
				calcBaseValue = baseValueFunction,
				drawLines = {vector3(dis, 0, 0)},
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(dis, 0, 0),
					orientationQ = quaternion(),
			},
			}},
		}},
	}}

	}
	return children
end

function generate_man_limb(L_1, orientationQ_1, L_2, orientationQ_2)
	local children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L_1/2, L_1/8, 0):rotate(orientationQ_1),
			orientationQ = orientationQ_1,
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(L_1/2, -L_1/8, 0):rotate(orientationQ_1),
			orientationQ = orientationQ_1,
			children = {
			{
				robotTypeS = "drone",
				positionV3 = vector3(L_1/2, L_1/8, 0),
				orientationQ = quaternion(),
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(L_2/2, L_2/6, L_2/6):rotate(orientationQ_2),
					orientationQ = orientationQ_2,
					children = {
					{	robotTypeS = "drone",
						positionV3 = vector3(L_2/2, -L_2/6, -L_2/6),
						orientationQ = quaternion(),
					},
				}},
				{	robotTypeS = "drone",
					positionV3 = vector3(L_2/2, -L_2/6, L_2/6):rotate(orientationQ_2),
					orientationQ = orientationQ_2,
				},
				{	robotTypeS = "drone",
					positionV3 = vector3(L_2/2, -L_2/6, -L_2/6):rotate(orientationQ_2),
					orientationQ = orientationQ_2,
				},
				{	robotTypeS = "drone",
					positionV3 = vector3(L_2/2, L_2/6, -L_2/6):rotate(orientationQ_2),
					orientationQ = orientationQ_2,
				},
			}}
		}},
	}
	return children
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
	local left_waist = {
		robotTypeS = "drone",
		positionV3 = vector3(0, -L*0.6, 0),
		orientationQ = quaternion(math.pi/2, vector3(0,1,0)),
		children = {},
	}
	local right_waist = {
		robotTypeS = "drone",
		positionV3 = vector3(0, L*0.6, 0),
		orientationQ = quaternion(math.pi/2, vector3(0,1,0)),
		children = {},
	}
	local node = 
	{	robotTypeS = "drone",
		positionV3 = vector3(),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, -L, 0),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-L, 0, 0),
				orientationQ = quaternion(),
			},
			left_shoulder,
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, L, 0),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-L, 0, 0),
				orientationQ = quaternion(),
			},
			right_shoulder,
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, -L),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, -L*0.6, 0),
				orientationQ = quaternion(),
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(-L, 0, 0),
					orientationQ = quaternion(),
				},
				{	robotTypeS = "drone",
					positionV3 = vector3(0, -L*0.6, 0),
					orientationQ = quaternion(),
				},
			}},
			{	robotTypeS = "drone",
				positionV3 = vector3(0, L*0.6, 0),
				orientationQ = quaternion(),
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(-L, 0, 0),
					orientationQ = quaternion(),
				},
				{	robotTypeS = "drone",
					positionV3 = vector3(0, L*0.6, 0),
					orientationQ = quaternion(),
				},
			}},
			{	robotTypeS = "drone",
				positionV3 = vector3(0, 0, -L),
				orientationQ = quaternion(),
				children = {
					{	robotTypeS = "drone",
						positionV3 = vector3(-L/2, -L/2, 0),
						orientationQ = quaternion(),
					},
					{	robotTypeS = "drone",
						positionV3 = vector3(-L/2, L/2, 0),
						orientationQ = quaternion(),
					},
					left_waist,
					right_waist,
			}}
		}},
	}}

	return node, node, left_shoulder, right_shoulder, left_waist, right_waist
end