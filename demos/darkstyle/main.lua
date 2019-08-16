#!/usr/bin/luajit
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
dofile(arg[0]:gsub('demos[/\\].+', 'examples/init.lua'))

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

QtCore.QCoreApplication.setAttribute(QtCore.AA_ShareOpenGLContexts)

local DarkStyle = require 'darkstyle'
local MainWindow = require 'mainwindow'
local FramelessWindow = require 'framelesswindow.framelesswindow'

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

-- Use `rcc` to convert qrc to rcc file:
--	rcc darkstyle.qrc -binary -o darkstyle.rcc
QtCore.QResource.registerResource('darkstyle.rcc', '')
QtCore.QResource.registerResource('framelesswindow.rcc', '')

-- style our application with custom dark style
app.setStyle(DarkStyle.new())

-- create frameless window (and set windowState or title)
local framelessWindow = FramelessWindow()
-- framelessWindow:setWindowState(QtCore.WindowFullScreen);
framelessWindow:setWindowTitle(tr 'test title')
framelessWindow:setWindowIcon(app.style():standardIcon(QtWidgets.QStyle.SP_DesktopIcon))

-- create our mainwindow instance
local mainWindow = MainWindow.new()

-- add the mainwindow to our custom frameless window

framelessWindow:setContent(mainWindow)
framelessWindow:show()

app.exec()

framelessWindow = nil

gc()
