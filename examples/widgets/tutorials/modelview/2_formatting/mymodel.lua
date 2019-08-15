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

function Class:parent()
	return QtCore.QModelIndex()
end

function Class:rowCount(parent)
	return 2
end

function Class:columnCount(parent)
	return 3
end

function Class:data(index, role)
	local row = index:row()
	local col = index:column()

    -- generate a log message when this method gets called
    print(string.format('row %d, col%d, role %d', row, col, role))

	local function data()
	    if role == QtCore.DisplayRole then
	    	if row == 0 and col == 1 then
	    		return '<--left'
	    	elseif row == 1 and col == 1 then
	    		return 'right-->'
	    	end
		    return string.format('Row%d, Column%d', index:row() + 1, index:column() + 1)
	    elseif role == QtCore.FontRole then
	    	-- change font only for cell(0,0)
	    	if row == 0 and col == 0 then
	    		local boldFont = QtGui.QFont()
	    		boldFont:setBold(true)
	    		return boldFont
	    	end
	    elseif role == QtCore.BackgroundRole then
	    	-- change background only for cell(1,2)
	    	if row == 1 and col == 2 then
	    		local redBackground = QtGui.QBrush('red', 'SolidPattern')
	    		return redBackground
	    	end
	    elseif role == QtCore.TextAlignmentRole then
	    	-- change text alignment only for cell(1,1)
	    	if row == 1 and col == 1 then
	    		return QtCore.AlignRight
	    	end
	    elseif role == QtCore.CheckStateRole then
	    	-- add a checkbox to cell(1,0)
	    	if row == 1 and col == 0 then
	    		return QtCore.Checked
	    	end
	    end
	end

    local val = QtCore.QVariant()
    val:setValue(data())
    return val
end

return Class
