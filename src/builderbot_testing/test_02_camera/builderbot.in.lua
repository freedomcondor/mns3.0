function init()
	robot.camera_system.enable()
end
function reset()
end

function step()
	-- print all the tags
	print("---------------------------------------------")
	print("---------------------------------------------")
	print("tags number = ", #robot.camera_system.tags)
	local the_reference_tag = nil
	for i,tag in ipairs(robot.camera_system.tags) do
		print("  --------- tag ", i)
		for index, v in pairs(tag) do
			print(index, " ", v, type(v))
		end
		the_reference_tag = tag
	end

	-- consider the last one as reference tag
	if the_reference_tag == nil then return end

	local robot_to_ref = {
		positionV3 = vector3(0.20, 0, 0),
		orientationQ = quaternion(math.pi, vector3(1,0,0))
	}
	local camera_to_ref = {
		positionV3 = the_reference_tag.position,
		orientationQ = the_reference_tag.orientation
	}

	local inverse = camera_to_ref.orientationQ:inverse()
	local ref_to_camera = {
		positionV3 = vector3(-camera_to_ref.positionV3):rotate(inverse),
		orientationQ = inverse
	}

	print("ref_to_camera position = ", ref_to_camera.positionV3)
	print("ref_to_camera orientation = ", ref_to_camera.orientationQ)

	local robot_to_camera = {
		positionV3 = robot_to_ref.positionV3 + vector3(ref_to_camera.positionV3):rotate(robot_to_ref.orientationQ),
		orientationQ = robot_to_ref.orientationQ * ref_to_camera.orientationQ
	}

	print("camera position = ", robot_to_camera.positionV3)
	print("camera orientation = ", robot_to_camera.orientationQ)
end

function destroy()
end