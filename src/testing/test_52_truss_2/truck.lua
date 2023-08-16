require("trussGenerator")

local baseValueFunction = function(base, current, target)
	return 0
end

function create_wheel(positionV3, orientationQ, d, n)
	local function create_wheel_chain(n, offsetPosition, offsetOrientation, startPosition, startOrientation)
		local node = {
			robotTypeS = "drone",
			positionV3 = startPosition or offsetPosition,
			orientationQ = startOrientation or offsetOrientation,
			calcBaseValue = baseValueFunction,
			drawLines = {offsetPosition, vector3(0, d, 0)},
		}

		if n ~= 1 then
			node.calcBaseValue = baseValueFunction
			node.children = {
				create_wheel_chain(n-1, offsetPosition, offsetOrientation)
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
		children = {
			create_wheel_chain(n,
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

function create_truck(positionV3, orientationQ)
	local positionV3 = positionV3 or vector3()
	local orientationQ = orientationQ or quaternion()
	local L = 1.5
	local thick = L * 2

	-- left back body
	local left_body, tail = create_beam(3, L, thick,
	                               vector3(0, L * 0.75, thick),
	                               quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )

	local left_tail, tail_tail = create_beam(1, L, thick,
	                               vector3(0, 0, thick),
	                               quaternion(math.pi, vector3(1, 0, 0))
	                              )

	tail.children = {
		create_wheel(vector3(0, 1.2, thick*0.75), quaternion(math.pi/2, vector3(0,0,1)), L, 6),
		left_tail
	}

	-- right back body
	local right_body, tail = create_beam(3, L, thick,
	                               vector3(0, -L * 0.75, thick),
	                               quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )

	local right_tail, tail_tail = create_beam(1, L, thick,
	                               vector3(0, 0, thick),
	                               quaternion(math.pi, vector3(1, 0, 0))
	                              )
	
	tail.children = {
		create_wheel(vector3(0, -1.2, thick*0.75), quaternion(-math.pi/2, vector3(0,0,1)), L, 6),
		right_tail
	}
	
	-- root
	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3 or vector3(),
		orientationQ = orientationQ or quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
			left_body,
			right_body,
		}
	}

	return node
end
