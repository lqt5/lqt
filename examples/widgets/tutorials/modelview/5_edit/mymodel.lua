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

local Class = QtCore.Class('MyModel', QtCore.QAbstractTableModel) {}

local ROWS = 2
local COLS = 3

function Class:__static_init()
    self:__addsignal('editCompleted(QString)')
end

function Class:__init()
    -- holds text entered into QTableView
    local gridData = {}
    for row = 1,ROWS do
        gridData[row] = {}
        for col = 1,COLS do
            gridData[row][col] = ''
        end
    end
    self.m_gridData = gridData
end

function Class:parent()
    return QtCore.QModelIndex()
end

function Class:rowCount(parent)
    return ROWS
end

function Class:columnCount(parent)
    return COLS
end

function Class:data(index, role)
    local row = index:row()
    local col = index:column()

    local function data()
        if role == QtCore.DisplayRole then
            return self.m_gridData[row + 1][col + 1]
        end
    end

    local val = QtCore.QVariant()
    val:setValue(data())
    return val
end

function Class:setData(index, value, role)
    if role == QtCore.EditRole then
        -- save value from editor to member m_gridData
        self.m_gridData[index:row() + 1][index:column() + 1] = value:toString():toStdString()
        -- for presentation purposes only: build and emit a joined string
        local results = {}
        for _,rows in ipairs(self.m_gridData) do
            for _,val in ipairs(rows) do
                table.insert(results, val)
            end
        end
        results = table.concat(results, ' ')

        self:__emit('editCompleted', results)
        -- self:__emit('editCompleted', QtCore.QString(results))
    end
    return true
end

function Class:flags(index)
    local flags = QtCore.QAbstractTableModel.flags(self, index)
    table.insert(flags, 'ItemIsEditable')
    return flags
end

return Class
