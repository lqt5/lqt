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

--! [include finddialog's header]
local FindDialog = require 'finddialog'
--! [include finddialog's header]

local AddressBook = QtCore.Class('AddressBook', QtWidgets.QWidget) {}

--! [Mode enum]
local Mode = {
    NavigationMode = 0,
    AddingMode = 1,
    EditingMode = 2,
}
--! [Mode enum]

function AddressBook:__static_init()
    self:__addslot('addContact()', self.addContact)
    self:__addslot('submitContact()', self.submitContact)
    self:__addslot('cancel()', self.cancel)
    self:__addslot('editContact()', self.editContact)
    self:__addslot('removeContact()', self.removeContact)
--! [findContact() declaration]
    self:__addslot('findContact()', self.findContact)
--! [findContact() declaration]
    self:__addslot('next()', self.next)
    self:__addslot('previous()', self.previous)
end

function AddressBook:__init()
    self.contacts = { index = 1 }
    self.currentMode = Mode.NavigationMode

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
    self.nextButton = QtWidgets.QPushButton.new(tr '&Next')
    self.nextButton:setEnabled(false)
    self.previousButton = QtWidgets.QPushButton.new(tr '&Previous')
    self.previousButton:setEnabled(false)
    self.editButton = QtWidgets.QPushButton.new(tr '&Edit')
    self.editButton:setEnabled(false)
    self.removeButton = QtWidgets.QPushButton.new(tr '&Remove')
    self.removeButton:setEnabled(false)
--! [instantiating findButton]
    self.findButton = QtWidgets.QPushButton.new(tr '&Find')
    self.findButton:setEnabled(false);
--! [instantiating findButton]

--! [instantiating FindDialog]
    self.dialog = FindDialog.new { self }
--! [instantiating FindDialog]

    self.connect(self.addButton, SIGNAL 'clicked()', self, SLOT 'addContact()')
    self.connect(self.submitButton, SIGNAL 'clicked()', self, SLOT 'submitContact()')
    self.connect(self.cancelButton, SIGNAL 'clicked()', self, SLOT 'cancel()')
    self.connect(self.editButton, SIGNAL 'clicked()', self, SLOT 'editContact()')
    self.connect(self.removeButton, SIGNAL 'clicked()', self, SLOT 'removeContact()')
--! [signals and slots for find]
    self.connect(self.findButton, SIGNAL 'clicked()', self, SLOT 'findContact()')
--! [signals and slots for find]
    self.connect(self.nextButton, SIGNAL 'clicked()', self, SLOT 'next()')
    self.connect(self.previousButton, SIGNAL 'clicked()', self, SLOT 'previous()')

    local buttonLayout1 = QtWidgets.QVBoxLayout.new()
    buttonLayout1:addWidget(self.addButton, QtCore.AlignTop)
    buttonLayout1:addWidget(self.editButton)
    buttonLayout1:addWidget(self.removeButton)
--! [adding findButton to layout]
    buttonLayout1:addWidget(self.findButton)
--! [adding findButton to layout]
    buttonLayout1:addWidget(self.submitButton)
    buttonLayout1:addWidget(self.cancelButton)
    buttonLayout1:addStretch()

    local buttonLayout2 = QtWidgets.QHBoxLayout.new()
    buttonLayout2:addWidget(self.previousButton)
    buttonLayout2:addWidget(self.nextButton)

    local mainLayout = QtWidgets.QGridLayout.new()
    mainLayout:addWidget(nameLabel, 0, 0)
    mainLayout:addWidget(self.nameLine, 0, 1)
    mainLayout:addWidget(addressLabel, 1, 0, QtCore.AlignTop)
    mainLayout:addWidget(self.addressText, 1, 1)
    mainLayout:addLayout(buttonLayout1, 1, 2)
    mainLayout:addLayout(buttonLayout2, 2, 1)

    self:setLayout(mainLayout)
    self:setWindowTitle(tr 'Simple Address Book')
end

function AddressBook:addContact()
    self.oldName = self.nameLine:text()
        :toStdString()
    self.oldAddress = self.addressText:toPlainText()
        :toStdString()

    self.nameLine:clear()
    self.addressText:clear()

    self:updateInterface(Mode.AddingMode)
end
--! [editContact() function]
function AddressBook:editContact()
    self.oldName = self.nameLine:text()
        :toStdString()
    self.oldAddress = self.addressText:toPlainText()
        :toStdString()

    self:updateInterface(Mode.EditingMode)
end
--! [editContact() function]
function AddressBook:_getContact(name)
    for idx,info in ipairs(self.contacts) do
        if info.name == name then
            return info,idx
        end
    end
    return nil
end

function AddressBook:_addContact(name, address)
    if self:_getContact(name) then
        return false
    end

    table.insert(self.contacts, {
        name = name,
        address = address,
    })
    self.contacts.index = #self.contacts

    return true
end

function AddressBook:_removeContact(name)
    for idx,info in ipairs(self.contacts) do
        if info.name == name then
            table.remove(self.contacts, idx)
            return true
        end
    end
    return false
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

    if self.currentMode == Mode.AddingMode then

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
    elseif self.currentMode == Mode.EditingMode then

        if self.oldName ~= name then
            if not self:_getContact(name) then
                QtWidgets.QMessageBox.information(self
                    , tr 'Edit Successful'
                    , tr('\'%1\' has been edited in your address book.'):arg(name)
                )
                self:_removeContact(self.oldName)
                self:_addContact(name, address)
            else
                return QtWidgets.QMessageBox.information(self
                    , tr 'Edit Unsuccessful'
                    , tr('Sorry, \'%1\' is already in your address book.'):arg(name)
                )
            end
        elseif self.oldAddress ~= address then
                QtWidgets.QMessageBox.information(self
                    , tr 'Edit Successful'
                    , tr('\'%1\' has been edited in your address book.'):arg(name)
                )
                local info = self:_getContact(name)
                info.address = address
        end
    end

    self:updateInterface(Mode.NavigationMode)
end

function AddressBook:cancel()
    self.nameLine:setText(self.oldName)
    self.addressText:setText(self.oldAddress)
    self:updateInterface(Mode.NavigationMode)
end

function AddressBook:removeContact()
    local name = self.nameLine:text()
        :toStdString()
    local address = self.addressText:toPlainText()
        :toStdString()

    if self:_getContact(name) then
        local button = QtWidgets.QMessageBox.question(self
            , tr 'Confirm Remove'
            , tr ('Are you sure you want to remove \'%1\'?'):arg(name)
            , QtWidgets.QMessageBox.Yes + QtWidgets.QMessageBox.No
        )

        if button == 'Yes' then
            self:previous()
            self:_removeContact(name)

            QtWidgets.QMessageBox.information(self
                , tr 'Remove Successful'
                , tr('\'%1\' has been removed from your address book.'):arg(name)
            )
        end
    end
    self:updateInterface(Mode.NavigationMode)
end

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

--! [findContact() function]
function AddressBook:findContact()
    self.dialog:show()

    if self.dialog:exec() == QtWidgets.QDialog.Accepted then
        local contactName = self.dialog:getFindText()

        local info,idx = self:_getContact(contactName)
        if info then
            self.nameLine:setText(contactName)
            self.addressText:setText(info.address)
            self.contacts.index = idx
        else
            return QtWidgets.QMessageBox.information(self
                , tr 'Contact Not Found'
                , (tr 'Sorry, \'%1\' is not in your address book.'):arg(contactName)
            )
        end
    end
    self:updateInterface(Mode.NavigationMode)
end
--! [findContact() function]
function AddressBook:updateInterface(mode)
    self.currentMode = mode

    if mode == Mode.AddingMode or mode == Mode.EditingMode then
        self.nameLine:setReadOnly(false)
        self.nameLine:setFocus(QtCore.OtherFocusReason)
        self.addressText:setReadOnly(false)

        self.addButton:setEnabled(false)
        self.editButton:setEnabled(false)
        self.removeButton:setEnabled(false)

        self.nextButton:setEnabled(false)
        self.previousButton:setEnabled(false)

        self.submitButton:show()
        self.cancelButton:show()

    elseif mode == Mode.NavigationMode then
        if #self.contacts == 0 then
            self.nameLine:clear()
            self.addressText:clear()
        end

        self.nameLine:setReadOnly(true)
        self.addressText:setReadOnly(true)
        self.addButton:setEnabled(true)

        local number = 0
        for _,_ in ipairs(self.contacts) do
            number = number + 1
        end
        self.editButton:setEnabled(number >= 1)
        self.removeButton:setEnabled(number >= 1)
        self.findButton:setEnabled(number > 2)
        self.nextButton:setEnabled(number > 1)
        self.previousButton:setEnabled(number >1 )

        self.submitButton:hide()
        self.cancelButton:hide()
    end
end

return AddressBook
