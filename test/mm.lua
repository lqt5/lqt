#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'

local qapp = QtCore.QCoreApplication(1+select("#", ...), {arg[0], ...})

local N = 1
local qo = nil
local del = QtCore.QObject.delete
for i = 1, 10*N do
  qo = QtCore.QObject(qo)
  print('created QObject', qo);
  qo.delete = function(...) del(...) print('deleting', ...) end
  qo.__gc = function(...) del(...) print('deleting', ...) end
end

-- [[
local t = {}
for i = 1, 10*N do
  table.insert(t, qo)
  print("getting parent", qo)
  qo = qo:parent()
end
--]]


qo=nil
print('collecting')
collectgarbage("collect")
collectgarbage("collect")
print('processing')
qapp.processEvents()
t=nil
print('collecting')
collectgarbage("collect")
print('processing')
qapp.processEvents()
print('collecting')
collectgarbage("collect")


