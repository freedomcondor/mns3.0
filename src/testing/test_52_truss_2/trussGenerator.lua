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

function create_beam_node(L, thick, positionV3, orientationQ, last)
local dis = L * 0.5
local horizontal_line = vector3(L, 0, 0)
if last == true then
	horizontal_line = nil
end
return {
	robotTypeS = "drone",
	positionV3 = positionV3 or vector3(),
	orientationQ = orientationQ or quaternion(),
	calcBaseValue = baseValueFunction,
	drawLines = {vector3(0, L, 0),
	             vector3(-L*0.5, L*0.5, thick),
	             vector3(L*0.5, L*0.5, thick),
	             horizontal_line,
	            },
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, L, 0),
		orientationQ = quaternion(),
		drawLines = {vector3(-L*0.5, -L*0.5, thick),
		             vector3(L*0.5, -L*0.5, thick),
		             horizontal_line,
		             },
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, L*0.5, thick),
		orientationQ = quaternion(),
		drawLines = {vector3(-L, 0, 0)},
		priority = 3,
	},
}}
end

function create_beam_chain(n, L, thick, start_position, start_orientation)
	local new_node = create_beam_node(L, thick, start_position or vector3(L, 0, 0), start_orientation or quaternion(), n == 1)
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
		drawLines = {vector3(L, -L*0.5, 0),
		             vector3(L, L*0.5, 0),
		             vector3(L*0.5, 0, thick),
		            },
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L*0.5, 0, thick),
			orientationQ = quaternion(),
			priority = 3,
		},
	}}
	local chain, tail = create_beam_chain(n, L, thick, vector3(L, -L*0.5, 0))
	local tail_node = {
		robotTypeS = "drone",
		positionV3 = vector3(L, L*0.5, 0),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		drawLines = {vector3(-L, -L*0.5, 0),
		             vector3(-L, L*0.5, 0),
		             vector3(-L*0.5, 0, thick),
		             },
	}
	table.insert(tail.children, tail_node)
	table.insert(head_node.children, chain)
	tail_node.children = children
	return head_node, tail_node
end