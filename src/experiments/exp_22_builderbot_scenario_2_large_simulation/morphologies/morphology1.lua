local dis = 1.0
local height = 1.7

function generate_line(n, startPositionV3, startOrientationQ, offsetPositionV3, offsetOrientationQ)
	if n == 1 then
		local node = 
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
			mission = "pusher",
		}
		node.children = {}
		table.insert(node.children,
		{	robotTypeS = "drone",
			positionV3 = vector3(0,dis/2,height),
			orientationQ = quaternion(),
		})
		return node
	else
		local node = 
		{	robotTypeS = "pipuck",
			positionV3 = startPositionV3,
			orientationQ = startOrientationQ,
			mission = "pusher",
			children = {
			generate_line(n - 1, offsetPositionV3, offsetOrientationQ, offsetPositionV3, offsetOrientationQ),
		}}
		table.insert(node.children,
		{	robotTypeS = "drone",
			positionV3 = vector3(0,dis/2,height),
			orientationQ = quaternion(),
		})
		return node
	end
end

local n = 8

return generate_line(n, vector3(0, dis, 0), quaternion(), vector3(0, dis, 0), quaternion())
