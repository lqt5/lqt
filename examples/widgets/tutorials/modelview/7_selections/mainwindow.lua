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

local Class = QtWidgets.QMainWindow()

function Class:__static_init()
    self:__addslot('selectionChangedSlot(QItemSelection,QItemSelection)'
    	, self.selectionChangedSlot
    )
end

function Class:__init()
	self.treeView = QtWidgets.QTreeView(self)
	self:setCentralWidget(self.treeView)

	local standardModel = QtGui.QStandardItemModel.new()
	local rootNode = standardModel:invisibleRootItem()

    -- defining a couple of items
    local americaItem = QtGui.QStandardItem.new 'America'
    local mexicoItem = QtGui.QStandardItem.new 'Canada'
    local usaItem = QtGui.QStandardItem.new 'USA'
    local bostonItem = QtGui.QStandardItem.new 'Boston'
    local europeItem = QtGui.QStandardItem.new 'Europe'
    local italyItem = QtGui.QStandardItem.new 'Italy'
    local romeItem = QtGui.QStandardItem.new 'Rome'
    local veronaItem = QtGui.QStandardItem.new 'Verona'

    -- building up the hierarchy
    rootNode:appendRow(americaItem)
    rootNode:appendRow(europeItem)
    americaItem:appendRow(mexicoItem)
    americaItem:appendRow(usaItem)
    usaItem:appendRow(bostonItem)
    europeItem:appendRow(italyItem)
    italyItem:appendRow(romeItem)
    italyItem:appendRow(veronaItem)

    -- register the model
    self.treeView:setModel(standardModel)
    -- avoid gc
    self.treeView.model = standardModel

    self.treeView:expandAll()

    -- selection changes shall trigger a slot
    local selectionModel = self.treeView:selectionModel()
    self.connect(selectionModel, SIGNAL 'selectionChanged(QItemSelection,QItemSelection)'
    	, self, SLOT 'selectionChangedSlot(QItemSelection,QItemSelection)'
    )
end

function Class:selectionChangedSlot(newSelection, oldSelection)
    -- get the text of the selected item
    local index = self.treeView:selectionModel():currentIndex()
    local selectedText = index:data(QtCore.DisplayRole):toString()
    -- find out the hierarchy level of the selected item
    local hierarchyLevel = 1
    local seekRoot = index
    while seekRoot:parent() ~= QtCore.QModelIndex() do
    	seekRoot = seekRoot:parent()
    	hierarchyLevel = hierarchyLevel + 1
    end
    local showString = QtCore.QString('%1, Level %2')
    	:arg(selectedText)
    	:arg(tostring(hierarchyLevel))

    self:setWindowTitle(showString)
end

return QtCore.Class(Class)
