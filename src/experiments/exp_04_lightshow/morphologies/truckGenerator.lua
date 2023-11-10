require("trussGenerator")

local L = 5

local baseValueFunction = function(base, current, target)
	return 0
end

local light_blue = "128, 128, 255"
local grey_color = "200, 200, 200"

function create_wheel(color, positionV3, orientationQ, d, n)
	local function create_wheel_chain(color, n, offsetPosition, offsetOrientation, startPosition, startOrientation)
		local node = {
			robotTypeS = "drone",
			positionV3 = startPosition or offsetPosition,
			orientationQ = startOrientation or offsetOrientation,
			calcBaseValue = baseValueFunction,
			drawLines = {offsetPosition, vector3(0, d, 0)},
			drawLinesColor = color,
			lightShowLED = color,
		}

		if n ~= 1 then
			node.calcBaseValue = baseValueFunction
			node.children = {
				create_wheel_chain(color, n-1, offsetPosition, offsetOrientation)
			}
		end

		return node
	end

	local th = math.pi*2/n
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3 or vector3(),
		orientationQ = orientationQ or quaternion(),
		calcBaseValue = baseValueFunction,
		lightShowLED = color,
		children = {
			create_wheel_chain(
				color,
				n,
				-- offset
				vector3(d*math.sin(th),d-d*math.cos(th),0),
				quaternion(th, vector3(0,0,1)),
				-- start
				vector3(0,0,d),
				quaternion(math.pi/2, vector3(0,0,1)) * quaternion(-math.pi/2, vector3(1,0,0))
			)
	}}

	return node
end

function create_truck(th)
	local th = th or 0
	local thick = L * 2

	-- left back body
	local left_body, tail = create_beam(3, L, thick,
	                               "blue",
	                               vector3(0, L * 0.75, 0),
	                               quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )

	local left_tail, tail_tail = create_beam(1, L, thick,
	                               "blue",
	                               vector3(0, 0, thick),
	                               quaternion(math.pi, vector3(1, 0, 0))
	                              )

	tail.children = {
		create_wheel(grey_color,
		             vector3(0, 1.2, thick*0.75),
		             quaternion(math.pi/2, vector3(0,0,1)) * quaternion(th*math.pi/180, vector3(1,0,0)),
		             L, 6
		),
		left_tail
	}

	-- right back body
	local right_body, tail = create_beam(3, L, thick,
	                               "blue",
	                               vector3(0, -L * 0.75, 0),
	                               quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )

	local right_tail, tail_tail = create_beam(1, L, thick,
	                               "blue",
	                               vector3(0, 0, thick),
	                               quaternion(math.pi, vector3(1, 0, 0))
	                              )
	
	tail.children = {
		create_wheel(grey_color,
		             vector3(0, -1.2, thick*0.75),
		             quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(-th*math.pi/180, vector3(1,0,0)),
		             L, 6
		),
		right_tail
	}

	local back = {
		robotTypeS = "drone",
		positionV3 = vector3(0, 0, thick),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
			left_body,
			right_body,
		},
		lightShowLED = "blue",
	}

	-- left front
	local left_front, tail = create_beam(2, L * 1.2, L * 1,
	                                "red",
	                                vector3(L * 0.5, L, 0),
	                                quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi/2, vector3(0, 1, 0))
	                                )

	table.insert(left_front.children,
		create_wheel(grey_color,
		             vector3(thick*0.25, -L, L * 0.5),
		             quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(th*math.pi/180, vector3(1,0,0)),
		             L, 5
		)
	)

	-- right front
	local right_front, tail = create_beam(2, L * 1.2, L * 1,
	                                "red",
	                                vector3(L * 0.5, -L, 0),
	                                quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi/2, vector3(0, 1, 0))
	                                )

	table.insert(right_front.children,
		create_wheel(grey_color,
		             vector3(thick*0.25, L, L * 0.5),
		             quaternion(-math.pi/2, vector3(0,0,1)) * quaternion(th*math.pi/180, vector3(1,0,0)),
		             L, 5
		)
	)

	-- front bottom
	local front_bottom, tail = create_beam(2, L, L * 1.2,
	                                "red",
	                                vector3(0, -L * 0.50, L * 1.7),
	                                quaternion(math.pi/2, vector3(0, 0, 1)) * quaternion(math.pi/2, vector3(1, 0, 0))
	                                )
	
	table.insert(left_front.children,
		front_bottom
	)

	-- front top
	local front_top, tail = create_beam(2, L, L * 1.2,
	                                light_blue,
	                                vector3(0, 0, L * 1.7),
	                                quaternion()
	                                )

	table.insert(front_bottom.children,
		front_top
	)
	
	-- root
	local node = {
		robotTypeS = "drone",
		positionV3 = vector3(),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
			back,
			left_front,
			right_front,
		},
		lightShowLED = "red",
	}

	return node
end
