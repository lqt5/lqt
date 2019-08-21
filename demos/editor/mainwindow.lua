--[[*************************************************************************
Copyright (c) 2019-2019 Saniko

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
***************************************************************************]]
local QtCore = require 'qtcore'
local QtWidgets = require 'qtwidgets'
local QtWebEngineWidgets = require 'qtwebenginewidgets'

local DarkStyle = require 'darkstyle'

local SceneWindow = require 'scenewindow'
local DevWindow = require 'devwindow'

local Class = QtCore.Class('MainWindow', QtWidgets.QMainWindow) {}

function Class:__init(app)
	-- Default dark style theme
	self.style = DarkStyle({}, app)

	self:setDockOptions { 'AnimatedDocks', 'AllowNestedDocks' }
	-- self:setDockOptions { 'AnimatedDocks', 'AllowNestedDocks', 'AllowTabbedDocks' }
	self:setTabPosition(QtCore.AllDockWidgetAreas, 'North')
	self:setContentsMargins(5, 5, 5, 5)

	local scene = SceneWindow { self }
	local dev = DevWindow({ self }, scene)

	self:addDockWidget(QtCore.DockWidgetArea.LeftDockWidgetArea, scene)
	self:addDockWidget(QtCore.DockWidgetArea.LeftDockWidgetArea, dev)

	self:splitDockWidget(scene, dev, QtCore.Orientation.Horizontal)

	local docks = QtWidgets.QList_QDockWidget__()
	docks:push_back(scene)
	docks:push_back(dev)

	local sizes = QtCore.QList_int_()
	sizes:push_back(2)
	sizes:push_back(1)

	self:resizeDocks(docks, sizes, QtCore.Orientation.Horizontal)

	self:setWindowTitle(tr 'Game Editor')
	self:showMaximized()
end

function Class:sizeHint()
	return QtCore.QSize(640, 480)
end

return Class
