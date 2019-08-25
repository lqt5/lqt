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
local QtWebChannel = require 'qtwebchannel'

local Document = require 'document'
local PreviewPage = require 'previewpage'

local Class = QtCore.Class('MainWindow', QtWidgets.QMainWindow) {}

function Class:__static_init()
    self:__addslot('onFileNew()', self.onFileNew, 'private')
    self:__addslot('onFileOpen()', self.onFileOpen, 'private')
    self:__addslot('onFileSave()', self.onFileSave, 'private')
    self:__addslot('onFileSaveAs()', self.onFileSaveAs, 'private')
    self:__addslot('onExit()', self.onExit, 'private')
end

function Class:__init()
    qSetupUi('mainwindow.ui', self)

    self.m_filePath = QtCore.QString()
    self.content = Document()

    self.ui.editor:setFont(QtGui.QFontDatabase.systemFont 'FixedFont')
    self.ui.preview:setContextMenuPolicy 'NoContextMenu'

    local page = PreviewPage.new { self }
    self.ui.preview:setPage(page)

    self.connect(self.ui.editor, SIGNAL 'textChanged()', function(_)
        self.content:setText(self.ui.editor:toPlainText())
    end)

    local channel = QtWebChannel.QWebChannel.new(self)
    channel:registerObject('content', self.content)
    page:setWebChannel(channel)

    self.ui.preview:setUrl(QtCore.QUrl 'qrc:/index.html')

    self.connect(self.ui.actionNew, SIGNAL 'triggered()', self, SLOT 'onFileNew()')
    self.connect(self.ui.actionOpen, SIGNAL 'triggered()', self, SLOT 'onFileOpen()')
    self.connect(self.ui.actionSave, SIGNAL 'triggered()', self, SLOT 'onFileSave()')
    self.connect(self.ui.actionSaveAs, SIGNAL 'triggered()', self, SLOT 'onFileSaveAs()')
    self.connect(self.ui.actionExit, SIGNAL 'triggered()', self, SLOT 'onExit()')

    self.connect(self.ui.editor:document(), SIGNAL 'modificationChanged(bool)'
        , self.ui.actionSave, SLOT 'setEnabled(bool)'
    )

    local defaultTextFile = QtCore.QFile(':/default.md')
    defaultTextFile:open(QtCore.QIODevice.ReadOnly)
    self.ui.editor:setPlainText(defaultTextFile:readAll())
end

function Class:openFile(path)
    local f = QtCore.QFile(path)
    if not f:open(QtCore.QIODevice.ReadOnly) then
        QtWidgets.QMessageBox.warning(self
            , self:windowTitle()
            , (tr 'Could not open file %1: %2'):arg(QtCore.QDir.toNativeSeparators(path), f:errorString())
        )
        return
    end
    self.m_filePath = path
    self.ui.editor:setPlainText(f:readAll())
    f:close()
end

function Class:onFileNew()
    if self:isModified() then
        local button = QtWidgets.QMessageBox.question(self
            , self:windowTitle()
            , tr 'You have unsaved changes. Do you want to create a new document anyway?'
        )
        if button ~= 'Yes' then
            return
        end
    end

    self.m_filePath:clear()
    self.ui.editor:setPlainText(tr '## New document')
    self.ui.editor:document():setModified(false)
end

function Class:onFileOpen()
    if self:isModified() then
        local button = QtWidgets.QMessageBox.question(self
            , self:windowTitle()
            , tr 'You have unsaved changes. Do you want to open a new document anyway?'
        )
        if button ~= 'Yes' then
            return
        end
    end

    local path = QtWidgets.QFileDialog.getOpenFileName(self
        , tr 'Open MarkDown File'
        , ''
        , tr 'MarkDown File (*.md *.markdown)'
    )

    if path:isEmpty() then
        return
    end

    self:openFile(path)
end

function Class:onFileSave()
    if self.m_filePath:isEmpty() then
        self:onFileSaveAs()
        return
    end

    local f = QtCore.QFile(self.m_filePath)
    if not f:open(QtCore.QIODevice.WriteOnly + QtCore.QIODevice.Text) then
        QtWidgets.QMessageBox.warning(self
            , self:windowTitle()
            , (tr 'Could not write to file %1: %2'):arg(QtCore.QDir.toNativeSeparators(path), f:errorString())
        )
        return
    end

    local str = QtCore.QTextStream(f)
    str:IN(self.ui.editor:toPlainText())
    f:close()

    self.ui.editor:document():setModified(false)
end

function Class:onFileSaveAs()
    local path = QtWidgets.QFileDialog.getSaveFileName(self
        , tr 'Save MarkDown File'
        , ''
        , tr 'MarkDown File (*.md *.markdown)'
    )

    if path:isEmpty() then
        return
    end
    self.m_filePath = path
    self:onFileSave()
end

function Class:onExit()
    if self:isModified() then
        local button = QtWidgets.QMessageBox.question(self
            , self:windowTitle()
            , tr 'You have unsaved changes. Do you want to exit anyway?'
        )
        if button ~= 'Yes' then
            return
        end
    end
    self:close()
end

function Class:isModified()
    return self.ui.editor:document():isModified()
end

return Class
