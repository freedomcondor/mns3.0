local dis = 0.45
local height = 1.7
return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis/2, height),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(0, -dis, height),
		orientationQ = quaternion(),
		mission = "pusher",
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(0., dis, height),
		orientationQ = quaternion(),
	},
}}