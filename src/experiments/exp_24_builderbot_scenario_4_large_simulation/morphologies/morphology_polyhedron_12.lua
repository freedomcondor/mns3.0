local L = 5

local function rad(degree)
	return degree * math.pi / 180
end
local function sin(degree)
	return math.sin(degree * math.pi / 180)
end
local function cos(degree)
	return math.cos(degree * math.pi / 180)
end

local calcBaseValue = function(base, current, target)
    --local base_target_V3 = target - base
    --local base_current_V3 = current - base
    local base_target_V3 = base - target
    local base_current_V3 = current - target 
    base_target_V3.z = 0
    base_current_V3.z = 0
    local dot = base_current_V3:dot(base_target_V3:normalize())
    if dot < 0 then 
        --return dot 
        return 0 
    else
        local x = dot
        local x2 = dot ^ 2
        local l = base_current_V3:length()
        local y2 = l ^ 2 - x2
        elliptic_distance2 = x2 + (1/4) * y2
        --return elliptic_distance2
        --return elliptic_distance2
		return 0
    end
end

local drawLines = function()
	return {
		vector3(L*0.5*(1-cos(36))/sin(36),
		        L*0.5,
		        L/(math.sqrt(2)*sin(36)) *
		            math.sqrt(
		                sin(36)*sin(36) - cos(36)*cos(36) + cos(36)
		            )
		       ),
		vector3(L*0.5*(1-cos(36))/sin(36),
		        -L*0.5,
		        L/(math.sqrt(2)*sin(36)) *
		            math.sqrt(
		                sin(36)*sin(36) - cos(36)*cos(36) + cos(36)
		            )
		       ),
		vector3(L/(2*sin(36)), 
			    0, 
			    -L*math.sqrt(1 - (1 /
			                         (4*sin(36)*sin(36))
			                     )
			                )
			   ),
		vector3(L*sin(36), L*cos(36), 0),
	}
end

local drawLines_upper = function()
	return {
			             vector3(L*sin(36), L*cos(36), 0),
			             vector3(L/(2*sin(36)), 
			                     0, 
			                     L*math.sqrt(1 - (1 /
			                                         (4*sin(36)*sin(36))
			                                      )
			                                 )
			                    ),
	}
end
	
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	drawLines = drawLines(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(L*sin(36), L*cos(36), 0),
		orientationQ = quaternion(rad(-72), vector3(0,0,1)),
        calcBaseValue = calcBaseValue,
		drawLines = drawLines(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L*sin(36), L*cos(36), 0),
			orientationQ = quaternion(rad(-72), vector3(0,0,1)),
			drawLines = drawLines(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(L/(2*sin(36)), 
			                     0, 
			                     -L*math.sqrt(1 - (1 /
			                                         (4*sin(36)*sin(36))
			                                      )
			                                 )
			                    ),
			orientationQ = quaternion(),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(L*sin(36), -L*cos(36), 0),
		orientationQ = quaternion(rad(72), vector3(0,0,1)),
		drawLines = drawLines(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L*sin(36), -L*cos(36), 0),
			orientationQ = quaternion(rad(72), vector3(0,0,1)),
		drawLines = drawLines(),
		},
	}},

	--[[
	{	robotTypeS = "drone",
		positionV3 = vector3(L/(2*sin(36)),
		                     0,
		                     L*0.5/(math.sqrt(2)*sin(36)) *
		                      math.sqrt(
		                       sin(36)*sin(36) - cos(36)*cos(36) + cos(36)
		                      )
		                    ),
		orientationQ = quaternion(),
	},
	--]]

	{	robotTypeS = "drone",
		positionV3 = vector3(L*0.5*(1-cos(36))/sin(36),
		                     L*0.5,
		                     L/(math.sqrt(2)*sin(36)) *
		                      math.sqrt(
		                       sin(36)*sin(36) - cos(36)*cos(36) + cos(36)
		                      )
		                    ),
		orientationQ = quaternion(rad(-36), vector3(0,0,1)),

		--calcBaseValue = calcBaseValue,
		calcBaseValue = function() return 0 end,
		drawLines = drawLines_upper(),

		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(L*sin(36), L*cos(36), 0),
			orientationQ = quaternion(rad(-72), vector3(0,0,1)),

			calcBaseValue = calcBaseValue,
			drawLines = drawLines_upper(),

			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(L*sin(36), L*cos(36), 0),
				orientationQ = quaternion(rad(-72), vector3(0,0,1)),
				drawLines = drawLines_upper(),
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(L/(2*sin(36)), 
				                     0, 
				                     L*math.sqrt(1 - (1 /
				                                         (4*sin(36)*sin(36))
				                                      )
				                                 )
				                    ),
				orientationQ = quaternion(),
			},
		}},
		{	robotTypeS = "drone",
			positionV3 = vector3(L*sin(36), -L*cos(36), 0),
			orientationQ = quaternion(rad(72), vector3(0,0,1)),
			drawLines = drawLines_upper(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(L*sin(36), -L*cos(36), 0),
				orientationQ = quaternion(rad(72), vector3(0,0,1)),
				drawLines = drawLines_upper(),
			},
		}},
	}},
}}
