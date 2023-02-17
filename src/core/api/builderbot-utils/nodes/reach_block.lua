-- register module with logger
robot.logger:register_module('nodes_reach_block')

-- assuming I'm distance(parameter) away of the block, 
-- move forward blindly for a certain distance
-- based on target.offset, adjust the distance and 
--                         raise or lower the manipulator
--     offset could be vector3(0,0,0), means the reference block itself
--                     vector3(1,0,0), means just infront of the reference block
--                     vector3(0,0,1), top of the reference block
--                     vector3(1,0,-1), and so on
--                     vector3(1,0,-2)
-- return node generator
return function(data, distance)
   return {
      type = "sequence*",
      children = {
         -- assume I arrive the pre-position, reach it
         {
            type = "selector*",
            children = {
               -- reach the block itself
               {
                  type = "sequence*",
                  children = {
                     -- condition vector3(0,0,0)
                     function ()
                        if data.target.offset == vector3(0,0,0) then
                           return false, true
                        else
                           return false, false
                        end
                     end,
                     -- raise lift
                     function()
                        robot.lift_system.set_position(data.blocks[data.target.id].position_robot.z) 
                        return false, true
                     end,
                     -- check whether lift to position
                     function()
                        if robot.lift_system.state == "inactive" then return false, true
                        else return true end
                     end,
                     -- forward to block
                     robot.nodes.create_timer_node(
                        (distance 
                           - robot.api.constants.end_effector_position_offset.x 
                           - robot.api.constants.end_effector_position_pickup_bias
                        ) /
                           robot.api.parameters.default_speed,
                        function()
                           robot.api.move.with_velocity(robot.api.parameters.default_speed, 
                                                      robot.api.parameters.default_speed)
                        end
                     )
                  },
               },
               -- reach the top of the reference block
               {
                  type = "sequence*",
                  children = {
                     -- condition vector3(0,0,1)
                     function ()
                        if data.target.offset == vector3(0,0,1) then
                           return false, true
                        else
                           return false, false
                        end
                     end,
                     -- raise lift
                     function()
                        robot.lift_system.set_position(data.blocks[data.target.id].position_robot.z + 
                                                       robot.api.constants.block_side_length) 
                        return false, true
                     end,
                     -- check whether lift to position
                     function()
                        if robot.lift_system.state == "inactive" then return false, true
                        else return true end
                     end,
                     -- forward to block
                     robot.nodes.create_timer_node(
                        (distance - 
                        robot.api.constants.end_effector_position_offset.x - 
                        robot.api.parameters.end_effector_overhang_length
                        ) / robot.api.parameters.default_speed,
                        function()
                           robot.api.move.with_velocity(robot.api.parameters.default_speed, 
                                                      robot.api.parameters.default_speed)
                        end
                     ),
                     function() robot.api.move.with_velocity(0,0) return false, true end,

                     function()
                        robot.lift_system.set_position(robot.lift_system.position -
								                       robot.api.constants.block_side_length / 2)
                        return false, true
                     end,
                     -- wait for 2 sec
                     robot.nodes.create_timer_node(0.5),
                     -- check whether lift to position
                     function()
                        if robot.lift_system.state == "inactive" then return false, true
                        else return true end
                     end
                  },
               },
               -- reach the front of the reference block
               {
                  type = "sequence*",
                  children = {
                     -- condition vector3(1,0,0)
                     function ()
                        if data.target.offset == vector3(1,0,0) then
                           return false, true
                        else
                           return false, false
                        end
                     end,
                     -- raise lift
                     function()
                        robot.lift_system.set_position(data.blocks[data.target.id].position_robot.z - 
                                                       robot.api.constants.block_side_length / 2 +
                                                       robot.api.constants.end_effector_position_place_bias) 
                        return false, true
                     end,
                     -- wait for 2 sec
                     robot.nodes.create_timer_node(0.5),
                     -- check whether lift to position
                     function()
                        if robot.lift_system.state == "inactive" then return false, true
                        else return true end
                     end,
                     -- forward in front of block
                     robot.nodes.create_timer_node(
                        (distance - 
                        robot.api.constants.end_effector_position_offset.x - 
                        robot.api.constants.block_side_length - 
                        robot.api.parameters.end_effector_overhang_length
                        ) / robot.api.parameters.default_speed,
                        function()
                           robot.api.move.with_velocity(robot.api.parameters.default_speed, 
                                                      robot.api.parameters.default_speed)
                        end
                     ),
                     function() robot.api.move.with_velocity(0,0) return false, true end,
                  },
               },
               -- reach the front down of the reference block
               {
                  type = "sequence*",
                  children = {
                     -- condition vector3(1,0,-1)
                     function ()
                        if data.target.offset == vector3(1,0,-1) then
                           return false, true
                        else
                           return false, false
                        end
                     end,
                     -- lower lift
                     function()
                        robot.lift_system.set_position(data.blocks[data.target.id].position_robot.z - 
                                                      robot.api.constants.block_side_length - 
                                                      robot.api.parameters.end_effector_overhang_length) 
                        return false, true
                     end,
                     -- check whether lift to position
                     function()
                        if robot.lift_system.state == "inactive" then return false, true
                        else return true end
                     end,
                     -- forward in front of block
                     robot.nodes.create_timer_node(
                        (distance - 
                        robot.api.constants.end_effector_position_offset.x - 
                        robot.api.constants.block_side_length - 
                        robot.api.parameters.end_effector_overhang_length
                        ) / robot.api.parameters.default_speed,
                        function()
                           robot.api.move.with_velocity(robot.api.parameters.default_speed, 
                                                      robot.api.parameters.default_speed)
                        end
                     )
                  },
               },
               -- reach the front down down of the reference block
               {
                  type = "sequence*",
                  children = {
                     -- condition vector3(1,0,-2)
                     function ()
                        if data.target.offset == vector3(1,0,-2) then
                           return false, true
                        else
                           return false, false
                        end
                     end,
                     -- lower lift
                     function()
                        robot.lift_system.set_position(data.blocks[data.target.id].position_robot.z - 
                                                      robot.api.constants.block_side_length * 2) 
                        return false, true
                     end,
                     -- check whether lift to position
                     function()
                        if robot.lift_system.state == "inactive" then return false, true
                        else return true end
                     end,
                     -- forward in front of block
                     robot.nodes.create_timer_node(
                        (distance - 
                        robot.api.constants.end_effector_position_offset.x - 
                        robot.api.constants.block_side_length - 
                        robot.api.parameters.end_effector_overhang_length
                        ) / robot.api.parameters.default_speed,
                        function()
                           robot.api.move.with_velocity(robot.api.parameters.default_speed, 
                                                      robot.api.parameters.default_speed)
                        end
                     )
                  },
               },
               function() robot.logger:log_info("no reach method for offset, abort reach") return false, false end,
            }, -- end of children of step forward
         }, -- end of step forward
         -- stop
         function() robot.api.move.with_velocity(0,0) return false, true end,
      }, -- end of the children of the return table
   } -- end of the return table
end
