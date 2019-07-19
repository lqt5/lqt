#!/usr/bin/luajit
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
dofile(arg[0]:gsub('examples/.+', 'examples/init.lua'))

local QtCore = require 'qtcore'
local QtWidgets = require 'qtwidgets'

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

local AddressBook = QtWidgets.QWidget()

function AddressBook:__init()
    self:__addslot('addContact()', self.addContact)
    self:__addslot('submitContact()', self.submitContact)
    self:__addslot('cancel()', self.cancel)
    self.contacts = {}

    local nameLabel = QtWidgets.QLabel.new(self.tr 'Name:')
    self.nameLine = QtWidgets.QLineEdit.new()
--! [setting readonly 1]
    self.nameLine:setReadOnly(true)
--! [setting readonly 1]

    local addressLabel = QtWidgets.QLabel.new(self.tr 'Address:')
    self.addressText = QtWidgets.QTextEdit.new()
--! [setting readonly 2]
    self.addressText:setReadOnly(true)
--! [setting readonly 2]

--! [pushbutton declaration]
    self.addButton = QtWidgets.QPushButton.new(self.tr '&Add')
    self.addButton:show()
    self.submitButton = QtWidgets.QPushButton.new(self.tr '&Submit')
    self.submitButton:hide()
    self.cancelButton = QtWidgets.QPushButton.new(self.tr '&Cancel')
    self.cancelButton:hide()
--! [pushbutton declaration]

--! [connecting signals and slots]
    self.connect(self.addButton, SIGNAL 'clicked()', self, SLOT 'addContact()')
    self.connect(self.submitButton, SIGNAL 'clicked()', self, SLOT 'submitContact()')
    self.connect(self.cancelButton, SIGNAL 'clicked()', self, SLOT 'cancel()')
--! [connecting signals and slots]

--! [vertical layout]
    local buttonLayout1 = QtWidgets.QVBoxLayout.new()
    buttonLayout1:addWidget(self.addButton, QtCore.AlignTop)
    buttonLayout1:addWidget(self.submitButton)
    buttonLayout1:addWidget(self.cancelButton)
    buttonLayout1:addStretch()
--! [vertical layout]

--! [grid layout]
    local mainLayout = QtWidgets.QGridLayout.new()
    mainLayout:addWidget(nameLabel, 0, 0)
    mainLayout:addWidget(self.nameLine, 0, 1)
    mainLayout:addWidget(addressLabel, 1, 0, QtCore.AlignTop)
    mainLayout:addWidget(self.addressText, 1, 1)
    mainLayout:addLayout(buttonLayout1, 1, 2)
--! [grid layout]

    self:setLayout(mainLayout)
    self:setWindowTitle(self.tr 'Simple Address Book')
end
--! [addContact]
function AddressBook:addContact()
    self.oldName = self.nameLine:text()
    self.oldAddress = self.addressText:toPlainText()

    self.nameLine:clear()
    self.addressText:clear()

    self.nameLine:setReadOnly(false)
    self.nameLine:setFocus(QtCore.OtherFocusReason)
    self.addressText:setReadOnly(false)

    self.addButton:setEnabled(false)
    self.submitButton:show()
    self.cancelButton:show()
end
--! [addContact]

--! [submitContact part1]
function AddressBook:submitContact()
    local name = self.nameLine:text()
        :toStdString()
    local address = self.addressText:toPlainText()
        :toStdString()

    if #name == 0 or #address == 0 then
        return QtWidgets.QMessageBox.information(self
            , self.tr 'Empty Field'
            , self.tr 'Please enter a name and address.'
        )
    end
--! [submitContact part1]
--! [submitContact part2]
    if not self.contacts[name] then
        self.contacts[name] = address

        QtWidgets.QMessageBox.information(self
            , self.tr 'Add Successful'
            , self.tr('\'%1\' has been added to your address book.'):arg(name)
        )
    else
        return QtWidgets.QMessageBox.information(self
            , self.tr 'Add Successful'
            , self.tr('Sorry, \'%1\' is already in your address book.'):arg(name)
        )
    end
--! [submitContact part2]
--! [submitContact part3]
    if not next(self.contacts) then
        self.nameLine:clear()
        self.addressText:clear()
    end

    self.nameLine:setReadOnly(true)
    self.addressText:setReadOnly(true)
    self.addButton:setEnabled(true)
    self.submitButton:hide()
    self.cancelButton:hide()
end
--! [submitContact part3]
--! [cancel]
function AddressBook:cancel()
    self.nameLine:setText(self.oldName)
    self.nameLine:setReadOnly(true)

    self.addressText:setText(self.oldAddress)
    self.addressText:setReadOnly(true)

    self.addButton:setEnabled(true)
    self.submitButton:hide()
    self.cancelButton:hide()
end
--! [cancel]
AddressBook = AddressBook:class()

local addressBook = AddressBook()
addressBook:show()

gc()

app.exec()
