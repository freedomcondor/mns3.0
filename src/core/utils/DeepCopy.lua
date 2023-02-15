function DeepCopy(table)
	local new_table
	if type(table) ~= "table" then
		return table
	else
		new_table = {}
		for i, v in pairs(table) do
			new_table[DeepCopy(i)] = DeepCopy(v)
		end
	end
	return new_table
end

return DeepCopy
