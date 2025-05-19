local dis = 1.0
local height = 1.7

local baseValueFunction_target = function(base, current, target)
	return (current - target):length()
end

function generate_line(n, positionV3, orientationQ, with_drone)
	if n == 1 then
		local node = 
		{	robotTypeS = "pipuck",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
		if with_drone == true then
			node.children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, 0, height),
				orientationQ = orientationQ,
			}}
		end
		return node
	else
		local node = {
			robotTypeS = "pipuck",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_line(n - 1, positionV3, orientationQ, with_drone)
			}
		}
		if with_drone == true and n % 2 == 0 then
			table.insert(node.children, {
				robotTypeS = "drone",
				positionV3 = vector3(0, 0, height),
				orientationQ = orientationQ,
			})
		end
		return node
	end
end

function generate_face(n, m, offsetX, offsetY)
	local node = generate_line(m, offsetY, quaternion(), n % 2 == 0)
	node.positionV3 = offsetX
	--node.calcBaseValue = baseValueFunction_target
	if n == 1 then
		return node
	else
		table.insert(node.children, generate_face(n-1, m, offsetX, offsetY))
		return node
	end
end

return generate_face(5, 5, vector3(0, 1, 0), vector3(-1, 0, 0))
