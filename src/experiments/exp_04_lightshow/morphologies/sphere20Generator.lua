local L = 3

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
	return 0
end

local phi = (1+math.sqrt(5)) * 0.5
local rev_phi = 1/phi
local L_rate = L / (rev_phi * 2)

local pl1 = vector3( 1, -1, -1) * L_rate
local pl2 = vector3( 1,  1, -1) * L_rate
local pl3 = vector3(-1, -1, -1) * L_rate
local pl4 = vector3(-1,  1, -1) * L_rate

local ph1 = vector3( 1, -1,  1) * L_rate
local ph2 = vector3( 1,  1,  1) * L_rate
local ph3 = vector3(-1, -1,  1) * L_rate
local ph4 = vector3(-1,  1,  1) * L_rate

local px1 = vector3(0, -phi, -rev_phi) * L_rate
local px2 = vector3(0, -phi,  rev_phi) * L_rate
local px3 = vector3(0,  phi, -rev_phi) * L_rate
local px4 = vector3(0,  phi,  rev_phi) * L_rate

local py1 = vector3( rev_phi, 0, -phi) * L_rate
local py2 = vector3( rev_phi, 0,  phi) * L_rate
local py3 = vector3(-rev_phi, 0, -phi) * L_rate
local py4 = vector3(-rev_phi, 0,  phi) * L_rate

local pz1 = vector3( phi, -rev_phi, 0) * L_rate
local pz2 = vector3( phi,  rev_phi, 0) * L_rate
local pz3 = vector3(-phi, -rev_phi, 0) * L_rate
local pz4 = vector3(-phi,  rev_phi, 0) * L_rate

local extra1 = vector3(0, 0, -0.5) * L_rate
local extra2 = vector3( 0.5, 0.5, 0.5) * L_rate
local extra3 = vector3( 0.5,-0.5, 0.5) * L_rate
local extra4 = vector3(-0.5, 0.5, 0.5) * L_rate
local extra5 = vector3(-0.5,-0.5, 0.5) * L_rate

function drawLines_tmp(myself, points)
	local relative_points = {}
	for i, point in ipairs(points) do
		table.insert(relative_points, (point - myself))
	end
	return relative_points
end

function create_sphere20(color, failure)
return 
{	robotTypeS = "drone",
	-- py3
	positionV3 = vector3(),
	orientationQ = quaternion(),
	drawLines_tmp = drawLines_tmp(py3, {py1, pl3, pl4}),
	label = "morphology20",
	children = {
	-- extra 5
	{	robotTypeS = "drone",
		positionV3 = extra1 - py3,
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = extra2 - extra1,
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = extra3 - extra1,
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = extra4 - extra1,
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = extra5 - extra1,
			orientationQ = quaternion(),
		},
	}},
	{	robotTypeS = "drone",
		-- py1
		positionV3 = py1 - py3,
		orientationQ = quaternion(),
		drawLines_tmp = drawLines_tmp(py1, {pl1, pl2}),
		children = {
		{	robotTypeS = "drone",
			-- pl1
			positionV3 = pl1 - py1,
			orientationQ = quaternion(),
			drawLines_tmp = drawLines_tmp(pl1, {px1, pz1}),
			children = {
			{	robotTypeS = "drone",
				-- pz1
				positionV3 = pz1 - pl1,
				orientationQ = quaternion(),
				drawLines_tmp = drawLines_tmp(pz1, {ph1, pz2}),
			}
		}},
		{	robotTypeS = "drone",
			-- pl2
			positionV3 = pl2 - py1,
			orientationQ = quaternion(),
			drawLines_tmp = drawLines_tmp(pl2, {px3, pz2}),
			children = {
			{	robotTypeS = "drone",
				-- pz2
				positionV3 = pz2 - pl2,
				orientationQ = quaternion(),
				drawLines_tmp = drawLines_tmp(pz2, {ph2}),
				children = {
				{	robotTypeS = "drone",
					-- ph2
					positionV3 = ph2 - pz2,
					orientationQ = quaternion(),
					drawLines_tmp = drawLines_tmp(ph2, {py2}),
					children = {
					{	robotTypeS = "drone",
						-- py2
						positionV3 = py2 - ph2,
						orientationQ = quaternion(),
					},
				}},
			}},
		}},
	}},
	{	robotTypeS = "drone",
		-- pl3
		positionV3 = pl3 - py3,
		orientationQ = quaternion(),
		drawLines_tmp = drawLines_tmp(pl3, {px1, pz3}),
		children = {
		{	robotTypeS = "drone",
			-- px1
			positionV3 = px1 - pl3,
			orientationQ = quaternion(),
			drawLines_tmp = drawLines_tmp(px1, {px2}),
			children = {
			{	robotTypeS = "drone",
				-- px2
				positionV3 = px2 - px1,
				orientationQ = quaternion(),
				drawLines_tmp = drawLines_tmp(px2, {ph1}),
				children = {
				{	robotTypeS = "drone",
					-- ph1
					positionV3 = ph1 - px2,
					orientationQ = quaternion(),
					drawLines_tmp = drawLines_tmp(ph1, {py2}),
				},
			}},
		}},
		{	robotTypeS = "drone",
			-- pz3
			positionV3 = pz3 - pl3,
			orientationQ = quaternion(),
			drawLines_tmp = drawLines_tmp(pz3, {ph3, pz4}),
			children = {
			{	robotTypeS = "drone",
				-- ph3
				positionV3 = ph3 - pz3,
				drawLines_tmp = drawLines_tmp(ph3, {px2, py4}),
				orientationQ = quaternion(),
			}
		}},
	}},
	{	robotTypeS = "drone",
		-- pl4
		positionV3 = pl4 - py3,
		orientationQ = quaternion(),
		drawLines_tmp = drawLines_tmp(pl4, {pz4, px3}),
		children = {
		{	robotTypeS = "drone",
			-- px3
			positionV3 = px3 - pl4,
			orientationQ = quaternion(),
			drawLines_tmp = drawLines_tmp(px3, {px4}),
			children = {
			{	robotTypeS = "drone",
				-- px4
				positionV3 = px4 - px3,
				orientationQ = quaternion(),
				drawLines_tmp = drawLines_tmp(px4, {ph2, ph4}),
			}
		}},
		{	robotTypeS = "drone",
			-- pz4
			positionV3 = pz4 - pl4,
			orientationQ = quaternion(),
			drawLines_tmp = drawLines_tmp(pz4, {ph4}),
			children = {
			{	robotTypeS = "drone",
				-- ph4
				positionV3 = ph4 - pz4,
				orientationQ = quaternion(),
				drawLines_tmp = drawLines_tmp(ph4, {py4}),
				children = {
				{	robotTypeS = "drone",
					-- py4
					positionV3 = py4 - ph4,
					orientationQ = quaternion(),
					drawLines_tmp = drawLines_tmp(py4, {py2}),
				},
			}},
		}},
	}},
}}
end
