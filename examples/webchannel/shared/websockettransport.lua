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
local QtWebChannel = require 'qtwebchannel'

--------------------------------------------------------------------------------
-- \brief QWebChannelAbstractSocket implementation that uses a QWebSocket internally.

-- The transport delegates all messages received over the QWebSocket over its
-- textMessageReceived signal. Analogously, all calls to sendTextMessage will
-- be send over the QWebSocket to the remote client.
--------------------------------------------------------------------------------
local Class = QtCore.Class('WebSocketTransport', QtWebChannel.QWebChannelAbstractTransport) {}

function Class:__static_init()
	self:__addslot('textMessageReceived(QString)', self.textMessageReceived, 'private')
end
--------------------------------------------------------------------------------
-- Construct the transport object and wrap the given socket.

-- The socket is also set as the parent of the transport object.
--------------------------------------------------------------------------------
function Class:__init(socket)
	self.socket = socket

	self.connect(socket, SIGNAL 'textMessageReceived(QString)', self, SLOT 'textMessageReceived(QString)')
	self.connect(socket, SIGNAL 'disconnected()', self, SLOT 'deleteLater()')
end
--------------------------------------------------------------------------------
-- Destroys the WebSocketTransport.
--------------------------------------------------------------------------------
function Class:__uninit()
	self.socket:deleteLater()
end
--------------------------------------------------------------------------------
-- Serialize the JSON message and send it as a text message via the WebSocket to the client.
--------------------------------------------------------------------------------
function Class:sendMessage(message)
	local doc = QtCore.QJsonDocument(message)
	self.socket:sendTextMessage(QtCore.QString.fromUtf8(doc:toJson('Compact')))
end
--------------------------------------------------------------------------------
-- Deserialize the stringified JSON messageData and emit messageReceived.
--------------------------------------------------------------------------------
function Class:textMessageReceived(messageData)
	local error = QtCore.QJsonParseError()
	local message = QtCore.QJsonDocument.fromJson(messageData:toUtf8(), error)
	if error.error ~= 'NoError' then
		qWarning():IN('Failed to parse text message as JSON object:'):IN(messageData)
			:IN('Error is:'):IN(error:errorString())
		return
	elseif not message:isObject() then
		qWarning():IN('Received JSON message that is not an object: '):IN(messageData)
		return
	end
	local obj = message:object()
	self:__emit('messageReceived', obj, { 'QWebChannelAbstractTransport*', self })
end

return Class
