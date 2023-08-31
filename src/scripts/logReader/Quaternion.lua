--[[
-- ZHU Weixu
--   zhuweixu_harry@126.com
--
--   version 1.1 : some problems in create from 2 vecs are detected and marked
--   version 2   : create default from rotation, use createHardValue for hard set
--   version 3   : create getAxis, getAng
--   version 3.1 : create() creates a rotate((0,0,1),0) which is hardvalue(0,0,0,1) not a hardvalue(0,0,0,0)
--   version 4.1 : Quaternion(0,0,1,0) to create, 
--                 remove CLASS = "Quaternion", use CLASSQUATERNION = true instead
--   version 4.2 : add a createFrom4Vector3s function
--]]
local Vec3 = require("Vector3")

local Quaternion = {CLASSQUATERNION = true}
Quaternion.__index = Quaternion

-- call will Quaternion(0,0,1,0)
local Quaternionmt = {}
setmetatable(Quaternion, Quaternionmt)
function Quaternionmt:__call(x,y,z,th)
	return Quaternion:create(x,y,z,th)
end

function Quaternion:createFromHardValue(x,y,z,w)
	local instance = {}
	setmetatable(instance,self)
	self.__index = self

	if type(x) == "table" and x.CLASSVECTOR3 == true then
		instance.v = x
		instance.w = y
		return instance
	end
	if type(x) == "number" and 
	   type(y) == "number" and
	   type(z) == "number" and
	   type(w) == "number" then
		instance.v = Vec3:create(x,y,z)
		instance.w = w
		return instance
	end

	instance.v = Vec3:create(0,0,0)
	instance.w = 0
	return instance;
end

function Quaternion:createFrom4Vector3s(X1_, Y1_, X2_, Y2_)
	local X1, Y1, X2, Y2
	if type(X1_) == "table" and X1_.CLASSVECTOR3 == true and X1_:len() ~= 0 and
	   type(Y1_) == "table" and Y1_.CLASSVECTOR3 == true and Y1_:len() ~= 0 and
	   type(X2_) == "table" and X2_.CLASSVECTOR3 == true and X2_:len() ~= 0 and
	   type(Y2_) == "table" and Y2_.CLASSVECTOR3 == true and Y2_:len() ~= 0 then
		X1 = X1_:nor()
		Y1 = Y1_:nor()
		X2 = X2_:nor()
		Y2 = Y2_:nor()
	else
		print("invalid parameter for Quaternion: create from 4 vector3s")
		return Quaternion(0,0,1,0)
	end

	local th1 = math.acos(X1 ^ X2)
	local axis1 = X1 * X2
	local qua1
	if axis1:len() == 0 then
		if th1 < math.pi/2 then
			qua1 = Quaternion(0,0,1,0)
		else
			qua1 = Quaternion(0,0,1,math.pi)
		end
	else
		qua1 = Quaternion(axis1, th1)
	end

	local Y_rotated = qua1:toRotate(Y1)
	local th2 = math.acos(Y_rotated ^ Y2)
	local axis2 = (Y_rotated * Y2):nor()
	if (axis2 - X2):len() > 1 then X1 = -X1 end
	local qua2 = Quaternion(X1, th2)

	return qua1 * qua2
end

function Quaternion:create(x,y,z,th)	-- create from rotation
	local halfth
	local v
	if type(x) == "table" and x.CLASSVECTOR3 == true and x:len() ~= 0 then
		halfth = y / 2
		v = x / x:len()
		v = x:nor()
		return self:createFromHardValue(v * math.sin(halfth),math.cos(halfth))
	end
	if type(x) == "number" and
	   type(y) == "table" and y.CLASSVECTOR3 == true then
		halfth = x / 2
		v = y / y:len()
		v = y:nor()
		return self:createFromHardValue(v * math.sin(halfth),math.cos(halfth))
	end
	if type(x) == "number" and
	   type(y) == "number" and
	   type(z) == "number" and
	   type(th) == "number" and
	   (x ~=0 or y ~= 0 or z ~= 0)then
		halfth = th / 2
		v = Vec3:create(x,y,z)
		v = v:nor()
		return self:createFromHardValue(v * math.sin(halfth),math.cos(halfth))
	end
	--return self:createFromHardValue(0,0,0,0)
	return self:create(0,0,1,0)
end

function Quaternion:getAxis()
	local halfth = math.acos(self.w)
	if halfth == 0 then
		return Vec3:create(0,0,1)
	end
	return (self.v / math.sin(halfth)):nor()
end

function Quaternion:getAng()	-- in rad
	return math.acos(self.w) * 2
end

function Quaternion.__add(a,b)
	return Quaternion:createFromHardValue(a.v + b.v,a.w + b.w)
end

function Quaternion.__unm(b)
	return Quaternion:createFromHardValue(-b.v,-b.w)
end

function Quaternion.__sub(a,b)
	local c = -b
	return a + c 
end

function Quaternion.__mul(a,b)
	local tv = a.v * b.v + a.w * b.v + a.v * b.w
	local tw = a.w * b.w - a.v ^ b.v
	return Quaternion:createFromHardValue(tv,tw)
end

function Quaternion:squlen()
	return self.v:squlen() + self.w * self.w
end

function Quaternion:len()
	return math.sqrt(self:squlen())
end

--inverse
function Quaternion:inv()
	if self:len() ~= 0 then
		return Quaternion:createFromHardValue(-self.v/self:len(),self.w/self:len())
	end
	return Quaternion:createFromHardValue(0,0,0,0)
end

function Quaternion.__eq(a,b)
	local eqError = 0.0001
	return a.v == b.v and 
	       -eqError < a.w - b.w and a.w - b.w < eqError
end

function Quaternion:__tostring()
	local c = "(" .. "(" .. self.v.x .. "," .. self.v.y .. "," .. self.v.z .. ")"
	c = c .. "," .. self.w .. ")"
	return c
end

-- returns a vector, is a is not a vector, returns a whatever it is
function Quaternion:toRotate(a)
	if self.v:len() == 0 and self.w == 0 then
		return vector3(a)
	end
	if type(a) == "table" and a.CLASSVECTOR3 == true then
		---[[
		local p = Quaternion:createFromHardValue(a,0)
		local res = self * p
		res = res * self:inv()
		local b = Vec3:create(res.v)
		--]]
		return b
	else
		print("In Quaternion:toRotate, para not a Vector3")
		return vector3(a)
	end
end

return Quaternion
--function Quaternion
