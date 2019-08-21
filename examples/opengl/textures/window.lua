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

local GLWidget = require 'glwidget'

local Class = QtCore.Class('Window', QtWidgets.QWidget) {}

local Consts = { NumRows = 2, NumColumns = 3 }

function Class:__static_init()
    self:__addslot('setCurrentGlWidget()', self.setCurrentGlWidget, 'private')
    self:__addslot('rotateOneStep()', self.rotateOneStep, 'private')
end

function Class:__init()
    local mainLayout = QtWidgets.QGridLayout.new()

    local glWidgets = {}
    for i = 0,Consts.NumRows - 1 do
        glWidgets[i] = {}
        for j = 0,Consts.NumColumns - 1 do
            local clearColor = QtGui.QColor()
            clearColor:setHsv(((i * Consts.NumColumns) + j) * 255 / (Consts.NumRows * Consts.NumColumns - 1), 255, 63)

            glWidgets[i][j] = GLWidget.new()
            glWidgets[i][j]:setClearColor(clearColor)
            glWidgets[i][j]:rotateBy(42 * 16, 42 * 16, -21 * 16);
            mainLayout:addWidget(glWidgets[i][j], i, j)

            self.connect(glWidgets[i][j], SIGNAL 'clicked()', self, SLOT 'setCurrentGlWidget()')
        end
    end
    self.glWidgets = glWidgets

    self:setLayout(mainLayout)

    self.currentGlWidget = glWidgets[0][0];

    local timer = QtCore.QTimer(self)
    self.connect(timer, SIGNAL 'timeout()', self, SLOT 'rotateOneStep()')
    timer:start(20)

    self:setWindowTitle(tr 'Textures')
end

function Class:setCurrentGlWidget()
    self.currentGlWidget = self:sender()
end

function Class:rotateOneStep()
    if self.currentGlWidget then
        self.currentGlWidget:rotateBy(2 * 16, 2 * 16, -1 * 16)
    end
end

return Class
