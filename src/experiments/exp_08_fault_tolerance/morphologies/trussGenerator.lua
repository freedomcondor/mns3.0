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

function create_beam_node(L, thick, color, positionV3, orientationQ, last)
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
	drawLinesColor = color,
	lightShowLED = color,
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, L, 0),
		orientationQ = quaternion(),
		drawLines = {vector3(-L*0.5, -L*0.5, thick),
		             vector3(L*0.5, -L*0.5, thick),
		             horizontal_line,
		             },
		drawLinesColor = color,
		lightShowLED = color,
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5, L*0.5, thick),
		orientationQ = quaternion(),
		drawLines = {vector3(-L, 0, 0)},
		priority = 0.01,
		drawLinesColor = color,
		lightShowLED = color,
	},
}}
end

function create_beam_chain(n, L, thick, color, start_position, start_orientation)
	local new_node = create_beam_node(L, thick, color, start_position or vector3(L, 0, 0), start_orientation or quaternion(), n == 1)
	local tail = new_node
	if n ~= 1 then
		local sub_nodes
		sub_nodes, tail = create_beam_chain(n-1, L, thick, color)
		table.insert(new_node.children, sub_nodes)
	end
	return new_node, tail
end

function create_beam(n, L, thick, color, positionV3, orientationQ, children)
	local head_node = {
		robotTypeS = "drone",
		positionV3 = positionV3 or vector3(),
		orientationQ = orientationQ or quaternion(),
		calcBaseValue = baseValueFunction,
		drawLines = {vector3(L, -L*0.5, 0),
		             vector3(L, L*0.5, 0),
		             vector3(L*0.5, 0, thick),
		            },
		drawLinesColor = color,
		lightShowLED = color,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L*0.5, 0, thick),
			orientationQ = quaternion(),
			priority = 0.01,
			lightShowLED = color,
		},
	}}
	local chain, tail = create_beam_chain(n, L, thick, color, vector3(L, -L*0.5, 0))
	local tail_node = {
		robotTypeS = "drone",
		positionV3 = vector3(L, L*0.5, 0),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		drawLines = {vector3(-L, -L*0.5, 0),
		             vector3(-L, L*0.5, 0),
		             vector3(-L*0.5, 0, thick),
		             },
		drawLinesColor = color,
		lightShowLED = color,
	}
	table.insert(tail.children, tail_node)
	table.insert(head_node.children, chain)
	tail_node.children = children
	return head_node, tail_node
end