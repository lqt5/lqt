#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'

local LCD_Range = function(...)
	local this = QtGui.QWidget.new(...)
	--print(this:metaObject():className(), this:metaObject():methodCount())
	--print(this:metaObject():className(), this:metaObject():methodCount())

	local lcd = QtGui.QLCDNumber.new()
	lcd:setSegmentStyle 'Filled'

	local slider = QtGui.QSlider.new'Horizontal'
	slider:setRange(0, 99)
	slider:setValue(0)

	this:__addmethod('valueChanged(int)')
	this:__addmethod('setValue(int)', function(_, val) slider:setValue(val) end)
	QtCore.QObject.connect(slider, '2valueChanged(int)', lcd, '1display(int)')
	QtCore.QObject.connect(slider, '2valueChanged(int)', this, '2valueChanged(int)')

	local layout = QtGui.QVBoxLayout.new()
	layout:addWidget(lcd)
	layout:addWidget(slider)
	this:setLayout(layout)
	return this
end

local new_MyWidget = function(...)
	local this = QtGui.QWidget.new(...)

	local quit = QtGui.QPushButton.new('Quit')
	quit:setFont(QtGui.QFont('Times', 18, 75))

	QtCore.QObject.connect(quit, '2clicked()', this, '1close()')

	local grid = QtGui.QGridLayout.new()
	local previousRange = nil
	for row = 1, 3 do
		for column = 1, 3 do
			local lcdrange = LCD_Range()
			grid:addWidget(lcdrange, row, column)
			if previousRange then
				QtCore.QObject.connect(lcdrange, '2valueChanged(int)',
					previousRange, '1setValue(int)')
			end
			previousRange = lcdrange
		end
	end

	local layout = QtGui.QVBoxLayout.new()
	layout:addWidget(quit)
	layout:addLayout(grid)
	this:setLayout(layout)
	return this
end

local app = QtGui.QApplication.new(1 + select('#', ...), {arg[0], ...})
app.__gc = app.delete -- take ownership of object

widget = new_MyWidget()
widget:show()

app.exec()


