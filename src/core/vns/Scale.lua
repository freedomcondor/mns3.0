local Scale = {}
Scale.__index = Scale

function Scale:new(table)
	local instance = {}
	setmetatable(instance, self)
	if table == nil then return instance end
	if type(table) == "table" then
		for i, v in pairs(table) do
			instance[i] = v
		end
	elseif type(table) == "string" then
		instance[table] = 1
	end
	return instance
end

function Scale:inc(robotTypeS)
	if self[robotTypeS] == nil then
		self[robotTypeS] = 1
	else
		self[robotTypeS] = self[robotTypeS] + 1
	end
end

function Scale:dec(robotTypeS)
	if self[robotTypeS] == nil then
		self[robotTypeS] = -1
	else
		self[robotTypeS] = self[robotTypeS] - 1
	end
end

function Scale:totalNumber()
	local sum = 0
	for i, v in pairs(self) do
		sum = sum + v
	end
	return sum
end

function Scale.__add(A, B)
	local C = Scale:new(A)
	if B == nil then return C end
	for i, v in pairs(B) do
		if C[i] == nil then 
			C[i] = v
		else
			C[i] = C[i] + v
		end
	end
	return C
end

function Scale.__sub(A, B)
	local C = Scale:new(A)
	if B == nil then return C end
	for i, v in pairs(B) do
		if C[i] == nil then 
			C[i] = -v
		else
			C[i] = C[i] - v
		end
	end
	return C
end

function Scale.__eq(A, B)
	if A == nil and B ~= nil then return false end
	if A ~= nil and B == nil then return false end
	if A == nil and B == nil then return true end
	for i, v in pairs(A) do
		if A[i] ~= B[i] then return false end
	end
	for i, v in pairs(B) do
		if A[i] ~= B[i] then return false end
	end
	return true
end

return Scale
