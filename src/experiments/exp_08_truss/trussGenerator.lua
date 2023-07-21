function create_truss_node(L, positionV3, orientationQ)
return {
	robotTypeS = "drone",
	positionV3 = positionV3,
	orientationQ = orientationQ,
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, L, 0),
		orientationQ = quaternion(),
	},
	--[[
	{	robotTypeS = "drone",
		positionV3 = vector3(L, 0, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, L, 0),
			orientationQ = quaternion(),
		},
	}},
	--]]
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, L*0.5, L),
		orientationQ = quaternion(),
		drawLines = {
			vector3( L*0.5, L*0.5, -L),
			vector3(-L*0.5, L*0.5, -L),
			vector3(-L*0.5,-L*0.5, -L),
			vector3( L*0.5,-L*0.5, -L),
		}
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, L*0.5, -L),
		orientationQ = quaternion(),
		drawLines = {
			vector3( L*0.5, L*0.5, L),
			vector3(-L*0.5, L*0.5, L),
			vector3(-L*0.5,-L*0.5, L),
			vector3( L*0.5,-L*0.5, L),
		}
	},
}}
end

function create_truss_chain(n, L, start_positionV3, start_orientationQ, node_positionV3, node_orientationQ)
	if node_positionV3 == nil   then node_positionV3 = start_positionV3     end
	if node_orientationQ == nil then node_orientationQ = start_orientationQ end

	local new_node = create_truss_node(L, start_positionV3, start_orientationQ)
	if n > 4 then
		table.insert(new_node.children, create_truss_chain(n-4, L, node_positionV3, node_orientationQ))
	end

	return new_node
end