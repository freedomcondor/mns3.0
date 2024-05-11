function init()
	robot.camera_system.enable()
end

function reset()
end

local robot_to_camera_calculated = {
	positionV3 = vector3(),
	orientationQ = quaternion(),
}

function step()
	print("---------------------------------------------")
	print("---------------------------------------------")

	-- print all the tags
	for i,v in pairs(robot.camera_system.transform) do
		print("  --------- camera.transform.", i, v)
	end

	print("tags number = ", #robot.camera_system.tags)
	local the_reference_tag = nil
	for i,tag in ipairs(robot.camera_system.tags) do
		print("  --------- tag ", i)
		print("   position = ", tag.position)
		print("orientation = ", tag.orientation)
		print("          X = ", vector3(1,0,0):rotate(tag.orientation))
		print("          Y = ", vector3(0,1,0):rotate(tag.orientation))
		print("          Z = ", vector3(0,0,1):rotate(tag.orientation))
		the_reference_tag = tag
	end

	-- consider the last one as reference tag
	if the_reference_tag == nil then return end

	local robot_to_ref_based_on_input = {
		positionV3 = robot.camera_system.transform.position + vector3(the_reference_tag.position):rotate(robot.camera_system.transform.orientation),
		orientationQ = robot.camera_system.transform.orientation * the_reference_tag.orientation
	}
	print("------------- ref")
	print("robot_to_ref based on calibration input: ")
	print("     position = ", robot_to_ref_based_on_input.positionV3)
	print("  orientation = ", robot_to_ref_based_on_input.orientationQ)
	print("            X = ", vector3(1,0,0):rotate(robot_to_ref_based_on_input.orientationQ))
	print("            Y = ", vector3(0,1,0):rotate(robot_to_ref_based_on_input.orientationQ))
	print("            Z = ", vector3(0,0,1):rotate(robot_to_ref_based_on_input.orientationQ))

	-- standard
	local robot_to_ref = {
		positionV3 = vector3(0.20, 0, 0.008),
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

	print("ref_to_camera    position = ", ref_to_camera.positionV3)
	print("ref_to_camera orientation = ", ref_to_camera.orientationQ)

	robot_to_camera_calculated.positionV3 = robot_to_ref.positionV3 + vector3(ref_to_camera.positionV3):rotate(robot_to_ref.orientationQ)
	robot_to_camera_calculated.orientationQ = robot_to_ref.orientationQ * ref_to_camera.orientationQ

	print("robot_to_camera")
	print("       position = ", robot_to_camera_calculated.positionV3)
	print("    orientation = ", robot_to_camera_calculated.orientationQ)
	print("              X = ", vector3(1,0,0):rotate(robot_to_camera_calculated.orientationQ))
	print("              Y = ", vector3(0,1,0):rotate(robot_to_camera_calculated.orientationQ))
	print("              Z = ", vector3(0,0,1):rotate(robot_to_camera_calculated.orientationQ))
end

function destroy()
	robot.camera_system.disable()

	local str = "<?xml version=\"1.0\" ?>\n<calibration>\n"
	str = str .. "  <extrinsic\n"
	str = str .. "       position=\"" .. tostring(robot_to_camera_calculated.positionV3) .. "\"\n"
	str = str .. "       orientation=\"" .. tostring(robot_to_camera_calculated.orientationQ) .. "\"\n"
	str = str .. "  />\n"
	str = str .. "</calibration>"
	local file = io.open("lua_calibration.xml",'w')
	file:write(str)
	file:close()
	print("lua_calibration.xml file saved!")
end