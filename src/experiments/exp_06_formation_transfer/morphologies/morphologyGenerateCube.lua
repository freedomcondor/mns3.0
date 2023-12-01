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
	local side_n = math.ceil(n ^ (1/3))
	return generate_cube(side_n, vector3(), quaternion(), vector3(L,0,0), vector3(0,L,0), vector3(0,0,L))
end

function generate_sliced_cube_morphology(n) -- n is number of drones
	local side_n = math.ceil(n ^ (1/3))
	local half_side_n = math.ceil((side_n+1) * 0.5)
	return generate_sliced_cube(half_side_n, side_n, vector3(), quaternion(), vector3(L,0,0), vector3(0,L,0), vector3(0,0,L))
end

function generate_radical_cube_morphology(n) -- n is number of drones
	--local half_side_n = math.ceil( ((n ^ (1/3)) + 1)/2 )
	local half_side_n = math.ceil((n-1) ^ (1/3)) / 2

	return generate_radical_cube(half_side_n, vector3(), quaternion(), vector3(L,0,0), vector3(0,L,0), vector3(0,0,L))
end

------------------------------------------------------------------------------
-- Radical cube that starts from center, but the brains has 26 children
function generate_radical_cube(n, positionV3, orientationQ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	-- 8 x n^3 + 1 drones
	-- (2n) x (2n) x (2n) cube + brain
	local X = vector3(L, 0, 0)
	local Y = vector3(0, L, 0)
	local Z = vector3(0, 0, L)

	local node
	--[[
	if n == 1 then
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	else
	--]]
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_cube     (n, ( X+Y+Z)*0.5, quaternion(),  X,  Y,  Z),
				generate_cube     (n, ( X+Y-Z)*0.5, quaternion(),  X,  Y, -Z),
				generate_cube     (n, ( X-Y+Z)*0.5, quaternion(),  X, -Y,  Z),
				generate_cube     (n, ( X-Y-Z)*0.5, quaternion(),  X, -Y, -Z),
				generate_cube     (n, (-X+Y+Z)*0.5, quaternion(), -X,  Y,  Z),
				generate_cube     (n, (-X+Y-Z)*0.5, quaternion(), -X,  Y, -Z),
				generate_cube     (n, (-X-Y+Z)*0.5, quaternion(), -X, -Y,  Z),
				generate_cube     (n, (-X-Y-Z)*0.5, quaternion(), -X, -Y, -Z),
			}
		}
	--end
	return node
end

------------------------------------------------------------------------------
-- Normal cube that starts from a corner
function generate_cube(n, positionV3, orientationQ, offsetX, offsetY, offsetZ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	-- n x n x n cube
	local node
	if n == 1 then
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	else
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_cube_line(n - 1, offsetX, quaternion(), {offsetY, offsetZ}),
				generate_cube_line(n - 1, offsetY, quaternion(), {offsetX, offsetZ}),
				generate_cube_line(n - 1, offsetZ, quaternion(), {offsetX, offsetY}),
				generate_square   (n - 1, offsetX + offsetY, quaternion(), offsetX, offsetY, {offsetZ}),
				generate_square   (n - 1, offsetX + offsetZ, quaternion(), offsetX, offsetZ, {offsetY}),
				generate_square   (n - 1, offsetY + offsetZ, quaternion(), offsetY, offsetZ, {offsetX}),
				generate_cube     (n - 1, offsetX + offsetY + offsetZ, quaternion(), offsetX, offsetY, offsetZ),
			}
		}
	end
	return node
end

------------------------------------------------------------------------------
-- Sliced cube that starts from a bottom center
function generate_sliced_cube(n, m, positionV3, orientationQ, offsetX, offsetY, offsetZ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	-- n x n x n cube
	local node
	if n == 1 then
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
		}
	else
		local drawLines_offsetZ = offsetZ
		if m == 1 then
			drawLines_offsetZ = nil
		end
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_cube_line(n - 1,  offsetX, quaternion(), {offsetY, -offsetY, drawLines_offsetZ}),
				generate_cube_line(n - 1, -offsetX, quaternion(), {offsetY, -offsetY, drawLines_offsetZ}),
				generate_cube_line(n - 1,  offsetY, quaternion(), {offsetX, -offsetX, drawLines_offsetZ}),
				generate_cube_line(n - 1, -offsetY, quaternion(), {offsetX, -offsetX, drawLines_offsetZ}),

				generate_square   (n - 1,  offsetX + offsetY, quaternion(),  offsetX,  offsetY, {drawLines_offsetZ}),
				generate_square   (n - 1,  offsetX - offsetY, quaternion(),  offsetX, -offsetY, {drawLines_offsetZ}),
				generate_square   (n - 1, -offsetX + offsetY, quaternion(), -offsetX,  offsetY, {drawLines_offsetZ}),
				generate_square   (n - 1, -offsetX - offsetY, quaternion(), -offsetX, -offsetY, {drawLines_offsetZ}),
			}
		}
	end

	if m ~= 1 then
		if node.children == nil then node.children = {} end
		table.insert(node.children, generate_sliced_cube(n, m-1, offsetZ, quaternion(), offsetX, offsetY, offsetZ))
	end

	return node
end

------------------------------------------------------------------------------
-- Line and Square tools
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

function generate_square(n, positionV3, orientationQ, offsetX, offsetY, drawLines)
	-- n x n square
	local node
	if n == 1 then
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			drawLines = drawLines,
		}
	else
		local drawLines_X = DeepCopy(drawLines)
		table.insert(drawLines_X, offsetY)
		local drawLines_Y = DeepCopy(drawLines)
		table.insert(drawLines_Y, offsetX)
		node = {
			robotTypeS = "drone",
			positionV3 = positionV3,
			orientationQ = orientationQ,
			children = {
				generate_cube_line(n - 1, offsetX, quaternion(), drawLines_X),
				generate_cube_line(n - 1, offsetY, quaternion(), drawLines_Y),
				generate_square   (n - 1, offsetX + offsetY, quaternion(), offsetX, offsetY, drawLines),
			}
		}
	end
	return node
end