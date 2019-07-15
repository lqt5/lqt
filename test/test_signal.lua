#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require'qtcore'

local qa = QtCore.QCoreApplication.new(1, {'virt_test'})

qa:__addsignal('valueChanged(int)')
qa:__addslot('setValue(int,int)', function(_, arg1, arg2) slider:setValue(val) end)

qa:connect('2destroyed(QObject*)', function()
end)

qa:connect('2applicationNameChanged()', function()
    print('applicationNameChanged: ', qa.applicationName():toStdString())
end)

qa.setApplicationName('New Application Name')

-- Qt-specific fields
local LQT_OBJMETASTRING = "Lqt MetaStringData"
local LQT_OBJMETADATA = "Lqt MetaData"
local LQT_OBJSLOTS = "Lqt Slots"
local LQT_OBJSIGS = "Lqt Signatures"

print(qa[LQT_OBJMETADATA])
print(qa[LQT_OBJMETASTRING])
print(qa['*' .. LQT_OBJMETADATA])
print(qa['*' .. LQT_OBJMETASTRING])

