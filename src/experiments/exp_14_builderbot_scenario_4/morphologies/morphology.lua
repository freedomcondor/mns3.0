local dis = 0.7
local height = 1.7

function create_chain(n)
	if n == 0 then return nil end

	local node =
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis*2, 0, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, dis, -height),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, -dis, -height),
			orientationQ = quaternion(),
		},
		create_chain(n-1),
	}}

	return node
end

return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3( dis, dis, height),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3( dis, -dis, height),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, -dis, height),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis,  dis, height),
		orientationQ = quaternion(),
	},
	create_chain(5-1)
}}
