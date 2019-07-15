#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require'qtcore'

local qa = QtCore.QCoreApplication.new(1, {'object_test'})

local Base = QtCore.QObject()
function Base:__init(hp)
	self.hp = hp or 10
end

function Base:test()
	print(self, 'hp = ' .. self.hp)
end

function Base:event(event)
end

-- TODO:fix crash
-- local Child = Base:create({ Base }, 20)
local Child = Base:create({ Base.new() }, 20)
print(Child)

-- Base:event()
Child:event()

print(Child.hp)
-- Base:test()
Child:test()
