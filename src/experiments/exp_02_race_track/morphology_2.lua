local L = 5

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
	label = "morphology2",
	children = {
	{	robotTypeS = "drone",
		--positionV3 = vector3(L/(2*sin(36)), 0, L*3), 
		positionV3 = vector3(0, 0, L*3), 
		orientationQ = quaternion(),
	},
}}
