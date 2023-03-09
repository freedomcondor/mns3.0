local dis = 1.5
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, 0, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(dis/2, 0, dis),
		orientationQ = quaternion(-math.pi/2, vector3(1,0,0)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(dis*3/2, 0, dis),
		orientationQ = quaternion(-math.pi/2, vector3(1,0,0)),
	},
}}
