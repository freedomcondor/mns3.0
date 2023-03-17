local L = 1.5

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
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, 0, L),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L/math.sqrt(3), 0, -L*(math.sqrt(2/3)-0.5*math.sqrt(3/2))),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-L*math.sqrt(3)*0.5, L*0.5, -L*(math.sqrt(2/3)-0.5*math.sqrt(3/2))),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-L*math.sqrt(3)*0.5, -L*0.5, -L*(math.sqrt(2/3)-0.5*math.sqrt(3/2))),
		orientationQ = quaternion(),
	},
}}
