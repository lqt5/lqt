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
    local file = QtCore.QFile('calculatorform.ui')
    file:open(QtCore.QIODevice.ReadOnly)

    local loader = QtUiTools.QUiLoader()
    return loader:load(file, parent)
end

local Class = QtWidgets.QWidget()

function Class:__static_init()
    self:__addslot('on_inputSpinBox1_valueChanged(int)', self.on_inputSpinBox1_valueChanged)
    self:__addslot('on_inputSpinBox2_valueChanged(int)', self.on_inputSpinBox2_valueChanged)
end

function Class:__init()
    local formWidget = loadUiFile(self)

    for name,child in pairs(formWidget:children()) do
        local key = string.format('ui_%s', name)
        print(key, child)
        self[key] = child
    end

    QtCore.QMetaObject.connectSlotsByName(self)

    local layout = QtWidgets.QHBoxLayout.new()
    layout:addWidget(formWidget)
    self:setLayout(layout)
end

function Class:on_inputSpinBox1_valueChanged(value)
    self.ui_outputWidget:setText(tostring(value + self.ui_inputSpinBox2:value()))
end

function Class:on_inputSpinBox2_valueChanged(value)
    self.ui_outputWidget:setText(QtCore.QString.number(value + self.ui_inputSpinBox1:value()))
end

return Class
