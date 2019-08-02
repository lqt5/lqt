#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require'qtcore'

local qa = QtCore.QCoreApplication.new(1, {'test_object'})

local Base = QtCore.QObject()
function Base:__init(hp)
	self.hp = hp or 10
end

function Base:test()
	print(self, 'hp = ' .. self.hp)
end

function Base:event(event)
	return false
end

Base = QtCore.Class(Base)

local Child = Base({ Base }, 20)
print(Child)

-- Base:event()
Child:event()

print(Child.hp)
-- Base:test()
Child:test()
