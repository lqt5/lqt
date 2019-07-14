#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local arg = {n = select('#', ...), [0] = arg[0], ...}

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

local app = QtWidgets.QApplication(1 + arg.n, arg)

quit = QtWidgets.QPushButton("Quit")
quit:resize(75, 30)
quit:setFont(QtGui.QFont("Times", 18, 75))

-- won't work, the signals and slots are checked if they exist
-- print(quit:connect('madeup()', app, 'quit()'))

quit:show()

app.exec()


