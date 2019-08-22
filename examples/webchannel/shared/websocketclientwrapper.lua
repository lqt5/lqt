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
local QtCore = require 'qtcore'
local WebSocketTransport = require 'websockettransport'

--------------------------------------------------------------------------------
-- \brief Wraps connected QWebSockets clients in WebSocketTransport objects.

-- This code is all that is required to connect incoming WebSockets to the WebChannel. Any kind
-- of remote JavaScript client that supports WebSockets can thus receive messages and access the
-- published objects.
--------------------------------------------------------------------------------
local Class = QtCore.Class('WebSocketClientWrapper', QtCore.QObject) {}

function Class:__static_init()
	self:__addsignal('clientConnected2(QObject*)', 'public')
	self:__addsignal('clientConnected(QWebChannelAbstractTransport*)', 'public')

	self:__addslot('handleNewConnection()', self.handleNewConnection, 'private')
end
--------------------------------------------------------------------------------
-- Construct the client wrapper with the given parent.

-- All clients connecting to the QWebSocketServer will be automatically wrapped
-- in WebSocketTransport objects.
--------------------------------------------------------------------------------
function Class:__init(server)
	self.server = server

	self.connect(server, SIGNAL 'newConnection()', self, SLOT 'handleNewConnection()')
end
--------------------------------------------------------------------------------
-- Wrap an incoming WebSocket connection in a WebSocketTransport object.
--------------------------------------------------------------------------------
function Class:handleNewConnection()
	local socket = self.server:nextPendingConnection()
	local transport = WebSocketTransport.new({ socket }, socket)
	self:__emit('clientConnected'
		, { 'QWebChannelAbstractTransport*', transport }
	)
end

return Class
