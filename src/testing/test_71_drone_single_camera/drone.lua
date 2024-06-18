Transform = require("Transform")

function init()
	for id, camera in pairs(robot.cameras_system) do
		camera.enable()
	end
end

function reset()
end

function step()
	for id, camera in pairs(robot.cameras_system) do
		print("camera", id, "-------------")
		for _, tag in ipairs(camera.tags) do
			print("tag", tag.id, "-------------")
			print("    position = ", tag.position)
			print("    orientation = X", vector3(1,0,0):rotate(tag.orientation))
			print("                  Y", vector3(0,1,0):rotate(tag.orientation))
			print("                  Z", vector3(0,0,1):rotate(tag.orientation))

			tag.positionV3 = camera.transform.position + vector3(tag.position):rotate(tag.orientation)
			tag.orientationQ = camera.transform.orientation * tag.orientation
			print("    robot_position = ", tag.positionV3)
			print("    robot_orientation = X", vector3(1,0,0):rotate(tag.orientationQ))
			print("                        Y", vector3(0,1,0):rotate(tag.orientationQ))
			print("                        Z", vector3(0,0,1):rotate(tag.orientationQ))
		end
	end
end

function destroy()
	for i, camera in ipairs(robot.cameras_system) do
			camera.disable()
	end
end