-- register module with logger
robot.logger:register_module('utils_queue')

local function create()
   local instance = {
      first = 1,
      last = 0,
      push = function(self, x)
         self.last = self.last + 1
         self[self.last] = x
      end,
      pop = function(self)
         if self.first > self.last then
            return nil
         end
         local value = self[self.first]
         self[self.first] = nil
         self.first = self.first + 1
         return value
      end,
      empty = function(self)
         return self.first > self.last
      end,
   }
   return instance
end

-- return module table
return { create = create }
