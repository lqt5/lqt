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

local Class = QtCore.Class('DiagramItem', QtWidgets.QGraphicsPolygonItem) {}

function Class:__static_init()
	self.Type = QtWidgets.QGraphicsItem.UserType + 1
	self.DiagramType = { Box = 1, Triangle = 2 }
end

function Class:__init(diagramType)
    self.boxPolygon = QtGui.QPolygonF()
    self.trianglePolygon = QtGui.QPolygonF()

	if diagramType == Class.DiagramType.Box then
		self.boxPolygon
			:IN(QtCore.QPointF(0, 0))
			:IN(QtCore.QPointF(0, 30))
			:IN(QtCore.QPointF(30, 30))
			:IN(QtCore.QPointF(30, 0))
			:IN(QtCore.QPointF(0, 0))

        self:setPolygon(self.boxPolygon)
	else
		self.trianglePolygon
			:IN(QtCore.QPointF(15, 0))
			:IN(QtCore.QPointF(30, 30))
			:IN(QtCore.QPointF(0, 30))
			:IN(QtCore.QPointF(15, 0))
		self:setPolygon(self.trianglePolygon)
	end

	local color = QtGui.QColor(math.floor(QtCore.QRandomGenerator.global():bounded(256))
		, math.floor(QtCore.QRandomGenerator.global():bounded(256))
		, math.floor(QtCore.QRandomGenerator.global():bounded(256))
		, math.floor(QtCore.QRandomGenerator.global():bounded(256))
	)
	local brush = QtGui.QBrush(color)
	self:setBrush(brush)
	self:setFlag(QtWidgets.QGraphicsItem.ItemIsSelectable)
	self:setFlag(QtWidgets.QGraphicsItem.ItemIsMovable)
end

function Class:diagramType()
	return self:polygon() == self.boxPolygon and Class.DiagramType.Box or Class.DiagramType.Triangle
end

function Class:type()
	return self.Type
end

return Class
