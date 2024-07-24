local dis = 1.0
local height = 1.7

local baseValueFunction_target = function(base, current, target)
	return (current - target):length()
end

return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, dis, height),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, -dis, height),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis,0, 0),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction_target,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, dis, 0),
			orientationQ = quaternion(),
			priority = 2,
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0,-dis, 0),
			orientationQ = quaternion(),
			priority = 2,
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis/2, 0, height),
				orientationQ = quaternion(),
			},
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis, 0, 0),
				orientationQ = quaternion(),
			},
		}},
	}},
}}
