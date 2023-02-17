-- register module with logger
robot.logger:register_module('nodes_place_block')

-- return node generator
return function(data, forward_distance)
   return {
      type = "sequence*",
      children = {
         -- recharge
         function()
            robot.electromagnet_system.set_discharge_mode("disable")
            return false, true
         end,
         -- reach the block
         robot.nodes.create_reach_block_node(data, forward_distance),
         -- change color
         function()
            if data.target.type ~= nil then
               robot.radios.nfc.send({tostring(data.target.type)})
            end
            return false, true
         end,
         -- release block
         function()
            robot.electromagnet_system.set_discharge_mode("destructive")
            return false, true
         end,
         -- wait for 2 sec
         robot.nodes.create_timer_node(2),
         function()
            robot.lift_system.set_position(robot.lift_system.position + 0.05)
            return false, true
         end,
         -- wait for 2 sec
         robot.nodes.create_timer_node(2),
         -- recharge magnet
         function()
            robot.electromagnet_system.set_discharge_mode("disable")
         end,
      },
   }
end
