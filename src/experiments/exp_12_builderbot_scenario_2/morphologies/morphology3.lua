local dis = 0.5
local height = 1.7

function generate_line(n, startPositionV3, startOrientationQ, offsetPositionV3, offsetOrientationQ)
	if n == 1 then
		return 
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0,0,height),
				orientationQ = quaternion(),
			},
		}}
	else
		return 
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0,0,height),
				orientationQ = quaternion(),
			},
			generate_line(n - 1, offsetPositionV3, offsetOrientationQ, offsetPositionV3, offsetOrientationQ),
		}}
	end
end

local n = 4
local Q1 = quaternion(math.pi/(n+1), vector3(0,0,1))
local half_Q1 = quaternion(math.pi/(n+1)/2, vector3(0,0,1))
local Q2 = quaternion(-math.pi/(n+1), vector3(0,0,1))
local half_Q2 = quaternion(-math.pi/(n+1)/2, vector3(0,0,1))

return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "builderbot",
		positionV3 = vector3(dis,0,0),
		orientationQ = quaternion(),
	},
	generate_line(4, vector3(0, dis, 0):rotate(half_Q1), half_Q1, vector3(0, dis, 0):rotate(Q1), Q1),
	generate_line(4, vector3(0, -dis, 0):rotate(half_Q2), half_Q2, vector3(0, -dis, 0):rotate(Q2), Q2),
}}

