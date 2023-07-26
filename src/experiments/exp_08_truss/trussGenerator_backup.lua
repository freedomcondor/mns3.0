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

function create_truss_node_10(L, positionV3, orientationQ)
local dis = L * 0.5
return {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(L, 0, 0),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis, dis, 0),
			orientationQ = quaternion(),
		}
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, L, 0),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L, 0, 0),
			orientationQ = quaternion(),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, 0, L),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L, 0, 0),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, dis, 0),
				orientationQ = quaternion(),
			}
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, L, 0),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(L, 0, 0),
				orientationQ = quaternion(),
			},
		}},
	}},
}}
end

function create_truss_node_20(L, positionV3, orientationQ)
local dis = L * 0.5
return {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	-- front
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, 0, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, 0, 0),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, dis, 0),
				orientationQ = quaternion(),
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(0, 0, dis),
				orientationQ = quaternion(),
			},
		}},
	}},
	-- left
	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, dis, 0),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, 0, dis),
				orientationQ = quaternion(),
			},
			-- front
			{	robotTypeS = "drone",
				positionV3 = vector3(dis, 0, 0),
				orientationQ = quaternion(),
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(dis, 0, 0),
					orientationQ = quaternion(),
					calcBaseValue = baseValueFunction,
					-- up
					children = {
					{	robotTypeS = "drone",
						positionV3 = vector3(0, 0, dis),
						orientationQ = quaternion(),
					}
				}},
			}},
		}},
	}},
	-- up
	{	robotTypeS = "drone",
		positionV3 = vector3(0, 0, dis),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, dis),
			orientationQ = quaternion(),
			calcBaseValue = baseValueFunction,
			children = {
			-- front
			{	robotTypeS = "drone",
				positionV3 = vector3(dis, 0, 0),
				orientationQ = quaternion(),
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(dis, 0, 0),
					orientationQ = quaternion(),
					calcBaseValue = baseValueFunction,
					children = {
					-- left
					{	robotTypeS = "drone",
						positionV3 = vector3(0, dis, 0),
						orientationQ = quaternion(),
					}
				}},
			}},
			-- left
			{	robotTypeS = "drone",
				positionV3 = vector3(0, dis, 0),
				orientationQ = quaternion(),
				children = {
				{	robotTypeS = "drone",
					positionV3 = vector3(0, dis, 0),
					orientationQ = quaternion(),
					calcBaseValue = baseValueFunction,
					children = {
					-- front
					{	robotTypeS = "drone",
						positionV3 = vector3(dis, 0, 0),
						orientationQ = quaternion(),
						children = {
						{	robotTypeS = "drone",
							positionV3 = vector3(dis, 0, 0),
							orientationQ = quaternion(),
						}
					}}
				}},
			}},
		}},
	}},
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