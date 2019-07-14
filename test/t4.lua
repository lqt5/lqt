#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'
local QtGui = require'qtgui'
local QtWidgets = require 'qtwidgets'

local new_MyWidget = function(...)
	local this = QtWidgets.QWidget.new(...)
	local quit = QtWidgets.QPushButton.new('Quit', this)
	this:setFixedSize(200, 120)
	quit:setGeometry(62, 40, 75, 30)
	quit:setFont(QtGui.QFont('Times', 18, 75))
	QtCore.QObject.connect(quit, '2clicked()', QtCore.QCoreApplication.instance(), '1quit()')
	return this
end

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

local widget = new_MyWidget()
widget:show()

app.exec()


