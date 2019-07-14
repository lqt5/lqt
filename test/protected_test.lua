package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require "qtcore"
local QtGui = require "qtgui"
local QtWidgets = require 'qtwidgets'

A = QtWidgets.QApplication(1, {'Protected test'})

-- We will implement our custom model
M = QtCore.QAbstractListModel()

-- stored in the environment table of the userdata
M.luaData = {'Hello', 'World'}

-- these are implemented virtual methods
function M:rowCount()
	return #self.luaData
end

function M:parent(model)
	return model
end

function M:columnCount()
	return 3
end

local empty = QtCore.QVariant()
function M:data(index, role)
	if role == QtCore.ItemDataRole.DisplayRole then
		local row = index:row()
		return QtCore.QVariant(self.luaData[row + 1])
	end
	return empty
end

-- this is a custom helper function
function M:addAnotherString(str)
	table.insert(self.luaData, str)
	local row = #self.luaData - 1
	local index = self:createIndex(row, 0)
	self:dataChanged(index, index)
end

-- some simple layout - list and a button
MW = QtWidgets.QWidget()

W = QtWidgets.QListView()
W:setModel(M)

B = QtWidgets.QPushButton('Add Lua data')
local counter = 1
B:connect('2clicked()', function()
	M:addAnotherString('Added text ' .. counter)
	counter = counter + 1
end)

L = QtWidgets.QVBoxLayout()
L:addWidget(W)
L:addWidget(B)
MW:setLayout(L)

MW:show()
A.exec()
