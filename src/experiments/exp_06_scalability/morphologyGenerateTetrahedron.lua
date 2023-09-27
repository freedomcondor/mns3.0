local L = 5

DeepCopy = require("DeepCopy")

function generate_tetrahedron_morphology(n_nodes)
	local n_side = 1
	while ( (1.0/6)*n_side*(n_side+1)*(n_side+2) < n_nodes ) do
		n_side = n_side + 1
	end
	return generate_tetrahedron(n_nodes, n_side, vector3(), quaternion()), n_side
end

function generate_tetrahedron(n_nodes, n_side, positionV3, orientationQ)
	if n_side == 1 then
		return {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	end

	local n_nodes_tetrahedron_minus_1 = (1.0/6)*(n_side-1)*(n_side)*(n_side+1)
	local tetrahedron_child = generate_tetrahedron(n_nodes_tetrahedron_minus_1, n_side-1, vector3(L/math.sqrt(3), 0, 1.2*L*math.sqrt(2)/math.sqrt(3)), quaternion())
	--local tetrahedron_child = generate_tetrahedron(n_nodes_tetrahedron_minus_1, n_side-1, vector3(L/math.sqrt(3), 0, L), quaternion())

	local node = generate_triangle(n_nodes - n_nodes_tetrahedron_minus_1, n_side, positionV3, orientationQ)
	if node.children == nil then node.children = {} end
	table.insert(node.children, tetrahedron_child)
	return node
end

function generate_triangle(n_nodes, n_side, positionV3, orientationQ)
	if n_side == 1 then
		return {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	end

	local node
	if n_nodes <= n_side then
		node = generate_tetrahedron_line(n_nodes, vector3(L*math.sqrt(3)/2, L*0.5, 0), quaternion())
		node.positionV3 = positionV3
		node.orientationQ = orientationQ
	else
		node = generate_tetrahedron_line(n_side, vector3(L*math.sqrt(3)/2, L*0.5, 0), quaternion())
		node.positionV3 = positionV3
		node.orientationQ = orientationQ
		if node.children == nil then node.children = {} end
		table.insert(node.children,
			generate_triangle(n_nodes - n_side, n_side-1, vector3(L*math.sqrt(3)/2, -L*0.5, 0), quaternion())
		)
	end
	return node
end

function generate_tetrahedron_line(n, positionV3, orientationQ)
	if n < 1 then return end
	if n == 1 then
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = drawLines,
		}
	else
		local node = 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_tetrahedron_line(n - 1, positionV3, orientationQ)
			}
		}
		return node
	end
end