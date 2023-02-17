-- register module with logger
robot.logger:register_module('utils_print')

local function table(table_input, indentation, skipindex)
   if indentation == nil then indentation = 0 end
   if type(table_input) ~= "table" then return nil end
   for i, v in pairs(table_input) do
      local str = ""
      for j = 1, indentation do
         str = str .. "\t"
      end
      local str = str .. "table:\t"
      str = str .. tostring(i) .. "\t"
      if i == skipindex then
         print("logger:\t", str .. "SKIPPED")
      else
         if type(v) == "table" then
            print("logger:\t", str)
            table(v, indentation + 1, skipindex)
         else
            str = str .. tostring(v)
            print("logger:\t", str)
         end
      end
   end
end

-- return module table
return { table = table }
