#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require 'qtcore'
-- local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

-- the conversion from Lua string to QString is automatic
local hello = QtWidgets.QPushButton.new("Hello World!")
-- but not the other way round
-- print(hello:text():toUtf8())

hello:resize(100, 30)
hello:show()

app.exec()
