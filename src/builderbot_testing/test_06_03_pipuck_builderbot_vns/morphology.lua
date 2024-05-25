local dis = 1.0
local height = 1.7
return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(dis/3, 0, height),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "builderbot",
		positionV3 = vector3(dis/2, 0, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(0, dis/2, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(0, -dis/2, 0),
		orientationQ = quaternion(),
		reference = true
	},
}}
