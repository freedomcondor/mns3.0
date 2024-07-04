local dis = 1.0
local height = 1.7

function generate_line(n, startPositionV3, startOrientationQ, offsetPositionV3, offsetOrientationQ, drone_location)
	local node
	if n == 1 then
		node =
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
		}
	else
		node = 
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
			children = {
			--[[
			{	robotTypeS = "drone",
				positionV3 = vector3(0,0,height),
				orientationQ = quaternion(),
			},
			--]]
			generate_line(n - 1, offsetPositionV3, offsetOrientationQ, offsetPositionV3, offsetOrientationQ, drone_location),
		}}
	end
	if n % 2 == drone_location then
		if node.children == nil then node.children = {} end
		table.insert(node.children,
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis * 0.66,0,height),
				orientationQ = quaternion(),
			}
		)
	end
	
	return node
end

local n = 5
local Q1 = quaternion(math.pi/(n+1), vector3(0,0,1))
local half_Q1 = quaternion(math.pi/(n+1)/2, vector3(0,0,1))
local Q2 = quaternion(-math.pi/(n+1), vector3(0,0,1))
local half_Q2 = quaternion(-math.pi/(n+1)/2, vector3(0,0,1))

return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		generate_line(n, vector3(0, dis, 0):rotate(half_Q1), Q1, vector3(0, dis, 0):rotate(half_Q1), Q1, 1),
		generate_line(n+1, vector3(0, -dis, 0):rotate(half_Q2), Q2, vector3(0, -dis, 0):rotate(half_Q2), Q2, 0),
}}
