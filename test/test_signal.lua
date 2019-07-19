#!/usr/bin/lua
dofile(arg[0]:gsub('test/.+', 'examples/init.lua'))

local QtCore = require 'qtcore'

local qa = QtCore.QCoreApplication.new(1, {'virt_test'})

qa:__addsignal('valueChanged(double,double)')
qa:__addslot('setValue(double,double)', function(self, arg1, arg2)
	print('setValue:', self, arg1, arg2)
end)

QtCore.QObject.connect(qa, '2valueChanged(double,double)', qa, '1setValue(double,double)')
qa:connect('2valueChanged(double,double)', qa, '1setValue(double,double)')

qa:connect('2destroyed(QObject*)', function()
end)
qa:connect('2applicationNameChanged()', function()
    print('applicationNameChanged: ', qa.applicationName():toStdString())
end)
table.foreach(qa:__methods(), print)

-- lqt-specific fields
local LQT_OBJMETASTRING = "Lqt MetaStringData"
local LQT_OBJMETADATA = "Lqt MetaData"
local LQT_OBJSLOTS = "Lqt Slots"
local LQT_OBJSIGS = "Lqt Signatures"

print(qa[LQT_OBJMETADATA])
print(qa[LQT_OBJMETASTRING])
print(qa['*' .. LQT_OBJMETADATA])
print(qa['*' .. LQT_OBJMETASTRING])

qa.setApplicationName('New Application Name')

local meta = qa:metaObject()
local signalIndex = meta:indexOfMethod('setValue(double,double)')
local signal = meta:method(signalIndex)
print('signal:', meta, signalIndex, signal)

signal:invoke(qa, 'AutoConnection', 0, 1)

QtCore.QMetaObject.invokeMethod(qa
	, 'valueChanged'
	-- , 'setValue'
	, 'AutoConnection'
	, 3.14, 9.28
)

qa:__emit('valueChanged', 1234, 5678)
