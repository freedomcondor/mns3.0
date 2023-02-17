-- register module with logger
robot.logger:register_module('nodes_move_to_location')

-- move to the location (position and orientation) blindly
--
--       \       x
--     th2\     |
--    <----P    |         forward case
--          \   |
--       dis \th|
--            \ |
--             \|
--   y ---------------------
--              |\
--              | \       backup case
--              |  \   |
--              |   \th|
--              | th2\ |
--              | <---\
local function create_get_time_function(data, location)
   local th, dis, th2
   local backup_mode = false
   local get_th = function() -- get th time
      if location.position.x == 0 then
         if location.position.y < 0 then th = -90
         elseif location.position.y > 0 then th = 90 
         end
      else
         th = math.atan(location.position.y / location.position.x) * 180 / math.pi
         if location.position.x < 0 then
            backup_mode = true
         end  
      end
      if th >= 0 then
         robot.api.move.with_bearing(0, robot.api.parameters.default_turn_speed)
      else
         robot.api.move.with_bearing(0, -robot.api.parameters.default_turn_speed)
      end
      return math.abs(th) / robot.api.parameters.default_turn_speed
   end
   local get_dis = function() -- get dis time
      dis = math.sqrt(location.position.x ^ 2 + location.position.y ^ 2)
      if backup_mode == false then
         robot.api.move.with_bearing(robot.api.parameters.default_speed, 0)
      else
         robot.api.move.with_bearing(-robot.api.parameters.default_speed, 0)
      end
      return dis / robot.api.parameters.default_speed
   end
   local get_th2 = function() -- get th2 time
      -- th2   -- assume orientation is always around z axis
      local angle, axis = location.orientation:toangleaxis()
      -- reverse orientation if axis is pointing down
      if (axis - vector3(0,0,-1)):length() < 0.1 then
         axis = -axis
         angle = 2 * math.pi - angle
      end
      angle = angle * 180 / math.pi  -- angle from 0 to 360
      th2 = angle - th               -- th2 from -90 to 360 + 90
      if th2 > 180 then th2 = th2 - 360 end
      if th2 >= 0 then
         robot.api.move.with_bearing(0, robot.api.parameters.default_turn_speed)
      else
         robot.api.move.with_bearing(0, -robot.api.parameters.default_turn_speed)
      end
      return math.abs(th2) / robot.api.parameters.default_turn_speed
   end
   local check_obstacle = function()
      local flag = false
      for i, v in ipairs(data.obstacles) do
         if v.position.x < 0.19 and v.position.x > 0.06 then
            if v.source == 'camera' then
               flag = true
               break
            elseif v.source == 'left' or v.source == 'right' then
               if robot.rangefinders['underneath'].proximity > robot.api.parameters.proximity_touch_tolerance then
                  if robot.lift_system.position < robot.api.parameters.lift_system_rf_cover_threshold then
                     flag = true
                     break
                  end
               end
            elseif v.source == '6' or v.source == '7' then
               if robot.lift_system.position >= robot.api.parameters.lift_system_rf_cover_threshold then
                  flag = true
                  break
               end
            elseif v.source == '5' or v.source == '8' then
               flag = true
               break

            end
         end
      end
      if flag == true then
         robot.logger:log_info("obstacle obstacle encountered, abort blind approach")
         return false, false
      end
   end
   return get_th, get_dis, get_th2, check_obstacle
end

-- return node generator
return function(data, location)
   local get_th, get_dis, get_th2, check_obstacle = create_get_time_function(data, location)
   return {
      type = "sequence*",
      children = {
         function()
            robot.camera_system.disable()
            robot.logger:log_info("approaching target")
            return false, true
         end,
         -- turn th
         robot.nodes.create_timer_node(get_th, check_obstacle),
         -- move dis
         robot.nodes.create_timer_node(get_dis, check_obstacle),
         -- turn th2
         robot.nodes.create_timer_node(get_th2, check_obstacle),
         -- stop moving
         function() 
            robot.api.move.with_velocity(0,0)
            robot.camera_system.enable()
            return false, true 
         end,
      }, -- end of the children
   } -- end of the node
end
