#!/usr/bin/luajit
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
dofile(arg[0]:gsub('examples/.+', 'examples/init.lua'))

local QtCore = require 'qtcore'
local QtWidgets = require 'qtwidgets'

local app = QtWidgets.QApplication(1 + select('#', ...), {arg[0], ...})

local AddressBook = QtWidgets.QWidget()

function AddressBook:__init()
    self:__addslot('addContact()', self.addContact)
    self:__addslot('submitContact()', self.submitContact)
    self:__addslot('cancel()', self.cancel)
    self:__addslot('next()', self.next)
    self:__addslot('previous()', self.previous)

    self.contacts = { index = 1 }

    local nameLabel = QtWidgets.QLabel.new(tr 'Name:')
    self.nameLine = QtWidgets.QLineEdit.new()
    self.nameLine:setReadOnly(true)

    local addressLabel = QtWidgets.QLabel.new(tr 'Address:')
    self.addressText = QtWidgets.QTextEdit.new()
    self.addressText:setReadOnly(true)

    self.addButton = QtWidgets.QPushButton.new(tr '&Add')
    self.addButton:show()
    self.submitButton = QtWidgets.QPushButton.new(tr '&Submit')
    self.submitButton:hide()
    self.cancelButton = QtWidgets.QPushButton.new(tr '&Cancel')
    self.cancelButton:hide()
--! [navigation pushbuttons]
    self.nextButton = QtWidgets.QPushButton.new(tr '&Next')
    self.nextButton:setEnabled(false)
    self.previousButton = QtWidgets.QPushButton.new(tr '&Previous')
    self.previousButton:setEnabled(false)
--! [navigation pushbuttons]

    self.connect(self.addButton, SIGNAL 'clicked()', self, SLOT 'addContact()')
    self.connect(self.submitButton, SIGNAL 'clicked()', self, SLOT 'submitContact()')
    self.connect(self.cancelButton, SIGNAL 'clicked()', self, SLOT 'cancel()')
--! [connecting navigation signals]
    self.connect(self.nextButton, SIGNAL 'clicked()', self, SLOT 'next()')
    self.connect(self.previousButton, SIGNAL 'clicked()', self, SLOT 'previous()')
--! [connecting navigation signals]

    local buttonLayout1 = QtWidgets.QVBoxLayout.new()
    buttonLayout1:addWidget(self.addButton, QtCore.AlignTop)
    buttonLayout1:addWidget(self.submitButton)
    buttonLayout1:addWidget(self.cancelButton)
    buttonLayout1:addStretch()
--! [navigation layout]
    local buttonLayout2 = QtWidgets.QHBoxLayout.new()
    buttonLayout2:addWidget(self.previousButton)
    buttonLayout2:addWidget(self.nextButton)
--! [ navigation layout]

    local mainLayout = QtWidgets.QGridLayout.new()
    mainLayout:addWidget(nameLabel, 0, 0)
    mainLayout:addWidget(self.nameLine, 0, 1)
    mainLayout:addWidget(addressLabel, 1, 0, QtCore.AlignTop)
    mainLayout:addWidget(self.addressText, 1, 1)
    mainLayout:addLayout(buttonLayout1, 1, 2)
--! [adding navigation layout]
    mainLayout:addLayout(buttonLayout2, 2, 1)
--! [adding navigation layout]

    self:setLayout(mainLayout)
    self:setWindowTitle(tr 'Simple Address Book')
end

function AddressBook:addContact()
    self.oldName = self.nameLine:text()
    self.oldAddress = self.addressText:toPlainText()

    self.nameLine:clear()
    self.addressText:clear()

    self.nameLine:setReadOnly(false)
    self.nameLine:setFocus(QtCore.OtherFocusReason)
    self.addressText:setReadOnly(false)

    self.addButton:setEnabled(false)
--! [disabling navigation]
    self.nextButton:setEnabled(false)
    self.previousButton:setEnabled(false)
--! [disabling navigation]
    self.submitButton:show()
    self.cancelButton:show()
end

function AddressBook:_addContact(name, address)
    for _,info in ipairs(self.contacts) do
        if info.name == name then
            return false
        end
    end
    table.insert(self.contacts, {
        name = name,
        address = address,
    })
    self.contacts.index = #self.contacts

    return true
end

function AddressBook:submitContact()
    local name = self.nameLine:text()
        :toStdString()
    local address = self.addressText:toPlainText()
        :toStdString()

    if #name == 0 or #address == 0 then
        return QtWidgets.QMessageBox.information(self
            , tr 'Empty Field'
            , tr 'Please enter a name and address.'
        )
    end

    if self:_addContact(name, address) then
        QtWidgets.QMessageBox.information(self
            , tr 'Add Successful'
            , tr('\'%1\' has been added to your address book.'):arg(name)
        )
    else
        return QtWidgets.QMessageBox.information(self
            , tr 'Add Successful'
            , tr('Sorry, \'%1\' is already in your address book.'):arg(name)
        )
    end

    if not next(self.contacts) then
        self.nameLine:clear()
        self.addressText:clear()
    end

    self.nameLine:setReadOnly(true)
    self.addressText:setReadOnly(true)
    self.addButton:setEnabled(true)
--! [enabling navigation]
    local number = 0
    for _,_ in ipairs(self.contacts) do
        number = number + 1
    end
    self.nextButton:setEnabled(number > 1)
    self.previousButton:setEnabled(number > 1)
--! [enabling navigation]
    self.submitButton:hide()
    self.cancelButton:hide()
end

function AddressBook:cancel()
    self.nameLine:setText(self.oldName)
    self.nameLine:setReadOnly(true)

    self.addressText:setText(self.oldAddress)
    self.addressText:setReadOnly(true)

    self.addButton:setEnabled(true)
    self.submitButton:hide()
    self.cancelButton:hide()
end
--! [next() function]
function AddressBook:next()
    local index = self.contacts.index
    if index < #self.contacts then
        index = index + 1
    else
        index = 1
    end
    self.contacts.index = index

    local info = self.contacts[index]
    self.nameLine:setText(info.name)
    self.addressText:setText(info.address)
end
--! [next() function]
--! [previous() function]
function AddressBook:previous()
    local index = self.contacts.index
    if index > 1 then
        index = index - 1
    else
        index = #self.contacts
    end
    self.contacts.index = index

    local info = self.contacts[index]
    self.nameLine:setText(info.name)
    self.addressText:setText(info.address)
end
--! [previous() function]
AddressBook = QtCore.Class(AddressBook)

local addressBook = AddressBook()
addressBook:show()

gc()

app.exec()
