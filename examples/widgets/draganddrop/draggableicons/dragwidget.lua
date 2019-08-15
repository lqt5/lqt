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
local QtWidgets = require 'qtwidgets'

local Class = QtCore.Class('DragWidget', QtWidgets.QFrame) {}

function Class:__init()
    self:setMinimumSize(200, 200)
    self:setFrameStyle(QtWidgets.QFrame.Sunken + QtWidgets.QFrame.StyledPanel)
    self:setAcceptDrops(true)

    local boatIcon = QtWidgets.QLabel.new(self)
    boatIcon:setPixmap(QtGui.QPixmap('images/boat.png'))
    boatIcon:move(10, 10)
    boatIcon:show()
    boatIcon:setAttribute(QtCore.WA_DeleteOnClose)

    local carIcon = QtWidgets.QLabel.new(self)
    carIcon:setPixmap(QtGui.QPixmap('images/car.png'))
    carIcon:move(100, 10)
    carIcon:show()
    carIcon:setAttribute(QtCore.WA_DeleteOnClose)

    local houseIcon = QtWidgets.QLabel.new(self)
    houseIcon:setPixmap(QtGui.QPixmap('images/house.png'))
    houseIcon:move(10, 80)
    houseIcon:show()
    houseIcon:setAttribute(QtCore.WA_DeleteOnClose)
end

function Class:dragEnterEvent(event)
    -- print('function Class:dragEnterEvent(event)')
    if event:mimeData():hasFormat('application/x-dnditemdata') then
        if event:source() == self then
            event:setDropAction(QtCore.MoveAction)
            event:accept()
        else
            event:acceptProposedAction()
        end
    else
        event:ignore()
    end
end

function Class:dragMoveEvent(event)
    -- print('function Class:dragMoveEvent(event)')
    if event:mimeData():hasFormat('application/x-dnditemdata') then
        if event:source() == self then
            event:setDropAction(QtCore.MoveAction)
            event:accept()
        else
            event:acceptProposedAction()
        end
    else
        event:ignore()
    end
end

function Class:dropEvent(event)
    -- print('function Class:dropEvent(event)')
    if event:mimeData():hasFormat('application/x-dnditemdata') then
        local mimeData = event:mimeData()
        local itemData = mimeData:data('application/x-dnditemdata')
        local dataStream = QtCore.QDataStream(itemData, QtCore.QIODevice.ReadOnly)

        local pixmap = QtGui.QPixmap()
        local offset = QtCore.QPoint()

        -- dataStream >> pixmap >> offset
        QtGui.OUT(dataStream, pixmap)
        QtCore.OUT(dataStream, offset)

        local newIcon = QtWidgets.QLabel(self)
        newIcon:setPixmap(pixmap)
        newIcon:move(event:pos() - offset)
        newIcon:show()
        newIcon:setAttribute(QtCore.WA_DeleteOnClose)

        if event:source() == self then
            event:setDropAction(QtCore.MoveAction)
            event:accept()
        else
            event:acceptProposedAction()
        end
    else
        event:ignore()
    end
end

function Class:mousePressEvent(event)
    local child = self:childAt(event:pos())
    if not child then
        return
    end

    local pixmap = QtGui.QPixmap(child:pixmap())

    local mimeData = QtCore.QMimeData.new()
    local itemData = QtCore.QByteArray()
    local dataStream = QtCore.QDataStream(itemData, QtCore.QIODevice.WriteOnly)

    -- dataStream << pixmap << QPoint(event:pos() - child:pos())
    QtGui.IN(dataStream, pixmap)
    QtCore.IN(dataStream
        , QtCore.QPoint(event:pos() - child:pos())
    )

    mimeData:setData('application/x-dnditemdata', itemData)

    local drag = QtGui.QDrag.new(self)
    drag:setMimeData(mimeData)
    drag:setPixmap(pixmap)
    drag:setHotSpot(event:pos() - child:pos())

    local tempPixmap = QtGui.QPixmap(pixmap)
    local painter = QtGui.QPainter()
    painter:begin(tempPixmap)
    painter:fillRect(pixmap:rect(), QtGui.QColor(127, 127, 127, 127))
    -- TODO: lqt function name(lua keyword) alias
    painter['end'](painter)

    child:setPixmap(tempPixmap)

    if drag:exec(QtCore.CopyAction + QtCore.MoveAction, QtCore.CopyAction) == 'MoveAction' then
        child:close()
    else
        child:show()
        child:setPixmap(pixmap)
    end
end

function Class:__uninit()
    print('__uninit', self)
end

return Class
