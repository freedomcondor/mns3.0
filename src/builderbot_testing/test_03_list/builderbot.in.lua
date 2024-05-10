local state = "calibrating"
local stepCount = 0
function init()
	robot.lift_system.calibrate();
end
 
function step()
	stepCount = stepCount + 1
	if stepCount == 1 then return end

	print("----------------------------------------------------")
	print("state = ", state)
	print("lift_system.state: " .. robot.lift_system.state)
	print("lift_system.limit_switches: " .. robot.lift_system.limit_switches.top .. " " .. robot.lift_system.limit_switches.bottom)
	print("lift_system.position: " .. robot.lift_system.position)
	if robot.lift_system.state == "inactive" and state == "calibrating" then
		robot.lift_system.set_position(0.07)
		state = "go to middle (0.07)"
	elseif robot.lift_system.state == "inactive" and state == "go to middle (0.07)" then
		robot.lift_system.set_position(0.00)
		state = "go to bottom(0.00)"
	end
end
 
function reset()
end
 
function destroy()
end