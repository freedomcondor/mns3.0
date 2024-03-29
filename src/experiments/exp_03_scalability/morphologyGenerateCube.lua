local L = 5

DeepCopy = require("DeepCopy")

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

function generate_cube_morphology(n, split_n)
	if n <= 8 then
		return require("morphology_8")
	end
	side_n = math.ceil(n ^ (1/3))

	local side_n_split = nil
	if split_n ~= nil then
		side_n_split = math.ceil(split_n ^ (1/3))
	end

	return generate_cube(side_n, vector3(), quaternion(), side_n_split)
end

function generate_cube(n, positionV3, orientationQ, split_n)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end
	local split = nil
	if split_n == n then
		split = true
	end

	if n == 1 then
		return
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			split = split,
		}
	else
		return
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = {
				vector3(L, 0, 0),
				vector3(0, L, 0),
				vector3(0, 0, L)
			},
			split = split,
			children = {
			generate_rectangular(n - 1, vector3(L, 0, 0), quaternion(), L, L, false, false),
			generate_rectangular(n - 1, vector3(0, L, 0), quaternion(math.pi/2, vector3(0, 0, 1)) * quaternion(math.pi/2, vector3(1, 0, 0)), L, L),
			generate_rectangular(n - 1, vector3(0, 0, L), quaternion(-math.pi/2, vector3(0, 1, 0)) * quaternion(-math.pi/2, vector3(1, 0, 0)), L, L),
			generate_cube(n - 1, vector3(L, L, L), quaternion(), split_n),
		}}
	end
end

function generate_rectangular(n, positionV3, orientationQ, X_offset, Y_offset, with_sub_cube, split_n)
	local sub_cube = nil
	if with_sub_cube == true then
		sub_cube = generate_cube(n, vector3(0, L, L), quaternion(), split_n)
	end
	if n == 1 then
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = {
				vector3(0, L, 0),
				vector3(0, 0, L)
			},
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(0, Y_offset, 0),
				orientationQ = quaternion(),
				drawLines = {
					vector3(0, 0, L),
				}
			},
			sub_cube
		}}
	else
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = {
				vector3(L, 0, 0),
				vector3(0, L, 0),
				vector3(0, 0, L)
			},
			calcBaseValue = baseValueFunction,
			children = {
				generate_cube_line(n - 1, vector3(X_offset, 0, 0), quaternion(), {vector3(0,L,0), vector3(0,0,L)}),
				generate_square(n, vector3(0, Y_offset, 0), quaternion(), X_offset, Y_offset),
				sub_cube
			}
		}
	end
end

function generate_cube_line(n, positionV3, orientationQ, drawLines)
	if n == 1 then
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = drawLines,
		}
	else
		local drawLines_full = DeepCopy(drawLines)
		table.insert(drawLines_full, positionV3)
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = drawLines_full,
			children = {
				generate_cube_line(n - 1, positionV3, orientationQ, drawLines)
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
			drawLines = {
				vector3(0, 0, L),
			}
		}
	else
		return 
		{	robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = {
				vector3(L, 0, 0),
				vector3(0, L, 0),
				vector3(0, 0, L)
			},
			children = {
				generate_cube_line(n - 1, vector3(X_offset, 0, 0), quaternion(), {vector3(0,L,0), vector3(0,0,L)}),
				generate_cube_line(n - 1, vector3(0, Y_offset, 0), quaternion(), {vector3(L,0,0), vector3(0,0,L)}),
				generate_square(n - 1, vector3(X_offset, Y_offset, 0), quaternion(), X_offset, Y_offset),
			}
		}
	end
end