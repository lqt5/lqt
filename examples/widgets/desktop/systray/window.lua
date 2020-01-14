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

local Class = QtCore.Class('Window', QtWidgets.QDialog) {}

function Class:__static_init()
    self:__addslot('setIcon(int)', self.setIcon)
    self:__addslot('iconActivated(QSystemTrayIcon::ActivationReason)', self.iconActivated)
    self:__addslot('showMessage()', self.showMessage)
    self:__addslot('messageClicked()', self.messageClicked)
end

function Class:__init()
    self:createIconGroupBox()
    self:createMessageGroupBox()

    self.iconLabel:setMinimumWidth(self.durationLabel:sizeHint():width())

    self:createActions()
    self:createTrayIcon()

    self.connect(self.showMessageButton, SIGNAL 'clicked()', self, SLOT 'showMessage()')
    self.connect(self.showIconCheckBox, SIGNAL 'toggled(bool)', self.trayIcon, SLOT 'setVisible(bool)')
    self.connect(self.iconComboBox, SIGNAL 'currentIndexChanged(int)', self, SLOT 'setIcon(int)')
    self.connect(self.trayIcon, SIGNAL 'messageClicked()', self, SLOT 'messageClicked()')
    self.connect(self.trayIcon
        , SIGNAL 'activated(QSystemTrayIcon::ActivationReason)'
        , self
        , SLOT 'iconActivated(QSystemTrayIcon::ActivationReason)'
    )

    local mainLayout = QtWidgets.QVBoxLayout.new()
    mainLayout:addWidget(self.iconGroupBox)
    mainLayout:addWidget(self.messageGroupBox)
    self:setLayout(mainLayout)

    self.iconComboBox:setCurrentIndex(1)
    self.trayIcon:show()

    self:setWindowTitle(tr 'Systray')
    self:resize(400, 300)
end

function Class:setVisible(visible)
    self.minimizeAction:setEnabled(visible)
    self.maximizeAction:setEnabled(not self:isMaximized())
    self.restoreAction:setEnabled(self:isMaximized() or not visible)
    QtWidgets.QDialog.setVisible(self, visible)
end

function Class:closeEvent(event)
    if jit.os == 'OSX' then
        if not event:spontaneous() or not self:isVisible() then
            return
        end
    end
    if self.trayIcon:isVisible() then
        QtWidgets.QMessageBox.information(self
            , tr 'Systray'
            , tr 'The program will keep running in the system tray. To terminate the program, choose <b>Quit</b> in the context menu of the system tray entry.'
        )
        self:hide()
        event:ignore()
    end
end

function Class:setIcon(index)
    local icon = self.iconComboBox:itemIcon(index)
    self.trayIcon:setIcon(icon)
    self:setWindowIcon(icon)

    self.trayIcon:setToolTip(self.iconComboBox:itemText(index))
end

function Class:iconActivated(reason)
    if reason == 'Trigger' or reason == 'DoubleClick' then
        self.iconComboBox:setCurrentIndex(
            (self.iconComboBox:currentIndex() + 1) % self.iconComboBox:count()
        )
    elseif reason == 'MiddleClick' then
        self:showMessage()
    end
end

function Class:showMessage()
    self.showIconCheckBox:setChecked(true)
    local iconIdx = self.typeComboBox:itemData(self.typeComboBox:currentIndex()):toInt()
    local msgIcon = QtWidgets.QSystemTrayIcon.MessageIcon[iconIdx]
    if msgIcon == 'NoIcon' then
        local icon = self.iconComboBox:itemIcon(self.iconComboBox:currentIndex())
        self.trayIcon:showMessage(self.titleEdit:text()
            , self.bodyEdit:toPlainText()
            , icon
            , self.durationSpinBox:value() * 1000
        )
    else
        self.trayIcon:showMessage(self.titleEdit:text()
            , self.bodyEdit:toPlainText()
            , msgIcon
            , self.durationSpinBox:value() * 1000
        )
    end
end

function Class:messageClicked()
    QtWidgets.QMessageBox.information(nil
        , tr 'Systray'
        , tr 'Sorry, I already gave what help I could.\nMaybe you should try asking a human?'
    )
end

function Class:createIconGroupBox()
    local iconGroupBox = QtWidgets.QGroupBox.new(tr 'Tray Icon')

    local iconLabel = QtWidgets.QLabel.new(tr 'Icon:')

    local iconComboBox = QtWidgets.QComboBox.new()
    iconComboBox:addItem(QtGui.QIcon('images/bad.png'), tr 'Bad')
    iconComboBox:addItem(QtGui.QIcon('images/heart.png'), tr 'Heart')
    iconComboBox:addItem(QtGui.QIcon('images/trash.png'), tr 'Trash')

    local showIconCheckBox = QtWidgets.QCheckBox.new(tr 'Show icon')
    showIconCheckBox:setChecked(true)

    local iconLayout = QtWidgets.QHBoxLayout.new()
    iconLayout:addWidget(iconLabel)
    iconLayout:addWidget(iconComboBox)
    iconLayout:addStretch()
    iconLayout:addWidget(showIconCheckBox)
    iconGroupBox:setLayout(iconLayout)

    self.iconLabel = iconLabel
    self.showIconCheckBox = showIconCheckBox
    self.iconComboBox = iconComboBox
    self.iconGroupBox = iconGroupBox
