--[[*************************************************************************
Copyright (c) 2019-2019 Saniko

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
***************************************************************************]]

----------------------------------------------------------------------------------------------------
--- Creates a deep copy of an object.
----------------------------------------------------------------------------------------------------
local function deepCopy(tab)
	local lookup = {}
	local function _copy(value)
		if type(value) ~= 'table' then
			return value
		elseif lookup[value] then
			return lookup[value]
		end
		local new = {}
		lookup[value] = new
		for k,v in pairs(value) do
			new[_copy(k)] = _copy(v)
		end
	end
	return _copy(tab)
end
----------------------------------------------------------------------------------------------------
-- call __static_init(static constructor)
----------------------------------------------------------------------------------------------------
local staticInit = (function()
	local __cache = setmetatable({}, { __mode = 'k' })

	local function __init(classDef)
		if __cache[classDef] then
			return
		end
		__cache[classDef] = true

		local __super = rawget(classDef, '__super')
		if __super then
			__init(__super)
		end

		local __static_init = rawget(classDef, '__static_init')
		if type(__static_init) == 'function' then

			-- local metaStrings = __super and __super[LQT_OBJMETASTRING] or nil
			-- local metaData = __super and __super[LQT_OBJMETADATA] or nil
			-- local metaSlots = __super and __super[LQT_OBJSLOTS] or nil
			-- local metaSignals = __super and __super[LQT_OBJSIGS] or nil

			-- classDef[LQT_OBJMETASTRING] = deepCopy(metaStrings)
			-- classDef[LQT_OBJMETADATA] = deepCopy(metaData)
			-- classDef[LQT_OBJSLOTS] = deepCopy(metaSlots)
			-- classDef[LQT_OBJSIGS] = deepCopy(metaSignals)
			-- classDef[LQT_OBJMETADATA_STORE] = ''
			-- classDef[LQT_OBJMETASTRING_STORE] = ''

			__static_init(classDef)
		end     
	end

	return __init
end)()
----------------------------------------------------------------------------------------------------
-- trigger lqtAddOverride virtual-bind function
----------------------------------------------------------------------------------------------------
local function addOverride(inst, classDef)
	local __super = rawget(classDef, '__super')
	if __super then
		addOverride(inst, __super)
	end

	for k,v in pairs(classDef) do
		if type(v) == 'function' then
			inst[k] = v
			inst[k] = nil
		end
	end
end
-- reversed fields, cannot used in class defitition table
local reversedFields = {
	'new',
	'__name',
	'__classDef',
	'__proto',
	'__super',
}
----------------------------------------------------------------------------------------------------
-- 'Is a class' check.
----------------------------------------------------------------------------------------------------
local isClass = function (x)
	return type(x) == 'table' and type(x.__classDef) == 'table'
end
----------------------------------------------------------------------------------------------------
-- 'Is an object' check.
----------------------------------------------------------------------------------------------------
local isObject = function (x)
	return type(x) == 'userdata' and isClass(x.__class)
end
----------------------------------------------------------------------------------------------------
-- 'Is an instance of' check.
--  @param x Object that is tested for being an instance of class.
--  @param cls A class that the object is tested against.
--  @return Returns `true` if `obj` is an immediate instance of `cls` or one of it's ancestors.
----------------------------------------------------------------------------------------------------
local isInstanceOf = (function()
	local function checkQt(obj, cls)
		if type(obj) ~= 'userdata' or type(cls) ~= 'table' then
			return false
		end
		local __type = rawget(cls, '__type')
		return __type and (obj[__type] ~= nil)
	end

	local function check(obj, cls)
		if not isObject(obj) then
			return false
		end

		local ret = false

		local env = debug.getfenv(obj)
		local __class = rawget(env, '__class')

		while __class and __class ~= cls do
			-- check if obj create by __proto(Qt objects)
			if __class.__proto == cls then
				return true
			end
			__class = rawget(__class, '__super')
		end

		return __class == cls
	end

	local clsCaches = {}

	return function(obj, cls)
		local objCaches = clsCaches[cls]
		local key = tostring(obj)
		if objCaches then
			local flag = objCaches[key]
			if flag ~= nil then
				return flag
			end
		end

		local ret = checkQt(obj, cls) or check(obj, cls)

		if not objCaches then
			objCaches = setmetatable({}, { __mode = 'k' })
			clsCaches[cls] = objCaches
		end
		objCaches[key] = ret

		return ret
	end
end)()

local function errorNew()
	error('attempt to call `new` from an instance')
end

local function Class(name, proto)
	assert(type(name) == 'string', 'Class name must be an string')

	local function createInst(inst, classDef, ...)
		local env = debug.getfenv(inst)
		env.new = errorNew
		env.__class = classDef
		-- set object env inherit super(self) env
		setmetatable(env, { __index = classDef })

		-- call __static_init once
		--  for class object
		staticInit(classDef)

		-- trigger lqtAddOverride virtual-bind function
		addOverride(inst, classDef)

		-- call __init(custom constructor)
		local __init = rawget(classDef, '__init')
		if type(__init) == 'function' then
			__init(inst, ...)
		end

		return inst
	end

	return function(classDef)
		if not classDef then
			classDef = {}
		end

		for _,name in ipairs(reversedFields) do
			assert(rawget(classDef, name) == nil
				, string.format('`%s` is reversed classDef field!', name)
			)
		end

		classDef.__name = name
		classDef.__classDef = classDef
		classDef.__proto = proto.__proto and proto.__proto or proto
		classDef.__super = proto.__classDef and proto or nil

		local function ctor(new, ctorArgs)
			assert(type(ctorArgs) == 'table' or ctorArgs == nil, 'ctorArgs must be table or nil')
			return ctorArgs and new(unpack(ctorArgs)) or new()
		end

		classDef.new = function(ctorArgs, ...)
			local inst = ctor(classDef.__proto.new, ctorArgs)
			inst.__gc = false
			return createInst(inst, classDef, ...)
		end

		return setmetatable(classDef, {
			__index = function(_,k)
				-- call __static_init once
				--  for class object
				staticInit(classDef)

				local v = rawget(classDef, k)
				if v ~= nil then
					return v
				end

				v = proto[k]

				if type(v) == nil then
					error(string.format('Class `%s` : can not get undeclared member variable `%s`', name, k), 2)
				end

				return v
			end,
			__call = function(self, ctorArgs, ...)
				local inst = ctor(classDef.__proto, ctorArgs)
				return createInst(inst, classDef, ...)
			end,
		})
	end
end

return function(QtCore, LQT)
	rawset(QtCore, 'isClass', isClass)
	rawset(QtCore, 'isObject', isObject)
	rawset(QtCore, 'isInstanceOf', isInstanceOf)
	rawset(QtCore, 'Class', Class)
end
