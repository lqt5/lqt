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

local Class = QtCore.QVector_float_()

function Class:__init()
    self.m_count = 0

    self:resize(2500 * 6)

    local x1 =  0.06
    local y1 = -0.14
    local x2 =  0.14
    local y2 = -0.06
    local x3 =  0.08
    local y3 =  0.00
    local x4 =  0.30
    local y4 =  0.22

    self:quad(x1, y1, x2, y2, y2, x2, y1, x1)
    self:quad(x3, y3, x4, y4, y4, x4, y3, x3)

    self:extrude(x1, y1, x2, y2)
    self:extrude(x2, y2, y2, x2)
    self:extrude(y2, x2, y1, x1)
    self:extrude(y1, x1, x1, y1)
    self:extrude(x3, y3, x4, y4)
    self:extrude(x4, y4, y4, x4)
    self:extrude(y4, x4, y3, x3)

    local NumSectors = 100

    for i = 0,NumSectors - 1 do
    	local angle = (i * 2 * math.pi) / NumSectors
        local angleSin = math.sin(angle)
        local angleCos = math.cos(angle)
		local x5 = 0.30 * angleSin
        local y5 = 0.30 * angleCos
    	local x6 = 0.20 * angleSin
    	local y6 = 0.20 * angleCos

        angle = ((i + 1) * 2 * math.pi) / NumSectors
        angleSin = math.sin(angle)
        angleCos = math.cos(angle)
        local x7 = 0.20 * angleSin
    	local y7 = 0.20 * angleCos
    	local x8 = 0.30 * angleSin
    	local y8 = 0.30 * angleCos

        self:quad(x5, y5, x6, y6, x7, y7, x8, y8)

        self:extrude(x6, y6, x7, y7)
        self:extrude(x8, y8, x5, y5)
    end
end

function Class:count()
	return self.m_count
end

function Class:vertexCount()
	return math.floor(self.m_count / 6)
end

function Class:add(v, n)
	local index = self.m_count
	self:replace(index + 0, v:x())
	self:replace(index + 1, v:y())
	self:replace(index + 2, v:z())
	self:replace(index + 3, n:x())
	self:replace(index + 4, n:y())
	self:replace(index + 5, n:z())
	self.m_count = self.m_count + 6
end

function Class:quad(x1, y1, x2, y2, x3, y3, x4, y4)
	local n = QtGui.QVector3D.normal(
		QtGui.QVector3D(x4 - x1, y4 - y1, 0.0),
		QtGui.QVector3D(x2 - x1, y2 - y1, 0.0)
	)

    self:add(QtGui.QVector3D(x1, y1, -0.05), n)
    self:add(QtGui.QVector3D(x4, y4, -0.05), n)
    self:add(QtGui.QVector3D(x2, y2, -0.05), n)

    self:add(QtGui.QVector3D(x3, y3, -0.05), n)
    self:add(QtGui.QVector3D(x2, y2, -0.05), n)
    self:add(QtGui.QVector3D(x4, y4, -0.05), n)

    n = QtGui.QVector3D.normal(
		QtGui.QVector3D(x1 - x4, y1 - y4, 0.0),
		QtGui.QVector3D(x2 - x4, y2 - y4, 0.0)
	)

    self:add(QtGui.QVector3D(x4, y4, 0.05), n)
    self:add(QtGui.QVector3D(x1, y1, 0.05), n)
    self:add(QtGui.QVector3D(x2, y2, 0.05), n)

    self:add(QtGui.QVector3D(x2, y2, 0.05), n)
    self:add(QtGui.QVector3D(x3, y3, 0.05), n)
    self:add(QtGui.QVector3D(x4, y4, 0.05), n)
end

function Class:extrude(x1, y1, x2, y2)
	local n = QtGui.QVector3D.normal(
		QtGui.QVector3D(0.0, 0.0, -0.1),
		QtGui.QVector3D(x2 - x1, y2 - y1, 0.0)
	)

    self:add(QtGui.QVector3D(x1, y1,  0.05), n)
    self:add(QtGui.QVector3D(x1, y1, -0.05), n)
    self:add(QtGui.QVector3D(x2, y2,  0.05), n)

    self:add(QtGui.QVector3D(x2, y2, -0.05), n)
    self:add(QtGui.QVector3D(x2, y2,  0.05), n)
    self:add(QtGui.QVector3D(x1, y1, -0.05), n)
end

return QtCore.Class(Class)
