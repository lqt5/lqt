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


-- local LQT_REF_CLASS = "Registry Ref Class"
-- local registry = debug.getregistry()

-- print('step1')
-- table.foreach(registry[LQT_REF_CLASS], print)


-- print('step2')
-- table.foreach(registry[LQT_REF_CLASS], print)


-- print('step3')
-- table.foreach(registry[LQT_REF_CLASS], print)

-- -- DragWidget:delete()
-- DragWidget = nil

-- -- horizontalLayout = nil

-- -- app:delete()
-- -- print(app)
-- app = nil

-- -- mainWidget:delete()
-- mainWidget = nil

-- gc()

-- print('step4')
-- table.foreach(registry[LQT_REF_CLASS], print)
