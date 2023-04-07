function create_node(n, dis)
	local node = {
		robotTypeS = "drone",
		positionV3 = vector3(0, 0, -dis),
		orientationQ = quaternion(),
	}
	if n == 1 then
		return node
	else
		node.children = {create_node(n-1, dis)}
		return node
	end
end

--return create_node(5, dis)