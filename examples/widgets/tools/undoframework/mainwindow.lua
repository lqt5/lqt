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
local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

local Commands = require 'commands'
local DiagramItem = require 'diagramitem'
local DiagramScene = require 'diagramscene'

local Class = QtCore.Class('MainWindow', QtWidgets.QMainWindow) {}

function Class:__static_init()
    self:__addslot('itemMoved(QGraphicsPolygonItem*,QPointF)', self.itemMoved)
    self:__addslot('deleteItem()', self.deleteItem, 'private')
    self:__addslot('addBox()', self.addBox, 'private')
    self:__addslot('addTriangle()', self.addTriangle, 'private')
    self:__addslot('about()', self.about, 'private')
    self:__addslot('itemMenuAboutToShow()', self.itemMenuAboutToShow, 'private')
    self:__addslot('itemMenuAboutToHide()', self.itemMenuAboutToHide, 'private')
end

function Class:__init()
    self.undoStack = QtWidgets.QUndoStack(self)

    self:createActions()
    self:createMenus()

    self:createUndoView()

    self.diagramScene = DiagramScene.new()

    local pixmapBrush = QtGui.QBrush(
        QtGui.QPixmap('./images/cross.png'):scaled(30, 30)
    )
    self.diagramScene:setBackgroundBrush(pixmapBrush)
    self.diagramScene:setSceneRect(QtCore.QRect(0, 0, 500, 500))

    self.connect(self.diagramScene, SIGNAL 'itemMoved(QGraphicsPolygonItem*,QPointF)'
        , self, SLOT 'itemMoved(QGraphicsPolygonItem*,QPointF)'
    )

    self:setWindowTitle('Undo Framework')
    local view = QtWidgets.QGraphicsView.new(self.diagramScene)
    self:setCentralWidget(view)
    self:resize(700, 500)
end

function Class:createUndoView()
    self.undoView = QtWidgets.QUndoView(self.undoStack)
    self.undoView:setWindowTitle(tr 'Command List')
    self.undoView:show()
    self.undoView:setAttribute(QtCore.WA_QuitOnClose, false)
end

function Class:createActions()
    self.deleteAction = QtWidgets.QAction(tr '&Delete Item', self)
    local deleteShortcuts = QtGui.QList_QKeySequence_()
    deleteShortcuts
        :IN(QtGui.QKeySequence(tr 'Del'))
        :IN(QtGui.QKeySequence(tr 'Ctrl+Backspace'))
    self.deleteAction:setShortcuts(deleteShortcuts)
    self.connect(self.deleteAction, SIGNAL 'triggered()', self, SLOT 'deleteItem()')

    self.addBoxAction = QtWidgets.QAction(tr 'Add &Box', self)
    self.addBoxAction:setShortcut(QtGui.QKeySequence(tr 'Ctrl+O'))
    self.connect(self.addBoxAction, SIGNAL 'triggered()', self, SLOT 'addBox()')

    self.addTriangleAction = QtWidgets.QAction(tr 'Add &Triangle', self)
    self.addTriangleAction:setShortcut(QtGui.QKeySequence(tr 'Ctrl+T'))
    self.connect(self.addTriangleAction, SIGNAL 'triggered()', self, SLOT 'addTriangle()')

    self.undoAction = self.undoStack:createUndoAction(self, tr '&Undo')
    self.undoAction:setShortcuts(QtGui.QKeySequence.Undo)

    self.redoAction = self.undoStack:createRedoAction(self, tr '&Redo')
    self.redoAction:setShortcuts(QtGui.QKeySequence.Redo)

    self.exitAction = QtWidgets.QAction(tr 'E&xit', self)
    self.exitAction:setShortcut(QtGui.QKeySequence.Quit)
    self.connect(self.exitAction, SIGNAL 'triggered()', self, SLOT 'close()')

    self.aboutAction = QtWidgets.QAction(tr '&About', self)
    local aboutShortcuts = QtGui.QList_QKeySequence_()
    aboutShortcuts
        :IN(QtGui.QKeySequence(tr 'Ctrl+A'))
        :IN(QtGui.QKeySequence(tr 'Ctrl+B'))
    self.aboutAction:setShortcuts(aboutShortcuts)
    self.connect(self.aboutAction, SIGNAL 'triggered()', self, SLOT 'about()')
end

function Class:createMenus()
    local fileMenu = self:menuBar():addMenu(tr '&File')
    fileMenu:addAction(self.exitAction)

    self.editMenu = self:menuBar():addMenu(tr '&Edit')
    self.editMenu:addAction(self.undoAction)
    self.editMenu:addAction(self.redoAction)
    self.editMenu:addSeparator()
    self.editMenu:addAction(self.deleteAction)
    self.connect(self.editMenu, SIGNAL 'aboutToShow()',
            self, SLOT 'itemMenuAboutToShow()')
    self.connect(self.editMenu, SIGNAL 'aboutToHide()',
            self, SLOT 'itemMenuAboutToHide()')

    self.itemMenu = self:menuBar():addMenu(tr '&Item')
    self.itemMenu:addAction(self.addBoxAction)
    self.itemMenu:addAction(self.addTriangleAction)

    self.helpMenu = self:menuBar():addMenu(tr '&About')
    self.helpMenu:addAction(self.aboutAction)
end

function Class:itemMoved(movedDiagram, moveStartPosition)
    self.undoStack:push(
        Commands.MoveCommand.new({}, movedDiagram, moveStartPosition)
    )
end

function Class:deleteItem()
    if self.diagramScene:selectedItems():isEmpty() then
        return
    end

    local deleteCommand = Commands.DeleteCommand.new({}
        , self.diagramScene
    )
    self.undoStack:push(deleteCommand)
end

function Class:itemMenuAboutToHide()
    self.deleteAction:setEnabled(true)
end

function Class:itemMenuAboutToShow()
    self.deleteAction:setEnabled(not self.diagramScene:selectedItems():isEmpty())
end

function Class:addBox()
    local addCommand = Commands.AddCommand.new({}
        , DiagramItem.DiagramType.Box
        , self.diagramScene
    )
    self.undoStack:push(addCommand)
end

function Class:addTriangle()
    local addCommand = Commands.AddCommand.new({}
        , DiagramItem.DiagramType.Triangle
        , self.diagramScene
    )
    self.undoStack:push(addCommand)
end

function Class:about()
    QtWidgets.QMessageBox.about(self
        , tr 'About Undo'
        , tr 'The <b>Undo</b> example demonstrates how to use Qt\'s undo framework.'
    )
end

return Class
