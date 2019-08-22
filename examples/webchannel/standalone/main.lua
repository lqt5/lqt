#!/usr/bin/luajit
--[[*************************************************************************
**
** Copyright (C) 2016 Klarälvdalens Datakonsult AB, a KDAB Group company, info@kdab.com, author Milian Wolff <milian.wolff@kdab.com>
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtWebChannel module of the Qt Toolkit.
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
package.path = package.path .. ';../shared/?.lua'

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'
local QtWebChannel = require 'qtwebchannel'
local QtWebSockets = require 'qtwebsockets'

local WebSocketClientWrapper = require 'websocketclientwrapper'
local WebSocketTransport = require 'websockettransport'
local Dialog = require 'dialog'
local Core = require 'core'

local function main(...)
	QtCore.QCoreApplication.setAttribute(QtCore.AA_ShareOpenGLContexts)

	local app = QtWidgets.QApplication(2 + select('#', ...), { 'Game Editor', '--ignore-gpu-blacklist', ... })

	local jsFileInfo = QtCore.QFileInfo(QtCore.ADD(QtCore.QDir.currentPath(), '/qwebchannel.js'))
	if not jsFileInfo:exists() then
		QtCore.QFile.copy(':/qtwebchannel/qwebchannel.js', jsFileInfo:absoluteFilePath())
	end

	-- setup the QWebSocketServer
	local server = QtWebSockets.QWebSocketServer('QWebChannel Standalone Example Server', 'NonSecureMode')
	if not server:listen('LocalHost', 12345) then
		qFatal('"Failed to open web socket server.')
		return 1
	end

	-- wrap WebSocket clients in QWebChannelAbstractTransport objects
	local clientWrapper = WebSocketClientWrapper({}, server)

	-- setup the channel
	local channel = QtWebChannel.QWebChannel()
	QtCore.QObject.connect(clientWrapper, SIGNAL 'clientConnected(QWebChannelAbstractTransport*)', channel, SLOT 'connectTo(QWebChannelAbstractTransport*)')

	-- setup the UI
	local dialog = Dialog()

	-- setup the core and publish it to the QWebChannel
	local core = Core({}, dialog)
	channel:registerObject('core', core)

	-- open a browser window with the client HTML page
	local url = QtCore.QUrl.fromLocalFile('./index.html')
	QtGui.QDesktopServices.openUrl(url)

	dialog:displayMessage((tr 'Initialization complete, opening browser at %1.'):arg(url:toDisplayString()))
	dialog:show()

	return app.exec()
end

local ret = main(...)
gc()
return ret