end

function Class:createMessageGroupBox()
    local messageGroupBox = QtWidgets.QGroupBox.new(tr 'Balloon Message')

    local typeLabel = QtWidgets.QLabel.new(tr 'Type:')

    local typeComboBox = QtWidgets.QComboBox.new()
    typeComboBox:addItem(tr 'None', QtWidgets.QSystemTrayIcon.NoIcon)
    typeComboBox:addItem(self:style():standardIcon 'SP_MessageBoxInformation'
        , tr 'Information'
        , QtWidgets.QSystemTrayIcon.Information
    )
    typeComboBox:addItem(self:style():standardIcon 'SP_MessageBoxWarning'
        , tr 'Warning'
        , QtWidgets.QSystemTrayIcon.Warning
    )
    typeComboBox:addItem(self:style():standardIcon 'SP_MessageBoxCritical'
        , tr 'Critical'
        , QtWidgets.QSystemTrayIcon.Critical
    )
    typeComboBox:addItem(QtGui.QIcon()
        , tr 'Custom icon'
        , QtWidgets.QSystemTrayIcon.NoIcon
    )
    typeComboBox:setCurrentIndex(1)

    local durationLabel = QtWidgets.QLabel.new(tr 'Duration:')

    local durationSpinBox = QtWidgets.QSpinBox.new()
    durationSpinBox:setRange(5, 60)
    durationSpinBox:setSuffix ' s'
    durationSpinBox:setValue(15)

    local durationWarningLabel = QtWidgets.QLabel.new(tr '(some systems might ignore self hint)')
    durationWarningLabel:setIndent(10)

    local titleLabel = QtWidgets.QLabel.new(tr 'Title:')

    local titleEdit = QtWidgets.QLineEdit.new(tr 'Cannot connect to network')

    local bodyLabel = QtWidgets.QLabel.new(tr 'Body:')

    local bodyEdit = QtWidgets.QTextEdit.new()
    bodyEdit:setPlainText(tr 'Don\'t believe me. Honestly, I don\'t have a clue.\nClick self balloon for details.')

    local showMessageButton = QtWidgets.QPushButton.new(tr 'Show Message')
    showMessageButton:setDefault(true)

    local messageLayout = QtWidgets.QGridLayout.new()
    messageLayout:addWidget(typeLabel, 0, 0)
    messageLayout:addWidget(typeComboBox, 0, 1, 1, 2)
    messageLayout:addWidget(durationLabel, 1, 0)
    messageLayout:addWidget(durationSpinBox, 1, 1)
    messageLayout:addWidget(durationWarningLabel, 1, 2, 1, 3)
    messageLayout:addWidget(titleLabel, 2, 0)
    messageLayout:addWidget(titleEdit, 2, 1, 1, 4)
    messageLayout:addWidget(bodyLabel, 3, 0)
    messageLayout:addWidget(bodyEdit, 3, 1, 2, 4)
    messageLayout:addWidget(showMessageButton, 5, 4)
    messageLayout:setColumnStretch(3, 1)
    messageLayout:setRowStretch(4, 1)
    messageGroupBox:setLayout(messageLayout)

    self.durationLabel = durationLabel
    self.showMessageButton = showMessageButton
    self.messageGroupBox = messageGroupBox
    self.typeComboBox = typeComboBox
    self.titleEdit = titleEdit
    self.bodyEdit = bodyEdit
    self.durationSpinBox = durationSpinBox
end

function Class:createActions()
    local minimizeAction = QtWidgets.QAction.new(tr 'Mi&nimize', self)
    self.connect(minimizeAction, SIGNAL 'triggered()', self, SLOT 'hide()')

    local maximizeAction = QtWidgets.QAction.new(tr 'Ma&ximize', self)
    self.connect(maximizeAction, SIGNAL 'triggered()', self, SLOT 'showMaximized()')

    local restoreAction = QtWidgets.QAction.new(tr '&Restore', self)
    self.connect(restoreAction, SIGNAL 'triggered()', self, SLOT 'showNormal()')

    local quitAction = QtWidgets.QAction.new(tr '&Quit', self)
    self.connect(quitAction, SIGNAL 'triggered()', qApp(), SLOT 'quit()')

    self.minimizeAction = minimizeAction
    self.maximizeAction = maximizeAction
    self.restoreAction = restoreAction
    self.quitAction = quitAction
end

function Class:createTrayIcon()
    local trayIconMenu = QtWidgets.QMenu.new(self)
    trayIconMenu:addAction(self.minimizeAction)
    trayIconMenu:addAction(self.maximizeAction)
    trayIconMenu:addAction(self.restoreAction)
    trayIconMenu:addSeparator()
    trayIconMenu:addAction(self.quitAction)

    local trayIcon = QtWidgets.QSystemTrayIcon.new(self)
    trayIcon:setContextMenu(trayIconMenu)

    self.trayIcon = trayIcon
end

return Class
