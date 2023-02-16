local dis = 1.5
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis/3, 0, dis),
		orientationQ = quaternion(math.pi/6, vector3(0,1,0)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, dis/2, dis),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, -dis/2, dis),
			orientationQ = quaternion(),
		},
	}},
}}
