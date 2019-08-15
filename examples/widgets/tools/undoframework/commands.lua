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

local DiagramItem = require 'diagramitem'

local function createCommandString(item, pos)
    return tr('%1 at (%2, %3)'):arg(
        item:diagramType() == DiagramItem.DiagramType.Box and 'Box' or 'Triangle'
        , tostring(pos:x())
        , tostring(pos:y())
    )
end

local MoveCommand = QtCore.Class('MoveCommand', QtWidgets.QUndoCommand) {}

function MoveCommand:__static_init()
    self.Id = 1234
end

function MoveCommand:__init(diagramItem, oldPos)
    self.myDiagramItem = diagramItem
    self.newPos = diagramItem:pos()
    self.myOldPos = oldPos
end

function MoveCommand:id()
    return self.Id
end

function MoveCommand:undo()
    self.myDiagramItem:setPos(self.myOldPos)
    self.myDiagramItem:scene():update()
    self:setText(
        tr('Move %1'):arg(createCommandString(self.myDiagramItem, self.newPos))
    )
end

function MoveCommand:redo()
    self.myDiagramItem:setPos(self.newPos)
    self:setText(
        tr('Move %1'):arg(createCommandString(self.myDiagramItem, self.newPos))
    )
end

function MoveCommand:mergeWith(command)

    local item = command.myDiagramItem
    if self.myDiagramItem ~= item then
        return false
    end

    self.newPos = item:pos()
    self:setText(
        tr('Move %1'):arg(createCommandString(self.myDiagramItem, self.newPos))
    )

    return true
end

local DeleteCommand = QtCore.Class('DeleteCommand', QtWidgets.QUndoCommand) {}

function DeleteCommand:__init(scene)
    self.myGraphicsScene = scene
    local list = scene:selectedItems()
    list:first():setSelected(false)
    self.myDiagramItem = list:first()

    self:setText(
        tr('Delete %1'):arg(createCommandString(self.myDiagramItem, self.myDiagramItem:pos()))
    )
end

function DeleteCommand:undo()
    self.myGraphicsScene:addItem(self.myDiagramItem)
    self.myGraphicsScene:update()
end

function DeleteCommand:redo()
    self.myGraphicsScene:removeItem(self.myDiagramItem)
end

local AddCommand = QtCore.Class('AddCommand', QtWidgets.QUndoCommand) {}

function AddCommand:__static_init()
    self.itemCount = 0
end

function AddCommand:__init(addType, scene)
    self.myGraphicsScene = scene
    self.myDiagramItem = DiagramItem.new({}, addType)

    self.initialPosition = QtCore.QPointF(
        (self.itemCount * 15) % (scene:width()),
        (self.itemCount * 15) % (scene:height())
    )
    scene:update()

    AddCommand.itemCount = AddCommand.itemCount + 1

    self:setText(
        tr('Add %1'):arg(createCommandString(self.myDiagramItem, self.initialPosition))
    )
end

function AddCommand:undo()
    self.myGraphicsScene:removeItem(self.myDiagramItem)
    self.myGraphicsScene:update()
end

function AddCommand:redo()
    self.myGraphicsScene:addItem(self.myDiagramItem)
    self.myDiagramItem:setPos(self.initialPosition)
    self.myGraphicsScene:clearSelection()
    self.myGraphicsScene:update()
end

function AddCommand:__uninit()
    if self.myDiagramItem and not self.myDiagramItem:scene() then
        self.myDiagramItem:delete()
        self.myDiagramItem = false
    end
end

return {
    MoveCommand = MoveCommand,
    AddCommand = AddCommand,
    DeleteCommand = DeleteCommand,
}
