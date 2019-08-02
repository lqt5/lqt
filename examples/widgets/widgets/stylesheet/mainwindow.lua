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
-- local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

local StyleSheetEditor = require 'stylesheeteditor'

local Class = QtWidgets.QMainWindow()

function Class:__static_init()
    self:__addslot('on_editStyleAction_triggered()', self.on_editStyleAction_triggered)
    self:__addslot('on_aboutAction_triggered()', self.on_aboutAction_triggered)
end

function Class:__init()
    qSetupUi('mainwindow.ui', self)

    self.ui.nameLabel:setProperty('class', QtCore.QVariant 'mandatory QLabel')

    self.styleSheetEditor = StyleSheetEditor.new()-- { self }

    self:statusBar():addWidget(QtWidgets.QLabel.new(tr 'Ready'))

    self.connect(self.ui.exitAction, SIGNAL 'triggered()', qApp(), SLOT 'quit()')
    self.connect(self.ui.aboutQtAction, SIGNAL 'triggered()', qApp(), SLOT 'aboutQt()')

    self:setWindowTitle(tr 'Style sheet')
end

function Class:on_editStyleAction_triggered()
    self.styleSheetEditor:show()
    self.styleSheetEditor:activateWindow()
end

function Class:on_aboutAction_triggered()
    QtWidgets.QMessageBox.about(self
        , tr 'About Style sheet'
        , tr [[The <b>Style Sheet</b> example shows how widgets can be styled using <a href=\"http://doc.qt.io/qt-5/stylesheet.html\">Qt Style Sheets</a>. Click <b>File|Edit Style Sheet</b> to pop up the style editor, and either choose an existing style sheet or design your own.]]
    )
end

return QtCore.Class(Class)
