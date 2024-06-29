local dis = 0.3
local height = 1.7

function generate_line(n, startPositionV3, startOrientationQ, offsetPositionV3, offsetOrientationQ)
	if n == 1 then
		return 
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
		}
	else
		local node = 
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
			children = {
			generate_line(n - 1, offsetPositionV3, offsetOrientationQ, offsetPositionV3, offsetOrientationQ),
		}}
		table.insert(node.children,
		{	robotTypeS = "drone",
			positionV3 = vector3(0,0,height),
			orientationQ = quaternion(),
		})
		return node
	end
end

local n = 2
local Q1 = quaternion(math.pi/(n+1), vector3(0,0,1))
local half_Q1 = quaternion(math.pi/(n+1)/2, vector3(0,0,1))
local Q2 = quaternion(-math.pi/(n+1), vector3(0,0,1))
local half_Q2 = quaternion(-math.pi/(n+1)/2, vector3(0,0,1))

return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		generate_line(n, vector3(0, dis, 0):rotate(half_Q1), half_Q1, vector3(0, dis, 0):rotate(Q1), Q1),
		generate_line(n, vector3(0, -dis, 0):rotate(half_Q2), half_Q2, vector3(0, -dis, 0):rotate(Q2), Q2),
}}
