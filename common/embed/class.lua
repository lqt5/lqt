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
local QtCore
----------------------------------------------------------------------------------------------------
-- call __static_init(static constructor)
----------------------------------------------------------------------------------------------------
local staticInit = (function()
	local __cache = setmetatable({}, { __mode = 'k' })

	local function __init(classDef)
		local __super = rawget(classDef, '__super')
		if __super then
			__init(__super)
		end

		local __static_init = rawget(classDef, '__static_init')
		if type(__static_init) == 'function' then
			if __cache[__static_init] then
				return
			end
			__cache[__static_init] = true

			__static_init(classDef)
		end     
	end

	return __init
end)()
----------------------------------------------------------------------------------------------------
-- trigger lqtAddOverride virtual-bind function
----------------------------------------------------------------------------------------------------
local function addOverride(inst, classDef)
	local __override = inst.__override
	if type(__override) ~= 'function' then
		return
	end

	local __super = rawget(classDef, '__super')
	if __super then
		addOverride(inst, __super)
	end

	for k,v in pairs(classDef) do
		if type(v) == 'function' then
			__override(inst, k)
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
	'__addslot',
	'__addsignal',
	'__addproperty',
	'__emit',
}
-- All .new/ctor() Object instances
local instances = setmetatable({}, { __mode = 'v' })
----------------------------------------------------------------------------------------------------
-- 'Is a class' check.
----------------------------------------------------------------------------------------------------
local isClass = function (x)
	return type(x) == 'table' and not x.__class
end
----------------------------------------------------------------------------------------------------
-- 'Is an object' check.
----------------------------------------------------------------------------------------------------
local isObject = function (x)
	if type(x) ~= 'userdata' and type(x) ~= 'table' then
		return false
	end

	if not isClass(x.__class) then
		return false
	end
		-- lqt class object
	return (type(x) == 'userdata')
		-- lua class object
		or (type(x) == 'table' and x.__lua)
end
----------------------------------------------------------------------------------------------------
-- 'Is an instance of' check.
--  @param x Object that is tested for being an instance of class.
--  @param cls A class that the object is tested against.
--  @return Returns `true` if `obj` is an immediate instance of `cls` or one of it's ancestors.
----------------------------------------------------------------------------------------------------
local isInstanceOf = (function()
	local function checkQt(obj, cls)
		local __type = rawget(cls, '__type')
		return __type and (obj[__type] ~= nil)
	end

	local function check(obj, cls)
		if not isObject(obj) then
			return false
		end

		local ret = false

		local __class
		-- lqt class
		if type(obj) == 'userdata' then
			local env = debug.getfenv(obj)
			__class = rawget(env, '__class')
		-- lua class
		else
			__class = rawget(obj, '__class')
		end

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
		if (type(obj) ~= 'userdata' and type(obj) ~= 'table') or type(cls) ~= 'table' then
			return false
		end

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
----------------------------------------------------------------------------------------------------
-- Disable .new for instance object
----------------------------------------------------------------------------------------------------
local function errorNew()
	error('attempt to call `new` from an instance')
end
----------------------------------------------------------------------------------------------------
-- Defines a new class.
----------------------------------------------------------------------------------------------------
local function Class(name, super)
	assert(type(name) == 'string', 'Class name must be an string')

	local __protected

	local function createInst(inst, classDef, ...)
		if not classDef.__lua then
			local env = debug.getfenv(inst)
			env.new = errorNew
			env.__class = classDef
			env.__metaObject = classDef.__metaObject
			-- set object env inherit super(self) env
			setmetatable(env, getmetatable(classDef))
		else
			inst.__class = classDef
			setmetatable(inst, getmetatable(classDef))
		end

		__protected = false
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
		__protected = true

		return inst
	end

	-- ignore reversed lqt field getter
	--	1.reversed methods
	--	2.lqt metadata fields
	--	3.lqt class inherit check
	local function isReversedKey(k)
		return k:find('^__') or k:find('Lqt ') or k:find('%*$')
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

		classDef.__class = false
		classDef.__name = name
		classDef.__classDef = classDef

		-- Lua class(not inherit from lqt CLass)
		--	example: QtCore.Class('LuaClass')
		if not super then
			super = {}
			super.new = function() return {} end
			-- mark as lua class
			classDef.__lua = true
		else
			classDef.__lua = super.__classDef and super.__classDef.__lua or false
			-- Create qt-class specify QMetaObject
			classDef.__metaObject = QtCore.QMetaObject()
		end

		classDef.__proto = super.__proto and super.__proto or super
		classDef.__super = super.__classDef and super or nil

		if classDef.__lua then
			classDef.new = function(...)
				local inst = classDef.__proto.new()
				return createInst(inst, classDef, ...)
			end
			classDef.__call = function(self, ...)
				local inst = classDef.__proto.new()
				return createInst(inst, classDef, ...)
			end
		else
			local function ctor(new, ctorArgs)
				assert(type(ctorArgs) == 'table' or ctorArgs == nil, 'ctorArgs must be table or nil')
				return ctorArgs and new(unpack(ctorArgs)) or new()
			end

			classDef.new = function(ctorArgs, ...)
				local inst = ctor(classDef.__proto.new, ctorArgs)
				inst.__gc = false
				table.insert(instances, inst)
				return createInst(inst, classDef, ...)
			end
			classDef.__call = function(self, ctorArgs, ...)
				local inst = ctor(classDef.__proto, ctorArgs)
				table.insert(instances, inst)
				return createInst(inst, classDef, ...)
			end
		end

		return setmetatable(classDef, {
			__index = function(self,k)
				-- call __static_init once
				--  for class object
				staticInit(classDef)

				local v = rawget(classDef, k)
				if v ~= nil then
					return v
				end

				v = super and super[k] or nil

				if v == nil then
					if isReversedKey(k) then
						return
					end
					error(string.format('Class `%s` : can not get undeclared member variable `%s`', name, k), 2)
				end

				return v
			end,
			__newindex = function(self,k,v)
				if not __protected or isReversedKey(k) then
					rawset(self, k, v)
				else
					local ov = rawget(classDef, k)
					if ov ~= nil then
						rawset(classDef, k, v)
						return
					end

					if super and super[k] ~= nil then
						super[k] = v
					else
						error(string.format('Class `%s` : can not set undeclared member variable `%s` to `%s`', name, k, v), 2)
					end
				end
			end,
			__call = classDef.__call,
		})
	end
end
----------------------------------------------------------------------------------------------------
-- Entry
----------------------------------------------------------------------------------------------------
return function(...)
	QtCore = ...
	rawset(QtCore, 'isClass', isClass)
	rawset(QtCore, 'isObject', isObject)
	rawset(QtCore, 'isInstanceOf', isInstanceOf)
	rawset(QtCore, 'Class', Class)
	rawset(QtCore, 'instances', function()
		return instances
	end)
end
