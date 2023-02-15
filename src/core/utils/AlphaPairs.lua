rawpairs = pairs
local random_pairs = function(intable)
    -- create index as a alpha ordered index of intable
    local number_index = {}
    local string_index = {}
    for i, v in rawpairs(intable) do
        if type(i) == "number" then
            number_index[#number_index + 1] = i
        elseif type(i) == "string" then
            string_index[#string_index + 1] = i
        end
	end

    table.sort(number_index)
    table.sort(string_index)

    local number_n = #number_index
    local index = number_index
    for i = 1, #string_index do
        index[number_n + i] = string_index[i]
    end
    local n = #index

    -- create a random sequence of 1 to n
    local random_list = {}
    for i = 1, n do random_list[i] = i end
    for i = 1, n - 1 do 
        -- generate a random number between i and n
        local random_number = math.floor(robot.random.uniform(i, n + 1))
        if random_number == n + 1 then random_number = n end
        -- swap number i and random_number
        random_list[i], random_list[random_number] = 
        random_list[random_number], random_list[i]
    end

	local i = 0;
	return 
	function()
		i = i + 1
		--return index[random_list[i]], intable[index[random_list[i]]]
		return index[i], intable[index[i]]
	end
end

return random_pairs