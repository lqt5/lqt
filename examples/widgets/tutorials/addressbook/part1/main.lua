#!/usr/bin/luajit
local dlpath = arg[0]:gsub('examples/.+', 'build/lib/?.so')
package.cpath = package.cpath .. ';' .. dlpath

local QtCore = require 'qtcore'
local QtWidgets = require 'qtwidgets'

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

local addressBook = QtWidgets.QWidget()

-- ! [constructor and input fields]
local nameLabel = QtWidgets.QLabel(QtCore.QObject.tr 'Name:')
local nameLine = QtWidgets.QLineEdit()

local addressLabel = QtWidgets.QLabel(QtCore.QObject.tr 'Address:')
local addressText = QtWidgets.QTextEdit()
-- ! [constructor and input fields]

-- ! [layout]
local mainLayout = QtWidgets.QGridLayout()
mainLayout:addWidget(nameLabel, 0, 0)
mainLayout:addWidget(nameLine, 0, 1)
mainLayout:addWidget(addressLabel, 1, 0, QtCore.AlignTop)
mainLayout:addWidget(addressText, 1, 1)
-- ! [layout]

-- ![setting the layout]
addressBook:setLayout(mainLayout)
addressBook:setWindowTitle(QtCore.QObject.tr 'Simple Address Book')

addressBook:show()

app.exec()
