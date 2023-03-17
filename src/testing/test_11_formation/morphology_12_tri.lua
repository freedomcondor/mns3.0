local L = 1.5

local S = L * 0.5
local D = L * 0.5 * math.sqrt(3)
	
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(D, 0, S),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(D, 0, -S),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, L),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-D, 0, S),
				orientationQ = quaternion(),
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(0, 0, L),
					orientationQ = quaternion(),
				}
			}},
		}},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(-D*0.5, -D*0.5*math.sqrt(3), S),
		orientationQ = quaternion(-2/3*math.pi, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(D, 0, -S),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, L),
			orientationQ = quaternion(),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(-D*0.5, D*0.5*math.sqrt(3), S),
		orientationQ = quaternion(2/3*math.pi, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(D, 0, -S),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, L),
			orientationQ = quaternion(),
		},
	}},
}}
