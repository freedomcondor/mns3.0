--------------------------------------------
--	Version 1.1 : start basic function, but didn't handle minus situation very well
--------------------------------------------
local BaseNumber = {CLASSBASENUMBER = true}
BaseNumber.__index = BaseNumber

-- call with B a se Nu m b er(0,0,0)
local BaseNumbermt = {}
setmetatable(BaseNumber, BaseNumbermt)
function BaseNumbermt:__call(base, exp)
	return BaseNumber:create(base, exp)
end

function BaseNumber:create(base, exp)
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
		--the metatable of instance would be whoever owns this create
	      --so you can :  a = State:create();  b = a:create();  grandfather-father-son

	-- Asserts and add data
	if type(base) == "table" and base.CLASSBASENUMBER == true then
		instance.base = base.base
		instance.exp = {}
		for i, v in pairs(base.exp) do
			if type(i) == "number" then
				instance.exp[i] = v
			end
		end
		instance.highestBit = base.highestBit
		instance:regulate()
		return instance
	end
	if 	type(base) == "number" then
		if type(exp) ~= "table" then exp = {} end

		instance.base = base
		instance.exp = {}
		local highest = 0
		for i, v in pairs(exp) do
			if type(i) == "number" then
				instance.exp[i] = v
				if i > highest then highest = i end
			end
		end
		instance.highestBit = highest

		instance:regulate()
		return instance
	end

	instance:regulate()
	return instance
end

function BaseNumber:inc(exp, amount)
	self.exp[exp] = self.exp[exp] + amount or 1
end

function BaseNumber:createWithInc(base, dit)
	local exp = {}
	exp[dit] = 1
	return BaseNumber:create(base, exp)
end


-------------------------------------------------------------------------
-- every operator below should not change the parameters, 
-- for example if b = a:nor(), then a remains the same and b is a's normalization
-- except for regulate()

function BaseNumber:regulate()
	for i = 0, self.highestBit do
		if self.exp[i] ~= nil then
			self.exp[i+1] = (self.exp[i+1] or 0) + math.modf((self.exp[i] or 0)/self.base) -- int towards 0
			self.exp[i] = math.fmod((self.exp[i] or 0), self.base)
		end
	end
	self.highestBit = 0
	for i, v in pairs(self.exp) do
		if self.exp[i] == 0 then self.exp[i] = nil end
		if self.exp[i] ~= nil and i > self.highestBit then self.highestBit = i end
	end
end

-- c = a + b
function BaseNumber.__add(a,b)
	if type(a) == "number" and a == 0 and 
	   type(b) == "table" and b.CLASSBASENUMBER == true then
		a = BaseNumber:create(b.base, {})
	elseif type(b) == "number" and b == 0 and 
	       type(a) == "table" and a.CLASSBASENUMBER == true then
		b = BaseNumber:create(a.base, {})
	end
	if type(a) == "table" and a.CLASSBASENUMBER == true and
	   type(b) == "table" and b.CLASSBASENUMBER == true and
	   a.base == b.base then
		local c = BaseNumber:create(a)
		if b.highestBit > c.highestBit then c.highestBit = b.highestBit end
		for i, v in pairs(b.exp) do
			c.exp[i] = (c.exp[i] or 0) + (b.exp[i] or 0)
		end
		c:regulate()
		return c
	end
	return BaseNumber:create(a.base)
end

function BaseNumber.__unm(b)
	local c = BaseNumber:create(b)
	for i, v in pairs(c.exp) do
		c.exp[i] = -v
	end
	return c
end

function BaseNumber.__sub(a,b)
	local c = BaseNumber:create(-b)
	c = c + a
	return c
end

-- the result of * is a Vector, cross multi of Vectors, or number multi like 5 * a
	-- for productive multi, see __pow
function BaseNumber.__mul(a,b)
	if type(a) == "table" and a.CLASSBASENUMBER == true and
	   type(b) == "number" then
		c = BaseNumber:create(a)
		for i, v in pairs(c.exp) do
			c.exp[i] = v * b
		end
		c:regulate()
		return c
	end
	if type(a) == "number" and
	   type(b) == "table" and b.CLASSBASENUMBER == true then
		c = BaseNumber:create(b)
		for i, v in pairs(c.exp) do
			c.exp[i] = v * a
		end
		c:regulate()
		return c
	end
end

function BaseNumber.__div(a,b)
	if type(b) == "number" and b ~= 0 then
		return a * (1/b)
	end
end

-- the result of ^ is a number : productive multi, you can write a ^ a, or a ^ 2
function BaseNumber.__eq(a,b)
	if a.base ~= b.base then
		return false
	end
	if a.highestBit ~= b.highestBit then
		return false
	end
	for i = 0, a.highestBit do
		if a.exp[i] ~= b.exp[i] then
			return false
		end
	end

	return true
end

function BaseNumber.__lt(a,b)  -- <
	if a == math.huge then return false end
	if b == math.huge then return true end

	if type(a) == "number" and a == 0 and 
	   type(b) == "table" and b.CLASSBASENUMBER == true then
		a = BaseNumber:create(b.base, {})
	elseif type(b) == "number" and b == 0 and 
	       type(a) == "table" and a.CLASSBASENUMBER == true then
		b = BaseNumber:create(a.base, {})
	end

	if a.highestBit < b.highestBit then
		if b.exp[b.highestBit] > 0 then
			return true
		else
			return false
		end
	elseif a.highestBit > b.highestBit then
		if a.exp[a.highestBit] > 0 then
			return false
		else
			return true
		end
	elseif a.highestBit == b.highestBit then
		for i = a.highestBit, 0, -1 do
			if (a.exp[i] or 0) < (b.exp[i] or 0) then return true
			elseif (a.exp[i] or 0) > (b.exp[i] or 0) then return false
			end
		end
		-- all the same
		return false
	end
end
function BaseNumber.__le(a,b)  -- <=
	if b == math.huge then return true end
	if a == math.huge then return false end

	if type(a) == "number" and a == 0 and 
	   type(b) == "table" and b.CLASSBASENUMBER == true then
		a = BaseNumber:create(b.base, {})
	elseif type(b) == "number" and b == 0 and 
	       type(a) == "table" and a.CLASSBASENUMBER == true then
		b = BaseNumber:create(a.base, {})
	end

	if a.highestBit < b.highestBit then
		if b.exp[b.highestBit] > 0 then
			return true
		else
			return false
		end
	elseif a.highestBit > b.highestBit then
		if a.exp[a.highestBit] > 0 then
			return false
		else
			return true
		end
	elseif a.highestBit == b.highestBit then
		for i = a.highestBit, 0, -1 do
			if (a.exp[i] or 0) < (b.exp[i] or 0) then return true
			elseif (a.exp[i] or 0) > (b.exp[i] or 0) then return false
			end
		end
		-- all the same
		return true
	end
end

function BaseNumber:__tostring()
	local str = "(" .. self.base .. ": ("
	for i = 0, self.highestBit do
		if self.exp[i] ~= nil then
			str = str .. tostring(i) .. ":" .. tostring(self.exp[i]) .. ", "
		end
	end
	str = str .. "), " .. tostring(self.highestBit) .. ")"

	return str
end

return BaseNumber
