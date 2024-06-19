-- Avoider -----------------------------------------
------------------------------------------------------
local Avoider = {}

function Avoider.create(vns)
	vns.avoider = {
		obstacles = {}
	}
end

function Avoider.reset(vns)
	vns.avoider.obstacles = {}
	vns.avoider.aerial_obstacles = {}
	vns.avoider.blocks = {}
	vns.avoider.memoryBlocksInRealFrame = {}
end

function Avoider.preStep(vns)
end

function Avoider.step(vns, drone_pipuck_avoidance)
	local avoid_speed = {positionV3 = vector3(), orientationV3 = vector3()}

	local backup_avoid_speed_scalar = vns.Parameters.avoid_speed_scalar

	-- avoid seen robots
	-- the brain is not influenced by other robots
	if (vns.parentR ~= nil or vns.Parameters.avoider_brain_exception == false) and
	   vns.stabilizer.referencing_me ~= true then
		for idS, robotR in pairs(vns.connector.seenRobots) do
			-- avoid drone
			if vns.robotTypeS == "drone" and
			   robotR.robotTypeS == "drone" then
				if robot.params.hardware == true then
					vns.Parameters.avoid_speed_scalar = vns.Parameters.avoid_speed_scalar * 15
				end
				-- check vortex
				local drone_vortex = vns.Parameters.avoid_drone_vortex
				if drone_vortex == "goal" then
					drone_vortex = vns.goal.positionV3
				elseif drone_vortex == "true" then
					drone_vortex = true
				elseif drone_vortex == "nil" then
					drone_vortex = nil
				end
				-- add avoid speed
				avoid_speed.positionV3 =
					Avoider.add(vector3(), robotR.positionV3,
					            avoid_speed.positionV3,
					            vns.Parameters.dangerzone_drone,
					            drone_vortex,
					            vns.Parameters.deadzone_drone)
				if robot.params.hardware == true then
					vns.Parameters.avoid_speed_scalar = backup_avoid_speed_scalar
				end
			end
			-- avoid pipuck
			if (robotR.robotTypeS == "builderbot" or robotR.robotTypeS == "pipuck") and
			   (vns.robotTypeS == "builderbot" or vns.robotTypeS == "pipuck") then
				local dangerzone = vns.Parameters.dangerzone_pipuck
				local deadzone = vns.Parameters.deadzone_pipuck
				-- avoid referenced pipuck 10 times harder
				if idS == vns.stabilizer.referencing_pipuck_neighbour then
					vns.Parameters.avoid_speed_scalar = vns.Parameters.avoid_speed_scalar * 15
					dangerzone = dangerzone * vns.Parameters.dangerzone_reference_pipuck_scalar
					deadzone = deadzone * vns.Parameters.deadzone_reference_pipuck_scalar
				end
				-- check vortex
				local pipuck_vortex = vns.Parameters.avoid_pipuck_vortex
				if pipuck_vortex == "goal" then
					pipuck_vortex = vns.goal.positionV3
				elseif pipuck_vortex == "true" then
					pipuck_vortex = true
				elseif pipuck_vortex == "nil" then
					pipuck_vortex = nil
				end
				-- add avoid speed
				avoid_speed.positionV3 =
					Avoider.add(vector3(), robotR.positionV3,
					            avoid_speed.positionV3,
					            dangerzone,
					            pipuck_vortex,
					            deadzone
					           )
				-- resume
				vns.Parameters.avoid_speed_scalar = backup_avoid_speed_scalar
			end
			-- avoidance between drone and pipuck
			if drone_pipuck_avoidance == true and
			   robotR.robotTypeS ~= vns.robotTypeS and
			   (robotR.robotTypeS == "drone" or vns.robotTypeS == "drone") then
				local dangerzone = vns.Parameters.dangerzone_pipuck
				local deadzone = vns.Parameters.deadzone_pipuck
				-- check vortex
				local drone_vortex = vns.Parameters.avoid_pipuck_vortex
				if drone_vortex == "goal" then
					drone_vortex = vns.goal.positionV3
				elseif drone_vortex == "true" then
					drone_vortex = true
				elseif drone_vortex == "nil" then
					drone_vortex = nil
				end
				-- add avoid speed
				avoid_speed.positionV3 =
					Avoider.add(vector3(), robotR.positionV3,
					            avoid_speed.positionV3,
					            dangerzone,
					            drone_vortex,
					            deadzone
					           )
			end
		end
	end

	-- avoid obstacles
	if vns.robotTypeS == "drone" then
		if vns.api.actuator.flight_preparation.state == "navigation" and
		   vns.parentR ~= nil then
			-- avoid aerial obstacles
			for i, obstacle in ipairs(vns.avoider.aerial_obstacles) do
				avoid_speed.positionV3 =
					Avoider.add(vector3(), obstacle.positionV3,
					            avoid_speed.positionV3,
					            vns.Parameters.dangerzone_aerial_obstacle,
					            nil,
					            vns.Parameters.deadzone_aerial_obstacle
					)
			end
		end
	else
		-- avoid ground blocks
		for i, block in ipairs(vns.avoider.blocks) do if block.added ~= true then
			-- check vortex
			local block_vortex = vns.Parameters.avoid_block_vortex
			if block_vortex == "goal" then
				block_vortex = vns.goal.positionV3
			elseif block_vortex == "true" then
				block_vortex = true
			elseif block_vortex == "nil" then
				block_vortex = nil
			end
			avoid_speed.positionV3 =
				Avoider.add(vector3(), block.positionV3,
				            avoid_speed.positionV3,
				            vns.Parameters.dangerzone_block,
				            block_vortex,
				            vns.Parameters.deadzone_block
				)
				            --virtual_danger_zone)
				            --vns.goal.positionV3)
		end end -- end of obstacle.added ~= true and for
	end

	-- TODO: maybe add surpress or not
	-- add the speed to goal -- the brain can't be influended
	vns.goal.transV3 = vns.goal.transV3 + avoid_speed.positionV3
	vns.goal.rotateV3 = vns.goal.rotateV3 + avoid_speed.orientationV3


	---[[
	--if robot.id == "pipuck6" then
		local color = "255,0,0,0"
		vns.api.debug.drawArrow(color,
		                        vns.api.virtualFrame.V3_VtoR(vector3(0,0,0.1)),
		                        vns.api.virtualFrame.V3_VtoR(vns.goal.transV3 * 1 + vector3(0,0,0.1))
		                       )
	--end
	--]]
