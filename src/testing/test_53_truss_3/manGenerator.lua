require("trussGenerator")
require("sphere20Generator")
local DeepCopy = require("DeepCopy")

local light_blue = "128, 128, 255"
local grey_color = "200, 200, 200"

local L = 5

function create_shoulder(positionV3, orientationQ, shoulder_angle_Z, shoulder_angle_Y, fore_arm_angle_Z, fore_arm_angle_Y)
	local thick = L * 1.7
	local shoulder_orientationQ = quaternion(-math.pi/2, vector3(0,1,0)) *
	                              quaternion(math.pi, vector3(1,0,0)) *
	                              quaternion(shoulder_angle_Z * math.pi/180, vector3(0,0,1)) *
	                              quaternion(shoulder_angle_Y * math.pi/180, vector3(0,1,0))
	local arm = create_arm(L, L, "red", "red", vector3(0,0,L*0.5), shoulder_orientationQ, fore_arm_angle_Z, fore_arm_angle_Y)
	local node = create_complex_beam(1, L, thick, "red", positionV3, orientationQ * quaternion(math.pi, vector3(1,0,0)), {arm})
	return node
end

function create_arm(L, thick, color, color_fore_arm, positionV3, orientationQ, angleZ, angleY)
	local fore_arm_orientationQ = quaternion(math.pi, vector3(1, 0, 0)) *
	                              quaternion(-angleZ * math.pi/180, vector3(0,0,1)) *
	                              quaternion(-angleY * math.pi/180, vector3(0,1,0))
	local fore_arm, tail = create_complex_beam(2, L, thick,
	                                   color_fore_arm,
	                                   vector3(L*0.25, 0, thick) +
	                                   vector3(L*0.25, 0, 0):rotate(fore_arm_orientationQ),
	                                   fore_arm_orientationQ
	                                  )
	local node = create_complex_beam(1, L, thick,
	                         color,
	                         positionV3, orientationQ,
	                         {fore_arm}
	)
	return node
end

function create_chest(color, positionV3, orientationQ)
	local scale = 0.75
	return 
	{	robotTypeS = "drone",
		positionV3 = positionV3 or vector3(L * 0.75, 0, -L*scale*1.5),
		orientationQ = orientationQ or quaternion(),
		lightShowLED = color,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, L * scale, -L*scale*0.5),
			orientationQ = quaternion(),
			lightShowLED = color,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, L * scale, 0),
				orientationQ = quaternion(),
				lightShowLED = color,
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(-L*0.5, L*0.5*scale, 0),
				orientationQ = quaternion(),
				lightShowLED = color,
			},
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, -L * scale, -L*scale*0.5),
			orientationQ = quaternion(),
			lightShowLED = color,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, -L * scale, 0),
				orientationQ = quaternion(),
				lightShowLED = color,
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(-L*0.5, -L*0.5*scale, 0),
				orientationQ = quaternion(),
				lightShowLED = color,
			},
		}}
	}}
end

function create_body(option)
	local option = option or {}
	local left_shoulder_Z = option.left_shoulder_Z or -15   -- + front
	local left_shoulder_Y = option.left_shoulder_Y or -20   -- + inside
	local left_fore_arm_Z = option.left_fore_arm_Z or 30    -- + front
	local left_fore_arm_Y = option.left_fore_arm_Y or 30    -- + inside

	local right_shoulder_Z = option.right_shoulder_Z or -15   -- + front
	local right_shoulder_Y = option.right_shoulder_Y or -20   -- + inside
	local right_fore_arm_Z = option.right_fore_arm_Z or 30    -- + front
	local right_fore_arm_Y = option.right_fore_arm_Y or 30    -- + inside

	local node = create_sphere20("blue")
	--table.insert(node.children, create_chest(light_blue))

	table.insert(node.children, create_shoulder(vector3(-L*0.1, L*0.25, -L*0.4),
	                                            quaternion(math.pi/2, vector3(0,0,1)),
	                                            -left_shoulder_Z, left_shoulder_Y,          -- shoulder Z and Y
	                                            -left_fore_arm_Z, left_fore_arm_Y           -- fore arm z and Y
	                                           )
	            )
	table.insert(node.children, create_shoulder(vector3(-L*0.1, -L*0.25, -L*0.4),
	                                            quaternion(-math.pi/2, vector3(0,0,1)),
	                                            right_shoulder_Z, right_shoulder_Y,
	                                            right_fore_arm_Z, right_fore_arm_Y)
	            )

	local spine, tail = create_complex_beam(2, L, L, "red", vector3(-L*0.35, 0, -L*0.9), quaternion(math.pi/2, vector3(0,1,0)))
	table.insert(node.children, spine)
	tail.children = {}
	table.insert(tail.children,
	             create_arm(L, L,
	                        grey_color, "blue",
	                        vector3(0, L * 0.5, L * 0.5),
	                        quaternion(-math.pi/2, vector3(1,0,0)) *
	                        quaternion(-2.5 * math.pi/180, vector3(0,0,1)) *    -- + front?
	                        quaternion(-15 * math.pi/180, vector3(0,1,0)),      -- + inside
	                        5, 10
	                       )
	            )

	table.insert(tail.children,
	             create_arm(L, L,
	                        grey_color, "blue",
	                        vector3(0, -L * 0.5, L * 0.5),
	                        quaternion(math.pi/2, vector3(1,0,0)) *
	                        quaternion(2.5 * math.pi/180, vector3(0,0,1)) *    -- + front?
	                        quaternion(-15 * math.pi/180, vector3(0,1,0)),      -- + inside
	                        -5, 10
	                       )
	            )

	return node
end