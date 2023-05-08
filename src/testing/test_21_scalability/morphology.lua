local L = 1.5

function generate_morphology(n)
	side_n = math.ceil(n ^ (1/3))
	return generate_cube(side_n)
end

function generate_cube(n, positionV3, orientationQ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	if n == 1 then
		return
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	else
		return
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
			generate_rectangular(n - 1, vector3(L, 0, 0), quaternion(), L, L),
			generate_rectangular(n - 1, vector3(0, L, 0), quaternion(math.pi/2, vector3(0, 0, 1)) * quaternion(math.pi/2, vector3(1, 0, 0)), L, L),
			generate_rectangular(n - 1, vector3(0, 0, L), quaternion(-math.pi/2, vector3(0, 1, 0)) * quaternion(-math.pi/2, vector3(1, 0, 0)), L, L),
			generate_cube(n - 1, vector3(L, L, L), quaternion()),
		}}
	end
end

function generate_rectangular(n, positionV3, orientationQ, X_offset, Y_offset)
	if n == 1 then
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, Y_offset, 0),
				orientationQ = quaternion(),
			}
		}}
	else
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_line(n - 1, vector3(X_offset, 0, 0), quaternion()),
				generate_square(n, vector3(0, Y_offset, 0), quaternion(), X_offset, Y_offset)
			}
		}
	end
end

function generate_line(n, positionV3, orientationQ)
	if n == 1 then
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	else
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_line(n - 1, positionV3, orientationQ)
			}
		}
	end
end

function generate_square(n, positionV3, orientationQ, X_offset, Y_offset)
	if n == 1 then
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	else
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_line(n - 1, vector3(X_offset, 0, 0), quaternion()),
				generate_line(n - 1, vector3(0, Y_offset, 0), quaternion()),
				generate_square(n - 1, vector3(X_offset, Y_offset, 0), quaternion(), X_offset, Y_offset),
			}
		}
	end
end