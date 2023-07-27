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
		elliptic_distance2 = (1/12) * x2 + y2
		return elliptic_distance2
	end
end

function create_beam_node(L, thick, positionV3, orientationQ)
local dis = L * 0.5
return {
	robotTypeS = "drone",
	positionV3 = positionV3 or vector3(),
	orientationQ = orientationQ or quaternion(),
	calcBaseValue = baseValueFunction,
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, L, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, L*0.5, thick),
		orientationQ = quaternion(),
		priority = 0.01,
	},
}}
end

function create_beam_chain(n, L, thick, start_position, start_orientation)
	local new_node = create_beam_node(L, thick, start_position or vector3(L, 0, 0), start_orientation or quaternion())
	local tail = new_node
	if n ~= 1 then
		local sub_nodes
		sub_nodes, tail = create_beam_chain(n-1, L, thick)
		table.insert(new_node.children, sub_nodes)
	end
	return new_node, tail
end

function create_beam(n, L, thick, positionV3, orientationQ, children)
	local head_node = {
		robotTypeS = "drone",
		positionV3 = positionV3 or vector3(),
		orientationQ = orientationQ or quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L*0.5, 0, thick),
			orientationQ = quaternion(),
			priority = 0.01,
		},
	}}
	local chain, tail = create_beam_chain(n, L, thick, vector3(L, -L*0.5, 0))
	local tail_node = {
		robotTypeS = "drone",
		positionV3 = vector3(L, L*0.5, 0),
		orientationQ = quaternion(),
	}
	table.insert(tail.children, tail_node)
	table.insert(head_node.children, chain)
	tail_node.children = children
	return head_node, tail_node
end

function create_beams(n, L)
	local thick = L * 1.5

	local front_line,      front_tail      = create_beam(n, L, thick, vector3(L*0.5, 0, -thick), quaternion())
	local front_left_line, front_left_tail = create_beam(n, L, thick, vector3(0, L*0.5, -thick), quaternion(math.pi/2, vector3(0,0,1)))
	local front_joint = {
		robotTypeS = "drone",
		positionV3 = vector3(L*0.5, 0, thick),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
			front_left_line,
		},
	}
	front_tail.children = {front_joint}

	local left_line,       left_tail       = create_beam(n, L, thick, vector3(0, L*0.5, -thick), quaternion(math.pi/2, vector3(0,0,1)))
	local left_front_line, left_front_tail = create_beam(n, L, thick, vector3(0, -L*0.5, -thick), quaternion(-math.pi/2, vector3(0,0,1)))
	local left_joint = {
		robotTypeS = "drone",
		positionV3 = vector3(L*0.5, 0, thick),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
			left_front_line,
		},
	}
	left_tail.children = {left_joint}

	local left_front_joint = {
		robotTypeS = "drone",
		positionV3 = vector3(L*0.5, 0, thick),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
	}
	left_front_tail.children = {
		left_front_joint
	}

	local head_node = {
		robotTypeS = "drone",
		positionV3 = vector3(),
		orientationQ = quaternion(),
		children = {
			front_line,
			left_line,
			--create_beam(n, L, thick, vector3(-L*0.5, -L*0.5, L*0.5), quaternion(-math.pi*0.75, vector3(0,0,1))*quaternion(-math.pi/2, vector3(0,1,0))),
		},
	}
	return head_node
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