#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require'qtcore'

qa = QtCore.QCoreApplication.new(1, {'virt_test'})

qo = QtCore.QObject.new()
qo.event = function(o, e)
	print('event overload called', e:type())
	return false
end
qo.childEvent = function(o, e)
	print('child event overload called', e:type())
	return false
 end

ql = {}

for i = 1, 5 do
	table.insert(ql, qo:new())
end

qo.event = nil

for i, o in ipairs(ql) do
	o:delete()
end


