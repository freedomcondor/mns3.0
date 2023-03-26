local L = 1.5
local height_rate = 2

local function rad(degree)
	return degree * math.pi / 180
end
local function sin(degree)
	return math.sin(degree * math.pi / 180)
end
local function cos(degree)
	return math.cos(degree * math.pi / 180)
end

return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	label = "morphology4",
	drawLines = {vector3(L * math.sqrt(3) * 0.5,  L * 0.5, 0),
	             vector3(L * math.sqrt(3) * 0.5,  -L * 0.5, 0),
	             vector3(L / math.sqrt(3), 0, math.sqrt(2/3) * height_rate)
	            },
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(L * math.sqrt(3) * 0.5,  L * 0.5, 0),
		orientationQ = quaternion(-math.pi*2/3, vector3(0,0,1)),
		drawLines = {vector3(L * math.sqrt(3) * 0.5,  L * 0.5, 0),
		             vector3(L / math.sqrt(3), 0, math.sqrt(2/3) * height_rate)
		            },
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L * math.sqrt(3) * 0.5, -L * 0.5, 0),
		orientationQ = quaternion(math.pi*2/3, vector3(0,0,1)),
		drawLines = {vector3(L / math.sqrt(3), 0, math.sqrt(2/3) * height_rate)},
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L / math.sqrt(3), 0, math.sqrt(2/3) * height_rate),
		orientationQ = quaternion(),
	},
}}
