#!/usr/bin/luajit
--[[*************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
***************************************************************************]]
dofile(arg[0]:gsub('examples[/\\].+', 'examples/init.lua'))

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'
local QtOpengl = require 'qtopengl'

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

local MainWindow = require 'mainwindow'
local GLWidget = require 'glwidget'

QtCore.QCoreApplication.setApplicationName('Qt Hello GL 2 Example')
QtCore.QCoreApplication.setOrganizationName('QtProject')
QtCore.QCoreApplication.setApplicationVersion('5.13.0')

local parser = QtCore.QCommandLineParser()
parser:setApplicationDescription(QtCore.QCoreApplication.applicationName())
parser:addHelpOption()
parser:addVersionOption()
local multipleSampleOption = QtCore.QCommandLineOption('multisample', 'Multisampling')
parser:addOption(multipleSampleOption)
local coreProfileOption = QtCore.QCommandLineOption('coreprofile', 'Use core profile')
parser:addOption(coreProfileOption)
local transparentOption = QtCore.QCommandLineOption('transparent', 'Transparent window')
parser:addOption(transparentOption)

parser:process(app)

local fmt = QtGui.QSurfaceFormat()
fmt:setDepthBufferSize(24)
if parser:isSet(multipleSampleOption) then
    fmt:setSamples(4)
end
if parser:isSet(coreProfileOption) then
    fmt:setVersion(3, 2)
    fmt:setProfile(QtGui.QSurfaceFormat.CoreProfile)
end
QtGui.QSurfaceFormat.setDefaultFormat(fmt)

local mainWindow = MainWindow()

GLWidget.setTransparent(parser:isSet(transparentOption))
if GLWidget.isTransparent() then
    mainWindow:setAttribute(QtCore.WA_TranslucentBackground)
    mainWindow:setAttribute(QtCore.WA_NoSystemBackground, false)
end
mainWindow:resize(mainWindow:sizeHint())
local desktopArea = QtWidgets.QApplication.desktop():width() *
    QtWidgets.QApplication.desktop():height()
local widgetArea = mainWindow:width() * mainWindow:height()
if widgetArea / desktopArea < 0.75 then
    mainWindow:show()
else
    mainWindow:showMaximized()
end

gc()

return app.exec()
