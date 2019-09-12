#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require'qtcore'

local qa = QtCore.QCoreApplication.new(1, {'test_class'})

local Class = QtCore.Class('TestClass', QtCore.QObject) {}

function Class:__static_init()
	print('__static_init', self)
	self.className = 'TestObject'
end

function Class:__init(name)
	print('__init', self)
	if name then
		print('set className')
		self.className = name
	end
end

function Class:__uninit()
	print('gc', self)
end

function Class:dump()
	print('ClassName:', self, self.className)
end

local function main()
	local obj = Class()
	obj:dump()

	-- will delete in gc
	local obj1 = Class({}, 'TestObject 1')
	obj1:dump()

	-- wont delete in gc
	local obj2 = Class.new({}, 'TestObject 2')
	obj2:dump()
end
local succ,ret = xpcall(main, debug.traceback)
if not succ then print(ret) end

-- undeclared member set/get test
succ,ret = pcall(function()
	local obj = Class()
	obj.wtf = 123
end)
assert(not succ and ret:find('can not set undeclared member variable'))

succ,ret = pcall(function()
	local obj = Class()
	print(obj.wtf)
end)
assert(not succ and ret:find('can not get undeclared member variable'))

table.foreach(debug.getregistry()['Registry Ref Class'], print)

print('start gc')
collectgarbage()
print('end gc')

table.foreach(debug.getregistry()['Registry Ref Class'], print)
