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
-- local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'
local QtUiTools = require 'qtuitools'

local Class = QtCore.Class('StyleSheetEditor', QtWidgets.QDialog) {}

function Class:__static_init()
    self:__addslot('on_styleCombo_activated(QString)', self.on_styleCombo_activated)
    self:__addslot('on_styleSheetCombo_activated(QString)', self.on_styleSheetCombo_activated)
    self:__addslot('on_styleTextEdit_textChanged()', self.on_styleTextEdit_textChanged)
    self:__addslot('on_applyButton_clicked()', self.on_applyButton_clicked)
end

function Class:__init()
    qSetupUi('stylesheeteditor.ui', self)
    -- self:setModal(true)

    local regExp = QtCore.QRegularExpression '^.(.*)\\+?Style$'
    local defaultStyle = QtWidgets.QApplication.style():metaObject():className()
    local match = regExp:match(defaultStyle)

    if match:hasMatch() then
    	defaultStyle = match:captured(1)
    end

    self.ui.styleCombo:addItems(QtWidgets.QStyleFactory.keys())
    self.ui.styleCombo:setCurrentIndex(self.ui.styleCombo:findText(defaultStyle, QtCore.MatchContains))
    self.ui.styleSheetCombo:setCurrentIndex(self.ui.styleSheetCombo:findText('Coffee'))
    self:loadStyleSheet 'Coffee'
end

function Class:on_styleCombo_activated(styleName)
	qApp().setStyle(styleName)
	self.ui.applyButton:setEnabled(false)
end

function Class:on_styleSheetCombo_activated(sheetName)
    self:loadStyleSheet(sheetName);
	self.ui.applyButton:setEnabled(true)
end

function Class:on_styleTextEdit_textChanged()
	self.ui.applyButton:setEnabled(true)
end

function Class:on_applyButton_clicked()
	qApp():setStyleSheet(ui.styleTextEdit:toPlainText())
	self.ui.applyButton:setEnabled(false)
end

function Class:loadStyleSheet(sheetName)
	local file = QtCore.QFile(QtCore.QString('qss/%1.qss'):arg(sheetName))
	file:open(QtCore.QIODevice.ReadOnly)
	local styleSheet = QtCore.QString.fromLatin1(file:readAll())

	self.ui.styleTextEdit:setPlainText(styleSheet)
	qApp():setStyleSheet(styleSheet)
	self.ui.applyButton:setEnabled(false)
end

return Class
