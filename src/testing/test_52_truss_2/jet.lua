require("trussGenerator")

local baseValueFunction = function(base, current, target)
	return 0
end

function create_jet(positionV3, orientationQ)
	local positionV3 = positionV3 or vector3()
	local orientationQ = orientationQ or quaternion()
	local L = 1.5
	local thick = L * 1.7

	local left_body  = create_beam(3, L, L * 2,
	                               vector3(0, L * 0.75, thick * 0),
	                               quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )
	local right_body = create_beam(3, L, L * 2,
	                               vector3(0, -L * 0.75, thick * 0),
	                               quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )

	local middle_body = create_beam(3, L, L * 2,
	                                vector3(0, 0, thick * 0.35),
	                                quaternion(math.pi, vector3(1, 0, 0)) * quaternion(math.pi, vector3(0, 0, 1))
	                               )

	local head = create_beam(1, L, thick, vector3(0, 0, -thick * 0.35), quaternion())


	local left_wing  = create_beam(4, L, thick,
	                               vector3(-L*0.5,  L*0.5, -thick),
	                               quaternion(-math.pi/3, vector3(0,0,1)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )
	local right_wing = create_beam(4, L, thick,
	                               vector3(-L*0.5, -L*0.5, -thick),
	                               quaternion( math.pi/3, vector3(0,0,1)) * quaternion(math.pi, vector3(0, 0, 1))
	                              )
	local wings = {
		robotTypeS = "drone",
		positionV3 = vector3(-L*0.5, 0, -thick * 0),
		orientationQ = quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
			left_wing,
			right_wing,
	}}

	local node = {
		robotTypeS = "drone",
		positionV3 = positionV3 or vector3(),
		orientationQ = orientationQ or quaternion(),
		calcBaseValue = baseValueFunction,
		children = {
			head,
			middle_body,
			wings,
		}
	}

	return node
end
