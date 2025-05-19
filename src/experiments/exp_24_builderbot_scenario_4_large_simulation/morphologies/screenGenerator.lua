local L = 5

function generate_screen_square(n, positionV3, orientationQ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end
	local node = generate_square_line(n, positionV3, orientationQ, vector3(0, 0, L), quaternion())
	local current_node = node
	for i = 2, n do
		local new_node = generate_square_line(n, vector3(0, L, 0), quaternion(), vector3(0, 0, L), quaternion(), vector3(0, -L, 0))
		table.insert(current_node.children, new_node)
		current_node = new_node
	end
	return node
end

function generate_square_line(n, positionV3, orientationQ, offsetPositionV3, offsetOrientationQ, horizontal_line)
	if n == 1 then
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = {
				horizontal_line,
			},
		}
	else
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = {
				offsetPositionV3,
				horizontal_line,
			},
			children = {
				generate_square_line(n - 1, offsetPositionV3, offsetOrientationQ, offsetPositionV3, offsetOrientationQ, horizontal_line)
			}
		}
	end
end