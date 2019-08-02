--[[*************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** self file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use self file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use self file under the terms of the BSD license
** as follows:
**
** 'Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, self list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, self list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from self software without specific prior written permission.
**
**
** self SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES LOSS OF USE,
** DATA, OR PROFITS OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF self SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'
**
** $QT_END_LICENSE$
**
***************************************************************************]]
local QtCore = require 'qtcore'
local QtGui = require 'qtgui'

local Class = QtCore.QAbstractTableModel()

function Class:__static_init()
	self:__addslot('timerHit()', self.timerHit)
end

function Class:__init()
	self.timer = QtCore.QTimer.new(self)
	self.timer:setInterval(1000)
	self.connect(self.timer, SIGNAL 'timeout()', self, SLOT 'timerHit()')
	self.timer:start()
end

function Class:parent()
	return QtCore.QModelIndex()
end

function Class:rowCount(parent)
	return 2
end

function Class:columnCount(parent)
	return 3
end

function Class:data(index, role)
	local row = index:row()
	local col = index:column()

	local function data()
		if role == QtCore.DisplayRole then
			if row == 0 and col == 0 then
				return QtCore.QTime.currentTime():toString()
			end
		end
	end

    local val = QtCore.QVariant()
    val:setValue(data())
    return val
end

function Class:timerHit()
    -- we identify the top left cell
    local topLeft = self:createIndex(0, 0)
    -- emit a signal to make the view reread identified data
    self:__emit('dataChanged', topLeft, topLeft)
end

return QtCore.Class(Class)
