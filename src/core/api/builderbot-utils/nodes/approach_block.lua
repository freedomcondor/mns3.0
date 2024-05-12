-- register module with logger
robot.logger:register_module('nodes_approach_block')

-- return node generator
return function(data, search_node, distance)
   return {
      type = "sequence*",
      children = {
         -- search block
         search_node,
         -- check range and blind approach and search again
                  -- check the target block is there
         function()
            if data.target.id == nil or
               data.blocks[data.target.id] == nil then
               robot.logger:log_warn("target block is nil, abort Z approach")
               robot.api.move.with_velocity(0,0)
               return false, false
            else
               return false, true
            end
         end,
         {
            type = "selector*",
            children = {
               -- check range
               function()
                  local target_block = data.blocks[data.target.id]
                  local robot_to_block = 
                     vector3(-target_block.position_robot):
                     rotate(target_block.orientation_robot:inverse())
                  local angle = math.atan(robot_to_block.y / robot_to_block.x) * (180 / math.pi)
                  local blind_tolerance = robot.api.parameters.z_approach_range_angle
                  if angle < blind_tolerance and 
                     angle > -blind_tolerance and
                     --robot_to_block:length() < robot.api.parameters.z_approach_range_distance then
                     robot_to_block:length() < distance + robot.api.parameters.z_approach_block_distance_increment * 2 then
                     return false, true
                  else
                     return false, false
                  end
               end,
               -- not in range, blind approach and search
               {
                  type = "sequence*",
                  children = {
                     robot.nodes.create_z_approach_block_node(data, distance + robot.api.parameters.z_approach_block_distance_increment),
                     search_node,
                  },
               }, 
            }, -- end of chilren
         }, -- end of check range and blind approach and search again
         -- now should be in range, curved approach
         robot.nodes.create_curved_approach_block_node(data, distance)
      }, -- end of children of the return table
   } -- end of the return table
end
