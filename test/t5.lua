#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'

local new_MyWidget = function(...)
	local this = QtGui.QWidget.new(...)

	local quit = QtGui.QPushButton.new('Quit')
	quit:setFont(QtGui.QFont.new('Times', 18, 75))

	local lcd = QtGui.QLCDNumber.new()
	lcd:setSegmentStyle'Filled'

	local slider = QtGui.QSlider.new'Horizontal'
	slider:setRange(0, 99)
	slider:setValue(0)

	QtCore.QObject.connect(quit, '2clicked()', QtCore.QCoreApplication.instance(), '1quit()')
	QtCore.QObject.connect(slider, '2valueChanged(int)', lcd, '1display(int)')

	local layout = QtGui.QVBoxLayout.new()
	layout:addWidget(quit)
	layout:addWidget(lcd)
	layout:addWidget(slider)
	this:setLayout(layout)
	return this
end

local app = QtGui.QApplication.new(1 + select('#', ...), {arg[0], ...})
app.__gc = app.delete -- take ownership of object

widget = new_MyWidget()
widget:show()

app.exec()


