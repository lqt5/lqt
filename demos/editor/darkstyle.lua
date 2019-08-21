--[[###########################################################################
#                                                                             #
# The MIT License                                                             #
#                                                                             #
# Copyright (C) 2017 by Juergen Skrotzky (JorgenVikingGod@gmail.com)          #
#               >> https://github.com/Jorgen-VikingGod                        #
#                                                                             #
# Sources: https://github.com/Jorgen-VikingGod/Qt-Frameless-Window-DarkStyle  #
#                                                                             #
#############################################################################]]
local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

local Class = QtCore.Class('DarkStyle', QtWidgets.QProxyStyle) {}

function Class:__static_init()
	QtCore.QResource.registerResource('darkstyle.rcc', '')
    self.base = QtWidgets.QStyleFactory.create('Fusion')
end

function Class:__init(app)
    self:setBaseStyle(self.base)
	-- style our application with custom dark style
	app.setStyle(self)
end

function Class:polish(object)
	if QtCore.isInstanceOf(object, QtGui.QPalette) then
		self:polishPalette(object)
	elseif QtCore.isInstanceOf(object, QtCore.QCoreApplication) then
		self:polishApplication(object)
	end
end

function Class:polishPalette(palette)
	-- modify palette to dark
	palette:setColor(QtWidgets.QPalette.Window, QtGui.QColor(53, 53, 53))
	palette:setColor(QtWidgets.QPalette.WindowText, 'white')
	palette:setColor(QtWidgets.QPalette.Disabled
		, QtWidgets.QPalette.WindowText
		, QtGui.QColor(127, 127, 127)
	)
	palette:setColor(QtWidgets.QPalette.Base, QtGui.QColor(42, 42, 42))
	palette:setColor(QtWidgets.QPalette.AlternateBase, QtGui.QColor(66, 66, 66))
	palette:setColor(QtWidgets.QPalette.ToolTipBase, 'white')
	palette:setColor(QtWidgets.QPalette.ToolTipText, QtGui.QColor(53, 53, 53))
	palette:setColor(QtWidgets.QPalette.Text, 'white')
	palette:setColor(QtWidgets.QPalette.Disabled
		, QtWidgets.QPalette.Text
		, QtGui.QColor(127, 127, 127)
	)
	palette:setColor(QtWidgets.QPalette.Dark, QtGui.QColor(35, 35, 35))
	palette:setColor(QtWidgets.QPalette.Shadow, QtGui.QColor(20, 20, 20))
	palette:setColor(QtWidgets.QPalette.Button, QtGui.QColor(53, 53, 53))
	palette:setColor(QtWidgets.QPalette.ButtonText, 'white')
	palette:setColor(QtWidgets.QPalette.Disabled
		, QtWidgets.QPalette.ButtonText
		, QtGui.QColor(127, 127, 127)
	)
	palette:setColor(QtWidgets.QPalette.BrightText, 'red')
	palette:setColor(QtWidgets.QPalette.Link, QtGui.QColor(42, 130, 218))
	palette:setColor(QtWidgets.QPalette.Highlight, QtGui.QColor(42, 130, 218))
	palette:setColor(QtWidgets.QPalette.Disabled
		, QtWidgets.QPalette.Highlight
		, QtGui.QColor(80, 80, 80)
	)
	palette:setColor(QtWidgets.QPalette.HighlightedText, 'white')
	palette:setColor(QtWidgets.QPalette.Disabled
		, QtWidgets.QPalette.HighlightedText
		, QtGui.QColor(127, 127, 127)
	)
end

function Class:polishApplication(app)
	if not app then
		return
	end

	-- increase font size for better reading,
	-- setPointSize was reduced from +2 because when applied this way in Qt5, the
	-- font is larger than intended for some reason
  	local defaultFont = QtWidgets.QApplication.font()
  	defaultFont:setPointSize(defaultFont:pointSize() + 1)
  	app.setFont(defaultFont)

  	-- loadstylesheet
  	local file = QtCore.QFile(':/darkstyle/darkstyle.qss')
  	if file:open(QtCore.QIODevice.Text + QtCore.QIODevice.ReadOnly) then
		-- set stylesheet
		local qss = QtCore.QString.fromLatin1(file:readAll())
		app:setStyleSheet(qss)
		file:close()
  	end
end

return Class