end

function Avoider.add(myLocV3, obLocV3, accumulatorV3, threshold, vortex, deadzone)
	-- calculate the avoid speed from obLoc to myLoc,
	-- add the result into accumulator
	--[[
	        |  ||
	        |  ||
	speed   |  | |  -log(d/dangerzone) * scalar
	        |  |  |
	        |  |   \
	        |  |    -\
	        |  |      --\
	        |------------+------------------------
	           |         |
	        deadzone   threshold
	--]]
	-- if vortex is true, rotate the speed to create a vortex
	--[[
	    moveup |     /
	           R   \ Ob \
	                  /
	--]]
	-- if vortex is vector3, it means the goal of the robot is at the vortex,
	--         add left or right speed accordingly
	--[[
	                 /
	           R   \ Ob -
	   movedown \    \      * goal(vortex)
	--]]

	if deadzone == nil then deadzone = 0 end
	local dV3 = myLocV3 - obLocV3
	if vns.api.parameters.mode_2D == true then dV3.z = 0 end
	local d = dV3:length() - deadzone
	if d <= 0 then d = 0.000000000000001 end -- TODO: maximum
	local ans = accumulatorV3
	if d < threshold - deadzone then
		if vns.robotTypeS == "drone" and robot.params.hardware == true then
			robot.leds.set_leds("blue")
		end
		dV3:normalize()
		local transV3 = - vns.Parameters.avoid_speed_scalar
		                * math.log(d/(threshold-deadzone))
		                * dV3:normalize()
		if type(vortex) == "bool" and vortex == true then
			ans = ans + transV3:rotate(quaternion(math.pi/4, vector3(0,0,1)))
		elseif type(vortex) == "userdata" and getmetatable(vortex) == getmetatable(vector3()) then
			local goalV3 = vortex - myLocV3
			local cos = goalV3:dot(-dV3) / (goalV3:length() * dV3:length())
			if cos > math.cos(60*math.pi/180) then
				local product = (-dV3):cross(goalV3)
				if product.z > 0 then
					ans = ans + transV3:rotate(quaternion(-math.pi/4, vector3(0,0,1)))
				else
					ans = ans + transV3:rotate(quaternion(math.pi/4, vector3(0,0,1)))
				end
			else
				ans = ans + transV3
			end
		else
			ans = ans + transV3
		end
	end
	return ans
end

function Avoider.create_avoider_node(vns, option)
	return function()
		Avoider.step(vns, option.drone_pipuck_avoidance)
	end
end

return Avoider
