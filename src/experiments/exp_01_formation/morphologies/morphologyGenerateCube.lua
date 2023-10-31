local L = 5

DeepCopy = require("DeepCopy")

local baseValueFunction_target = function(base, current, target)
	return (current - target):length()
end

local baseValueFunction_0 = function(base, current, target)
	return 0
end
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
		elliptic_distance2 = (1/16) * x2 + y2
		return elliptic_distance2
	end
end

function generate_cube_morphology(n) -- n is number of drones
	side_n = math.ceil(n ^ (1/3))
	return generate_cube(side_n, vector3(), quaternion())
end

function generate_cube(n, positionV3, orientationQ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	return generate_square(n, n, n, true, positionV3, orientationQ)
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

function generate_square(m, n, totalN, drawlineYFlag, positionV3, orientationQ)
	-- n x n square
	-- m squares left including myself
	-- square grows X and Z
	-- next square goes to Y
	local node
	if n == 1 then
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
		if drawlineYFlag == true then
			node.drawLines = {vector3(0, L, 0)}
		end
	else
		local X_drawLines = {vector3(L, 0, 0)}
		local Z_drawLines = {vector3(0, 0, L)}
		local Y_drawLines = {vector3(L, 0, 0),
		                     vector3(0, 0, L)
		                    }
		if drawlineYFlag == true then
			table.insert(X_drawLines, vector3(0, L, 0))
			table.insert(Z_drawLines, vector3(0, L, 0))
			table.insert(Y_drawLines, vector3(0, L, 0))
		end
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = Y_drawLines,
			children = {
				generate_cube_line(n - 1, vector3(L, 0, 0), quaternion(), Z_drawLines),
				generate_cube_line(n - 1, vector3(0, 0, L), quaternion(), X_drawLines),
				generate_square(1, n - 1, totalN, drawlineYFlag, vector3(L, 0, L), quaternion()),
			}
		}
	end
	if m ~= 1 then
		if m - 1 == 1 then
			drawlineYFlag = false
		end
		local child = generate_square(m - 1, n, totalN, drawlineYFlag, vector3(0, L, 0), quaternion())
		if node.children == nil then
			node.children = {}
		end
		table.insert(node.children, child)
	end
	if totalN == n then
		node.calcBaseValue = baseValueFunction_target
	end
	return node
end