local L = 1.5

DeepCopy = require("DeepCopy")

function generate_chain_morphology(n)
	return generate_chain(n)
end

function generate_chain(n, positionV3, orientationQ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	local generate_knot = generate_triangle_knot
	local inc = 3
	local knot = generate_knot(n, positionV3, orientationQ)
	if n > inc then
		table.insert(
			knot.children,
			generate_chain(n - inc, vector3(-L,0,0), quaternion())
		)	
	end
	return knot
end

function generate_triangle_knot(n, positionV3, orientationQ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	local knot = nil
	if n >= 1 then
		knot = {	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			spine = true,
		}
	end
	if n >= 2 then
		knot.children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-L*0.5, -L*0.3, L*0.5*math.sqrt(3)),
				orientationQ = quaternion(),
			}
		}
	end
	if n >= 3 then
		table.insert(
			knot.children,
			{	robotTypeS = "drone",
				positionV3 = vector3(-L*0.5, L*0.3, L*0.5*math.sqrt(3)),
				orientationQ = quaternion(),
			}
		)
	end
	return knot
end