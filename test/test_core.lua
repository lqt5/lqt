#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require'qtcore'

qa = QtCore.QCoreApplication.new(1, {'virt_test'})

local latin1 = QtCore.QLatin1String('wtf', 1)
print(latin1:data())
local s = QtCore.QString('wtf')
print(s:toStdString())
print(s:toUtf8())
print(QtCore.QString.fromStdString('wtf'):toStdString())

print(latin1:at(0):toLatin1())
print(QtCore.QChar.fromLatin1(10))
-- print(QtCore.QCoreApplication.arguments)
qa:setObjectName('wtf')
qa:setObjectName(QtCore.QLatin1String('wtf'))
print(qa:objectName():toStdString())
-- table.foreach(, print)
-- print(QtCore.QCoreApplication.__addmethod)

qo = QtCore.QObject.new()
qo.event = function(o, e)
	print('event overload called', e:type())
	return false
end

qo.childEvent = function(o, e)
	print('child event overload called', e:type())
	return false
end
qo:connect('2destroyed()', function() print('destroyed') end)

-- qo:__addmethod('valueChanged(int)')
-- qo:__addmethod('setValue(int)', function(_, val) slider:setValue(val) end)
-- qo:emitSignal('destroyed()')

ql = {}

for i = 1, 5 do
	table.insert(ql, qo:new())
end

qo.event = nil

for i, o in ipairs(ql) do
	o:delete()
end


-- print(qa.libraryPaths():at(0):toStdString())
-- print(QtCore.QStringList())
