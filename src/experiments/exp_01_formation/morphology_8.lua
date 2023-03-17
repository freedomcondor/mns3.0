local dis = 1.5
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
		elliptic_distance2 = (1/4) * x2 + y2
		return elliptic_distance2
	end
end
	
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, 0, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis, 0),
		orientationQ = quaternion(-math.pi/2, vector3(1,0,0)),
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, 0, 0),
			orientationQ = quaternion(),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, 0, dis*1.5),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, 0, 0),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, dis, 0),
			orientationQ = quaternion(math.pi/2, vector3(1, 0, 0)),
			calcBaseValue = baseValueFunction,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(dis, 0, 0),
				orientationQ = quaternion(),
			},
		}},
	}},
}}
