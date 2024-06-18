Transform = require("Transform")

local accumulators
function init()
	for id, camera in pairs(robot.cameras_system) do
		camera.enable()
	end

	accumulators = {
		arm1 = Transform.createAccumulator(),
		arm2 = Transform.createAccumulator(),
		arm3 = Transform.createAccumulator(),
	}
end

function reset()
end

function step()
	-- calibrate with reference of tag 1
	-- find camera arm0
	local camera_arm0 = robot.cameras_system["arm0"]
	-- find tag1
	local tag1_arm0 = nil
	for _, newTag in ipairs(camera_arm0.tags) do
		if newTag.id == 1 then
			local robot_to_tag_orientation = camera_arm0.transform.orientation * newTag.orientation
			if (vector3(0,0,1):rotate(robot_to_tag_orientation) - vector3(0,0,-1)):length() < 0.3 then
				tag1_arm0 = newTag
				break
			end
		end
	end

	if tag1_arm0 == nil then
		return
	end

	local arm0_to_tag1 = {
		positionV3 = tag1_arm0.position,
		orientationQ = tag1_arm0.orientation,
	}

	local robot_to_tag1 = {
		positionV3 = camera_arm0.transform.position +
		             vector3(tag1_arm0.position):rotate(camera_arm0.transform.orientation),
		orientationQ = camera_arm0.transform.orientation * tag1_arm0.orientation,
	}

	for id, camera in pairs(robot.cameras_system) do
		if id ~= "arm0" then
			-- find tag1
			local tag1_focal_arm = nil
			for _, newTag in ipairs(camera.tags) do
				if newTag.id == 1 then
					local robot_to_tag_orientation = camera.transform.orientation * newTag.orientation
					if (vector3(0,0,1):rotate(robot_to_tag_orientation) - vector3(0,0,-1)):length() < 0.3 then
						tag1_focal_arm = newTag
						break
					end
				end
			end

			if tag1_focal_arm ~= nil then
				local focal_arm_to_tag1 = {
					positionV3 = tag1_focal_arm.position,
					orientationQ = tag1_focal_arm.orientation,
				}

				local robot_to_focal_arm = Transform.CxBisA(robot_to_tag1, focal_arm_to_tag1, c)

				Transform.addAccumulator(accumulators[id], robot_to_focal_arm)
				robot_to_focal_arm = Transform.averageAccumulator(accumulators[id])

				camera.transform.position = robot_to_focal_arm.positionV3
				camera.transform.orientation = robot_to_focal_arm.orientationQ
			end
		end
	end
	print("calibrated!")
	for id, camera in pairs(robot.cameras_system) do
		print("       position=\"" .. tostring(camera.transform.position) .. "\"\n")
		print("       orientation=\"" .. tostring(camera.transform.orientation) .. "\"\n")
	end

	print("-------------------------------------------")
	for id, camera in pairs(robot.cameras_system) do
		print("camera", id, "-------------")
		for _, newTag in ipairs(camera.tags) do if newTag.id ~= 34 then
			print("tag", newTag.id)
			newTag.positionV3 =
				camera.transform.position +
				vector3(newTag.position):rotate(camera.transform.orientation)

			newTag.orientationQ =
				camera.transform.orientation *
				newTag.orientation * quaternion(math.pi, vector3(1,0,0))

			print("position = ", newTag.positionV3)
			print("orientation = X", vector3(1,0,0):rotate(newTag.orientationQ))
			print("              Y", vector3(0,1,0):rotate(newTag.orientationQ))
			print("              Z", vector3(0,0,1):rotate(newTag.orientationQ))

			-- find the nearest 34 tag
			local dis = math.huge
			local tag34 = nil
			for _, nearTag in ipairs(camera.tags) do
				local currentDis = (nearTag.position - newTag.position):length()
				if nearTag.id == 34 and currentDis < dis then
					dis = currentDis
					tag34 = nearTag
				end
			end
			if tag34 ~= nil then
				tag34.positionV3 = camera.transform.position +
				                   vector3(tag34.position):rotate(camera.transform.orientation)
				tag34.orientationQ = camera.transform.orientation * tag34.orientation * newTag.orientation * quaternion(math.pi, vector3(1,0,0))
				local tag_to_tag34 = Transform.AxCisB(newTag, tag34)
				print("near_position = ", tag_to_tag34.positionV3)
				print("near_orientation = X", vector3(1,0,0):rotate(tag_to_tag34.orientationQ))
				print("                   Y", vector3(0,1,0):rotate(tag_to_tag34.orientationQ))
				print("                   Z", vector3(0,0,1):rotate(tag_to_tag34.orientationQ))
			end
		end end
	end
end

function destroy()
	for i, camera in ipairs(robot.cameras_system) do
			camera.disable()
	end

	local str = "<?xml version=\"1.0\" ?>\n<calibration>\n"
	for id, camera in pairs(robot.cameras_system) do
			str = str .. "  <arm id=\"" .. id .. "\"\n"
			str = str .. "       position=\"" .. tostring(camera.transform.position) .. "\"\n"
			str = str .. "       orientation=\"" .. tostring(camera.transform.orientation) .. "\"\n"
			str = str .. "  />\n"
	end
	str = str .. "</calibration>"
	local file = io.open("lua_calibration.xml",'w')
	file:write(str)
	file:close()
	print("lua_calibration.xml file saved!")
end