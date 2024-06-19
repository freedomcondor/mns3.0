Transform = require("Transform")
Logger = require("Logger")
Logger.enable()

function calcOrientationByPixel(tag)
	local X = (vector3(tag.corners[2].x - tag.corners[1].x ,
	                   tag.corners[2].y - tag.corners[1].y ,
	                   0) +
	           vector3(tag.corners[3].x - tag.corners[4].x ,
	                   tag.corners[3].y - tag.corners[4].y ,
	                   0)
              ):normalize()
	local Z = vector3(0,0,1)
	return Transform.fromTo2VecQuaternion(vector3(1,0,0), X, vector3(0,0,1), Z)
end

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

			tag.orientation_pixel = calcOrientationByPixel(tag)
			print("    orientation_pixel = X", vector3(1,0,0):rotate(tag.orientation_pixel))
			print("                        Y", vector3(0,1,0):rotate(tag.orientation_pixel))
			print("                        Z", vector3(0,0,1):rotate(tag.orientation_pixel))

			tag.positionV3 = camera.transform.position + vector3(tag.position):rotate(tag.orientation)
			tag.orientationQ = camera.transform.orientation * tag.orientation
			print("    robot_position = ", tag.positionV3)
			print("    robot_orientation = X", vector3(1,0,0):rotate(tag.orientationQ))
			print("                        Y", vector3(0,1,0):rotate(tag.orientationQ))
			print("                        Z", vector3(0,0,1):rotate(tag.orientationQ))

			Logger("logger")
			Logger(tag)
		end
	end
end

function destroy()
	for i, camera in ipairs(robot.cameras_system) do
			camera.disable()
	end
end