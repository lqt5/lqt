#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require'qtcore'

local qa = QtCore.QCoreApplication.new(1, {'test_object'})

local Base = QtCore.Class('Base', QtCore.QObject) {}
function Base:__init(hp)
	self.hp = hp or 10
end

function Base:test()
	print(self, 'hp = ' .. self.hp)
end

function Base:event(event)
	return false
end

local Child = Base({}, 20)
print(Child)

-- Base:event()
Child:event()

print(Child.hp)
-- Base:test()
Child:test()
