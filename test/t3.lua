#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

local window = QtWidgets.QWidget()
window:resize(200, 120)

local quit = QtWidgets.QPushButton("Quit", window)
quit:setFont(QtGui.QFont('Times', 18, 75))
quit:setGeometry(10, 40, 180, 40)

QtCore.QObject.connect(quit, '2clicked()', app, '1quit()')

window:show()

app.exec()


