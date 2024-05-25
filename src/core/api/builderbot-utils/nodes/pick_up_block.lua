-- register module with logger
robot.logger:register_module('nodes_pick_up_block')

-- return node generator
return function(data, forward_distance)
   return {
      type = 'sequence*',
      children = {
         -- recharge
         function()
            --robot.electromagnet_system.set_discharge_mode('disable')
            return false, true
         end,
         -- reach the block
         robot.nodes.create_reach_block_node(data, forward_distance),
         -- touch down
         {
            type = 'selector',
            children = {
               -- hand full ?
               --[[
               function()
                  if robot.rangefinders['underneath'].proximity < robot.api.parameters.proximity_touch_tolerance then
                     return false, true -- not running, true
                  else
                     return false, false -- not running, false
                  end
               end,
               --]]
               -- low lift
               function()
                  robot.lift_system.set_position(0)
                  if robot.lift_system.position < 0 + robot.api.parameters.lift_system_position_tolerance then
                     return false, true
                  else
                     return true
                  end
               end
            }
         },
         -- count and raise
         {
            type = 'sequence*',
            children = {
               -- attrack magnet
               --[[
               function()
                  --robot.electromagnet_system.set_discharge_mode('constructive')
                  return false, true
               end,
               --]]
               -- wait for 2 sec
               robot.nodes.create_timer_node(0.5),
               -- raise
               function()
                  robot.lift_system.set_position(robot.lift_system.position + 0.05)
                  return false, true -- not running, true
               end,
               robot.nodes.create_timer_node(0.5),
               -- recharge magnet
               --[[
               function()
                  --robot.electromagnet_system.set_discharge_mode('disable')
                  return false, true
               end
               --]]
            }
         },
         -- check success
         -- wait
         --[[
         robot.nodes.create_timer_node(2),
         function()
            if robot.rangefinders['underneath'].proximity < robot.api.parameters.proximity_touch_tolerance then
               robot.logger:log_info("pick up block succeeded")
               return false, true -- not running, true
            else
               robot.logger:log_info("pick up block failed")
               return false, false -- not running, false
            end
         end,
         -- change color
         function()
            if data.target.type ~= nil then
               robot.radios.nfc.send({tostring(data.target.type)})
               return false, true
            end
         end
         --]]
      }
   }
end
