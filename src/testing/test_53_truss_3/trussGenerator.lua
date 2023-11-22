--[[
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
--]]

local baseValueFunction = function(base, current, target)
	return 0
end

function create_complex_beam_node(L, thick, positionV3, orientationQ)
local half_L = L * 0.5
local quater_L = L * 0.25
local half_thick = thick * 0.5
local tail = {
	robotTypeS = "drone",
	positionV3 = vector3(half_L, 0, 0),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(quater_L, half_L, half_thick),
		orientationQ = quaternion(),
		priority = 3,
		children = {
		--[[
		{	robotTypeS = "drone",
			positionV3 = vector3(0, half_L, 0),
			orientationQ = quaternion(),
		},
		--]]
		{	robotTypeS = "drone",
			positionV3 = vector3(quater_L, 0, half_thick),
			orientationQ = quaternion(),
			priority = 3,
		},
	}},
}}
return {
	robotTypeS = "drone",
	positionV3 = positionV3 or vector3(),
	orientationQ = orientationQ or quaternion(),
	calcBaseValue = baseValueFunction,
	children = {
	tail,
	{	robotTypeS = "drone",
		positionV3 = vector3(quater_L, half_L, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-quater_L, half_L, 0),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(quater_L, half_L, 0),
			orientationQ = quaternion(),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(quater_L, quater_L, half_thick),
		orientationQ = quaternion(),
		priority = 3,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(quater_L, quater_L, half_thick),
			orientationQ = quaternion(),
			priority = 3,
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, half_L, 0),
			orientationQ = quaternion(),
		},
	}},
}}, tail
end

function create_complex_beam_chain(n, L, thick, start_position, start_orientation)
	local new_node, node_tail = create_complex_beam_node(L, thick, start_position or vector3(L * 0.5, 0, 0), start_orientation or quaternion())
	local chain_tail = node_tail
	if n ~= 1 then
		local sub_nodes
		sub_nodes, chain_tail = create_complex_beam_chain(n-1, L, thick)
		table.insert(node_tail.children, sub_nodes)
	end
	return new_node, chain_tail
end

function create_complex_beam(n, L, thick, color, positionV3, orientationQ, children)
	local half_L = L * 0.5
	local quater_L = L * 0.25
	local half_thick = thick * 0.5

	local head_tail = 
		{	robotTypeS = "drone",
			positionV3 = vector3(half_L, -quater_L, 0),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			priority = 3,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, half_L, 0),
				orientationQ = quaternion(),
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(quater_L, quater_L, half_thick),
				orientationQ = quaternion(),
				priority = 3,
				children = {
				--[[
				{	robotTypeS = "drone",
					positionV3 = vector3(0, half_L, 0),
					orientationQ = quaternion(),
				},
				--]]
				{	robotTypeS = "drone",
					positionV3 = vector3(quater_L, 0, half_thick),
					orientationQ = quaternion(),
					priority = 3,
				},
			}},
		}}

	local head_node = {
		robotTypeS = "drone",
		positionV3 = positionV3 or vector3(),
		orientationQ = orientationQ or quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(quater_L, 0, half_thick),
			orientationQ = quaternion(),
			priority = 3,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(quater_L, 0, half_thick),
				orientationQ = quaternion(),
				priority = 3,
			}
		}},
		head_tail,
	}}
	local chain, chain_tail = create_complex_beam_chain(n, L, thick, vector3(half_L, -quater_L, 0))

	local tail_node_tail = 
		{	robotTypeS = "drone",
			positionV3 = vector3(half_L, quater_L, 0),
			orientationQ = quaternion(),
		}
	local tail_node = {
		robotTypeS = "drone",
		positionV3 = vector3(half_L, quater_L, 0),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
		tail_node_tail,
		{	robotTypeS = "drone",
			positionV3 = vector3(quater_L, quater_L, half_thick),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, half_L, 0),
			orientationQ = quaternion(),
		},
	}}
	table.insert(chain_tail.children, tail_node)
	table.insert(head_tail.children, chain)
	tail_node_tail.children = children
	return head_node, tail_node_tail
end