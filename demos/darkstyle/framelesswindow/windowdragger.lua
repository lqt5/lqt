--[[###########################################################################
#                                                                             #
# The MIT License                                                             #
#                                                                             #
# Copyright (C) 2017 by Juergen Skrotzky (JorgenVikingGod@gmail.com)          #
#               >> https://github.com/Jorgen-VikingGod                        #
#                                                                             #
# Sources: https://github.com/Jorgen-VikingGod/Qt-Frameless-Window-DarkStyle  #
#                                                                             #
#############################################################################]]
local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'

local Class = QtCore.Class('WindowDragger', QtWidgets.QWidget) {}

function Class:__static_init()
    self:__addsignal('doubleClicked()')
end

function Class:__init()
    self.mousePressed = false
    self.mousePos = false
    self.wndPos = false
end

function Class:mousePressEvent(event)
    self.mousePressed = true
    self.mousePos = event:globalPos()

    local parent = self:parentWidget()
    if parent then
        parent = parent:parentWidget()
    end
    if parent then
        self.wndPos = parent:pos()
    end
end

function Class:mouseMoveEvent(event)
    local parent = self:parentWidget()
    if parent then
        parent = parent:parentWidget()
    end
    if parent and self.mousePressed then
        parent:move(self.wndPos + (event:globalPos() - self.mousePos))
    end
end

function Class:mouseReleaseEvent(event)
    self.mousePressed = false
end

function Class:paintEvent(event)
    local styleOption = QtWidgets.QStyleOption()
    styleOption:init(self)
    local painter = QtGui.QPainter(self)
    self:style():drawPrimitive(QtWidgets.QStyle.PE_Widget, styleOption, painter, self)
    painter:delete()
end

function Class:mouseDoubleClickEvent(event)
    self:__emit('doubleClicked')
end

return Class
