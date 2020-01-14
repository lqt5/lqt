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
local QtWidgets = require 'qtwidgets'

local GLWidget = require 'glwidget'

local Class = QtCore.Class('Window', QtWidgets.QWidget) {}

function Class:__static_init()
    self:__addslot('dockUndock()', self.dockUndock, 'private')
end

function Class:__init(mw)
    self.mainWindow = mw

    self.glWidget = GLWidget.new()

    self.xSlider = self:createSlider()
    self.ySlider = self:createSlider()
    self.zSlider = self:createSlider()

    self.connect(self.xSlider, SIGNAL 'valueChanged(int)', self.glWidget, SLOT 'setXRotation(int)')
    self.connect(self.glWidget, SIGNAL 'xRotationChanged(int)', self.xSlider, SLOT 'setValue(int)')
    self.connect(self.ySlider, SIGNAL 'valueChanged(int)', self.glWidget, SLOT 'setYRotation(int)')
    self.connect(self.glWidget, SIGNAL 'yRotationChanged(int)', self.ySlider, SLOT 'setValue(int)')
    self.connect(self.zSlider, SIGNAL 'valueChanged(int)', self.glWidget, SLOT 'setZRotation(int)')
    self.connect(self.glWidget, SIGNAL 'zRotationChanged(int)', self.zSlider, SLOT 'setValue(int)')

    local mainLayout = QtWidgets.QVBoxLayout.new()
    local container = QtWidgets.QHBoxLayout.new()
    container:addWidget(self.glWidget)
    container:addWidget(self.xSlider)
    container:addWidget(self.ySlider)
    container:addWidget(self.zSlider)

    local w = QtWidgets.QWidget.new()
    w:setLayout(container)
    mainLayout:addWidget(w)
    self.dockBtn = QtWidgets.QPushButton.new(tr 'Unlock', self)
    self.connect(self.dockBtn, SIGNAL 'clicked()', self, SLOT 'dockUndock()')
    mainLayout:addWidget(self.dockBtn)

    self:setLayout(mainLayout)

    self.xSlider:setValue(15 * 16)
    self.ySlider:setValue(345 * 16)
    self.zSlider:setValue(0 * 16)

    self:setWindowTitle(tr 'Hello GL')

    -- set focus policy to grab key event
    self:setFocusPolicy(QtCore.StrongFocus)
end

function Class:keyPressEvent(event)
    if event:key() == QtCore.Key_Escape then
        self:setParent(nil)
        self:setAttribute(QtCore.WA_DeleteOnClose)
        self:close()
    else
        QtWidgets.QWidget.keyPressEvent(self, event)
    end
end

function Class:dockUndock()
    if self:parent() ~= nil then
        self:setParent(nil)
        self:setAttribute(QtCore.WA_DeleteOnClose)
        self:move(math.floor(QtWidgets.QApplication.desktop():width() / 2 - self:width() / 2)
            , math.floor(QtWidgets.QApplication.desktop():height() / 2 - self:height() / 2)
        )
        self.dockBtn:setText(tr 'Dock')
        self:show()
    elseif not self.mainWindow:centralWidget() then
        if self.mainWindow:isVisible() then
            self:setAttribute(QtCore.WA_DeleteOnClose, false)
            self.dockBtn:setText(tr 'Undock')
            self.mainWindow:setCentralWidget(self)
        else
            QtWidgets.QMessageBox.information(self
                , tr 'Cannot dock'
                , tr 'Main window already closed'
            )
        end
    else
        QtWidgets.QMessageBox.information(self
            , tr 'Cannot dock'
            , tr 'Main window already occupied'
        )
    end
end

function Class:createSlider()
    local slider = QtWidgets.QSlider.new(QtCore.Vertical)
    slider:setRange(0, 360 * 16)
    slider:setSingleStep(16)
    slider:setPageStep(15 * 16)
    slider:setTickInterval(15 * 16)
    slider:setTickPosition(QtWidgets.QSlider.TicksRight)
    return slider
end

return Class
