function init()
end
function reset()
end

local state = "front"
local stepCount = 0

function step()
	stepCount = stepCount + 1

	local left, right

	if state == "front" then
		speed = 0.01
		left = speed
		right = speed
		if stepCount == 5 * 10 then
			stepCount = 0
			state = "turn"
		end
	elseif state == "turn" then
		speed = 0.01
		left = speed
		right = -speed

		local D = 0.125
		local R = D * 0.5
		if stepCount > 5 * 0.5*R*math.pi/speed then
			stepCount = 0
			state = "front"
		end
	end

	robot.differential_drive.set_target_velocity(left, -right)
end

function destroy()
end