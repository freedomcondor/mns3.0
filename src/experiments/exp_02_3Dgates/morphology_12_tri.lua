local L = 0.7

local S = L * 0.5
local D = L * 0.5 * math.sqrt(3)

L = L * 1.5
	
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	drawLines = {vector3(D, 0, S), vector3(-D*0.5, -D*0.5*math.sqrt(3), S), vector3(-D*0.5, D*0.5*math.sqrt(3), S)},

	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(D, 0, S),
		orientationQ = quaternion(),
		drawLines = {vector3(D, 0, -S), vector3(0, 0, L)},
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(D, 0, -S),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, L),
			orientationQ = quaternion(),
			drawLines = {vector3(-D, 0, S)},
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-D, 0, S),
				orientationQ = quaternion(),
				drawLines = {vector3(0, 0, L)},
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
		drawLines = {vector3(D, 0, -S), vector3(0, 0, L)},
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(D, 0, -S),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, L),
			orientationQ = quaternion(),
			drawLines = {vector3(-D, 0, S)},
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(-D*0.5, D*0.5*math.sqrt(3), S),
		orientationQ = quaternion(2/3*math.pi, vector3(0,0,1)),
		drawLines = {vector3(D, 0, -S), vector3(0, 0, L)},
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(D, 0, -S),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, L),
			orientationQ = quaternion(),
			drawLines = {vector3(-D, 0, S)},
		},
	}},
}}
