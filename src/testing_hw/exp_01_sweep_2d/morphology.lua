local dis = 1.8
local height = 1.7
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis, 0),
		orientationQ = quaternion(),
	},
}}
