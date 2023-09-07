local dis = 2.0
local height = 1.5
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, dis/2, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, -dis/2, 0),
		orientationQ = quaternion(),
	},
}}
