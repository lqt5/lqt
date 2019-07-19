--[[*************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https:--www.qt.io/licensing/
**
** self file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use self file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https:--www.qt.io/terms-conditions. For further
** information use the contact form at https:--www.qt.io/contact-us.
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
local QtUiTools = require 'qtuitools'

local function loadUiFile(parent)
    local file = QtCore.QFile('forms/textfinder.ui')
    file:open(QtCore.QIODevice.ReadOnly)

    local loader = QtUiTools.QUiLoader()
    return loader:load(file, parent)
end

local function loadTextFile()
    local inputFile = QtCore.QFile('forms/input.txt')
    inputFile:open(QtCore.QIODevice.ReadOnly)
    local ins = QtCore.QTextStream(inputFile)
    ins:setCodec('UTF-8')
    return ins:readAll()
end

local Class = QtWidgets.QWidget()

function Class:__static_init()
    self:__addslot('on_findButton_clicked()', self.on_findButton_clicked)
end

function Class:__init()
    local formWidget = loadUiFile(self)

    for name,child in pairs(formWidget:children()) do
        local key = string.format('ui_%s', name)
        self[key] = child
    end

    -- self.ui_findButton = self:findChild('findButton')
    -- self.ui_textEdit = self:findChild('textEdit')
    -- self.ui_lineEdit = self:findChild('lineEdit')

    QtCore.QMetaObject.connectSlotsByName(self)

    self.ui_textEdit:setText(loadTextFile())


    local layout = QtWidgets.QVBoxLayout.new()
    layout:addWidget(formWidget)
    self:setLayout(layout)

    self:setWindowTitle(tr 'Text Finder')
end

function Class:on_findButton_clicked()
    local searchString = self.ui_lineEdit:text()
    local document = self.ui_textEdit:document()

    local found = false

    -- undo previous change (if any)
    document:undo()

    if searchString:isEmpty() then
        QtWidgets.QMessageBox.information(self
            , tr 'Empty Search Field'
            , tr 'Please enter a word and click Find.'
        )
        return
    end

    local highlightCursor = QtGui.QTextCursor(document)
    local cursor = QtGui.QTextCursor(document)

    cursor:beginEditBlock()

    local plainFormat = highlightCursor:charFormat()
    local colorFormat = plainFormat

    colorFormat:setForeground(QtGui.QBrush('red', 'SolidPattern'))

    while not highlightCursor:isNull() and not highlightCursor:atEnd() do
        highlightCursor = document:find(searchString
            , highlightCursor
            , QtWidgets.QTextDocument.FindWholeWords
        )

        if not highlightCursor:isNull() then
            found = true
            highlightCursor:movePosition(QtGui.QTextCursor.WordRight, QtGui.QTextCursor.KeepAnchor)
            highlightCursor:mergeCharFormat(colorFormat)
        end
    end

    cursor:endEditBlock()

    if not found then
        QtWidgets.QMessageBox.information(self
            , tr 'Word Not Found'
            , tr 'Sorry, the word cannot be found.'
        )
    end
end

return Class:class()
