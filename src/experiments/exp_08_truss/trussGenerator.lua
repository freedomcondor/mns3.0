local baseValueFunction = function(base, current, target)
	local base_target_V3 = target - base
	local base_current_V3 = current - base
	local dot = base_current_V3:dot(base_target_V3:normalize())
	if dot < 0 then 
		return dot 
	else
		local x = dot
		local x2 = dot ^ 2
		local l = base_current_V3:length()
		local y2 = l ^ 2 - x2
		elliptic_distance2 = (1/6) * x2 + y2
		return elliptic_distance2
	end
end

function create_horizontal_truss_node_2(L, positionV3, orientationQ)
return {
	robotTypeS = "drone",
	positionV3 = positionV3 or vector3(),
	orientationQ = orientationQ or quaternion(),
	drawLines = {
		vector3(L, 0, 0),
		vector3(L*0.5, -L*0.5, L*1.5),
		vector3(L*0.5, -L*0.5, -L*1.5),
		vector3(0, -L, 0),
	},
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, -L, 0),
		orientationQ = quaternion(),
		priority = 0.1,
		drawLines = {
			vector3(L, 0, 0),
			vector3(L*0.5, L*0.5, L*1.5),
			vector3(L*0.5, L*0.5, -L*1.5),
		},
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, -L*0.5, L*1.5),
		orientationQ = quaternion(),
		priority = 0.01,
		drawLines = {
			vector3(L*0.5, L*0.5, -L*1.5),
			vector3(L*0.5, -L*0.5, -L*1.5),
			vector3(L, 0, 0),
		},
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, -L*0.5, -L*1.5),
		orientationQ = quaternion(),
		priority = 0.01,
		drawLines = {
			vector3(L*0.5, L*0.5,  L*1.5),
			vector3(L*0.5, -L*0.5, L*1.5),
			vector3(L, 0, 0),
		},
	},
}}
end

function create_horizontal_truss_node(L, positionV3, orientationQ, horizontal_line)
local dis = L * 0.5
return {
	robotTypeS = "drone",
	positionV3 = positionV3 or vector3(),
	orientationQ = orientationQ or quaternion(),
	drawLines = {vector3(L, 0, 0)},
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, L*0.5, L*1.5),
		orientationQ = quaternion(),
		priority = 0.01,
		drawLines = {
			vector3(L*0.5, -L*0.5, -L*1.5),
			vector3(-L*0.5, -L*0.5, -L*1.5),

			vector3(L*0.5, -L*0.5, L*1.5),
			vector3(-L*0.5, -L*0.5, L*1.5),
			vector3(0, -L, 0),
			vector3(L, 0, 0),
		},
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-L*0.5, -L*0.5, L*1.5),
			orientationQ = quaternion(),
			drawLines = {
				vector3(L, 0, 0),
			},
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, -L*0.5, L*1.5),
		orientationQ = quaternion(),
		priority = 0.01,
		drawLines = {
			vector3(L*0.5, L*0.5, -L*1.5),
			vector3(-L*0.5, L*0.5, -L*1.5),

			vector3(L*0.5, L*0.5, L*1.5),
			vector3(-L*0.5, L*0.5, L*1.5),

			vector3(L, 0, 0),
		},
	},
}}
end

function create_horizontal_truss_chain(n, L, node_relative_positionV3, node_relative_orientationQ, start_positionV3, start_orientationQ)
	local new_node = create_horizontal_truss_node(L, start_positionV3 or node_relative_positionV3, start_orientationQ or node_relative_orientationQ)
	if n ~= 1 then
		local sub_nodes, tail
		sub_nodes, tail = create_horizontal_truss_chain(n-1, L,
		                                                node_relative_positionV3,
		                                                node_relative_orientationQ
		                                               )
		table.insert(new_node.children, sub_nodes)
	end
	return new_node, tail
end

function create_vertical_truss_node(L, positionV3, orientationQ)
return {
	robotTypeS = "drone",
	positionV3 = positionV3 or vector3(),
	orientationQ = orientationQ or quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, L*0.5, L*1.5),
		orientationQ = quaternion(),
	},
	}}
end