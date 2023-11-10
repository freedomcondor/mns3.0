local dis = 1.5
local height = 1.7
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, 0, 0),
		orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(dis/2, dis/2, -height),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
		priority = 2,
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(dis/2, -dis/2, -height),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis/2, -dis/2, -height),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis/2, dis/2, -height),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
	},
}}
