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

local WindowDragger = require 'framelesswindow.windowdragger'

local Class = QtCore.Class('FramelessWindow', QtWidgets.QWidget) {}

local CONST_DRAG_BORDER_SIZE = 15

function Class:__static_init()
    self:__addslot('setWindowTitle(QString)', self.setWindowTitle, 'public')
    self:__addslot('setWindowIcon(QIcon)', self.setWindowIcon, 'public')

    self:__addslot('on_applicationStateChanged(Qt::ApplicationState)', self.on_applicationStateChanged, 'private')
    self:__addslot('on_minimizeButton_clicked()', self.on_minimizeButton_clicked, 'private')
    self:__addslot('on_restoreButton_clicked()', self.on_restoreButton_clicked, 'private')
    self:__addslot('on_maximizeButton_clicked()', self.on_maximizeButton_clicked, 'private')
    self:__addslot('on_closeButton_clicked()', self.on_closeButton_clicked, 'private')
    self:__addslot('on_windowTitlebar_doubleClicked()', self.on_windowTitlebar_doubleClicked, 'private')
end

function Class:__init()
    local form = qSetupUi('framelesswindow/framelesswindow.ui', self, function(className, parent, name)
        className = className:toStdString()
        if className == 'WindowDragger' then
            return WindowDragger.new { parent }
        end
    end)

    self.startGeometry = QtCore.QRect()
    self.mousePressed = false
    self.dragTop = false
    self.dragLeft = false
    self.dragRight = false
    self.dragBottom = false

    self:setWindowFlags { 'FramelessWindowHint', 'WindowSystemMenuHint' }
    -- append minimize button flag in case of windows,
    -- for correct windows native handling of minimize function
    if jit.os == 'Windows' then
        local flags = self:windowFlags()
        table.insert(flags, 'WindowMinimizeButtonHint')
        self:setWindowFlags(flags)
    end
    self:setAttribute(QtCore.WA_NoSystemBackground, true)
    self:setAttribute(QtCore.WA_TranslucentBackground)

    self.ui.restoreButton:setVisible(false)

    -- shadow under window title text
    local textShadow = QtWidgets.QGraphicsDropShadowEffect.new()
    textShadow:setBlurRadius(4.0)
    textShadow:setColor(QtGui.QColor(0, 0, 0))
    textShadow:setOffset(0, 0)
    self.ui.titleText:setGraphicsEffect(textShadow)

    -- window shadow
    local windowShadow = QtWidgets.QGraphicsDropShadowEffect.new()
    windowShadow:setBlurRadius(9.0)
    windowShadow:setColor(self:palette():color('Highlight'))
    windowShadow:setOffset(0, 0)
    self.ui.windowFrame:setGraphicsEffect(windowShadow)

    QtCore.QObject.connect(qApp(), SIGNAL 'applicationStateChanged(Qt::ApplicationState)', self, SLOT 'on_applicationStateChanged(Qt::ApplicationState)')
    self.ui.minimizeButton:connect(SIGNAL 'clicked()', self, SLOT 'on_minimizeButton_clicked()')
    self.ui.restoreButton:connect(SIGNAL 'clicked()', self, SLOT 'on_restoreButton_clicked()')
    self.ui.maximizeButton:connect(SIGNAL 'clicked()', self, SLOT 'on_maximizeButton_clicked()')
    self.ui.closeButton:connect(SIGNAL 'clicked()', self, SLOT 'on_closeButton_clicked()')
    self.ui.windowTitlebar:connect(SIGNAL 'doubleClicked()', self, SLOT 'on_windowTitlebar_doubleClicked()')
    
    self:setMouseTracking(true)

    -- important to watch mouse move from all child widgets
    QtWidgets.QApplication.instance():installEventFilter(self)
end

function Class:on_restoreButton_clicked()
    self.ui.restoreButton:setVisible(false)

    self.ui.maximizeButton:setVisible(true)
    self:setWindowState(QtCore.WindowNoState)
    -- on MacOS this hack makes sure the
    -- background window is repaint correctly
    self:hide()
    self:show()
end

function Class:on_maximizeButton_clicked()
    self.ui.restoreButton:setVisible(true)
    self.ui.maximizeButton:setVisible(false)
    self:setWindowState(QtCore.WindowMaximized)
    self:showMaximized()
    self:styleWindow(true, true)
end

function Class:changeEvent(event)
    if event:type() == 'WindowStateChange' then
        if not self:isMaximized() then
            self.ui.restoreButton:setVisible(false)
            self.ui.maximizeButton:setVisible(true)
            self:styleWindow(true, false)
            event:ignore()
        else
            self.ui.restoreButton:setVisible(true)
            self.ui.maximizeButton:setVisible(false)
            self:styleWindow(true, true)
            event:ignore()
        end
    else
        event:accept()
    end
end

function Class:setContent(w)
    self.ui.windowContent:layout():addWidget(w)
end

function Class:setWindowTitle(text)
    self.ui.titleText:setText(text)
end

function Class:setWindowIcon(icon)
    self.ui.icon:setPixmap(icon:pixmap(16, 16))
end

function Class:styleWindow(active, maximized)

    local qssWindowTitlebar = ([[#windowTitlebar {
    border: 0px none palette(shadow);
    border-top-left-radius:{border}px;
    border-top-right-radius:{border}px;
    background-color:palette({palette});
    height:20px;
}]]):gsub('{palette}', active and 'shadow' or 'dark')
    :gsub('{border}', maximized and 0 or 5)

    local qssWindowFrame = ([[#windowFrame {
    border:1px solid {palette};
    border-radius:{border}px {border}px {border}px {border}px;
    background-color:palette(Window);
}]]):gsub('{palette}'
        , maximized
            and (active and 'dark' or 'shadow')
            or (active and 'palette(highlight)' or '#000000')
    )
    :gsub('{border}', maximized and 0 or 5)

    self:layout():setMargin(maximized and 0 or 15)

    self.ui.windowTitlebar:setStyleSheet(qssWindowTitlebar)
    self.ui.windowFrame:setStyleSheet(qssWindowFrame)

    local oldShadow = self.ui.windowFrame:graphicsEffect()
    if oldShadow then oldShadow:delete() end

    if not maximized then
        local windowShadow = QtWidgets.QGraphicsDropShadowEffect.new()
        windowShadow:setBlurRadius(9.0)
        windowShadow:setColor(self:palette():color(active and 'Highlight' or 'Shadow'))
        windowShadow:setOffset(0, 0)
        self.ui.windowFrame:setGraphicsEffect(windowShadow)
    else
        self.ui.windowFrame:setGraphicsEffect(nil)
    end
end

function Class:on_applicationStateChanged(state)
    self:styleWindow(state == 'ApplicationActive', self:isMaximized())
end

function Class:on_minimizeButton_clicked()
    self:setWindowState(QtCore.WindowMinimized)
end

function Class:on_closeButton_clicked()
    self:close()
end

function Class:on_windowTitlebar_doubleClicked()
    if not self:isMaximized() then
        self:on_maximizeButton_clicked()
    else
        self:on_restoreButton_clicked()
    end
end

function Class:mouseDoubleClickEvent(event)
end

function Class:updateMouseBorderHit(globalMousePos, pressed)
    for _, info in ipairs {
        { QtCore.SizeFDiagCursor, 'dragLeft,dragTop', self.leftBorderHit, self.topBorderHit },
        { QtCore.SizeBDiagCursor, 'dragRight,dragTop', self.rightBorderHit, self.topBorderHit },
        { QtCore.SizeBDiagCursor, 'dragLeft,dragBottom', self.leftBorderHit, self.bottomBorderHit },
        { QtCore.SizeVerCursor, "dragTop", self.topBorderHit },
        { QtCore.SizeHorCursor, "dragLeft", self.leftBorderHit },
        { QtCore.SizeHorCursor, "dragRight", self.rightBorderHit },
        { QtCore.SizeVerCursor, "dragBottom", self.bottomBorderHit },
    } do
        local pass = true
        for idx = 3,#info do
            local func = info[idx]
            if not func(self, globalMousePos) then
                pass = false
                break
            end
        end
        if pass then
            if pressed then
                for coord in (info[2]):gmatch('%w+') do
                    self[coord] = true
                end
            end

            self:setCursor(info[1])
            return true
        end
    end
    return false
end

function Class:setGeometry(rect)
    local geometry = self:geometry()

    -- limit size ti minimumSize
    local size = self:minimumSize()
    if rect:width() > size:width() then
        geometry:setX(rect:x())
        geometry:setWidth(rect:width())
    end

    if rect:height() > size:height() then
        geometry:setY(rect:y())
        geometry:setHeight(rect:height())
    end

    QtWidgets.QWidget.setGeometry(self, geometry)
end

function Class:checkBorderDragging(event)
    if self:isMaximized() then
        return
    end

    local globalMousePos = event:globalPos()
    if self.mousePressed then
        -- available geometry excludes taskbar
        local availGeometry = QtWidgets.QApplication.desktop():availableGeometry()
        local h = availGeometry:height()
        local w = availGeometry:width()

        if QtWidgets.QApplication.desktop():isVirtualDesktop() then
            local sz = QtWidgets.QApplication.desktop():size()
            h = sz:height()
            w = sz:width()
        end

        -- top right corner
        if self.dragTop and self.dragRight then
            local diff = globalMousePos:x() - (self.startGeometry:x() + self.startGeometry:width())
            local neww = self.startGeometry:width() + diff
            diff = globalMousePos:y() - self.startGeometry:y()
            local newy = self.startGeometry:y() + diff
            if neww > 0 and newy > 0 and newy < h - 50 then
                local newg = QtCore.QRect(self.startGeometry)
                newg:setWidth(neww)
                newg:setX(self.startGeometry:x())
                newg:setY(newy)
                self:setGeometry(newg)
            end
        -- top left corner
        elseif self.dragTop and self.dragLeft then
            local diff = globalMousePos:y() - self.startGeometry:y()
            local newy = self.startGeometry:y() + diff
            diff = globalMousePos:x() - self.startGeometry:x()
            local newx = self.startGeometry:x() + diff
            if newy > 0 and newx > 0 then
                local newg = QtCore.QRect(self.startGeometry)
                newg:setY(newy)
                newg:setX(newx)
                self:setGeometry(newg)
            end
        -- bottom right corner
        elseif self.dragBottom and self.dragLeft then
            local diff = globalMousePos:y() - (self.startGeometry:y() + self.startGeometry:height())
            local newh = self.startGeometry:height() + diff
            diff = globalMousePos:x() - self.startGeometry:x()
            local newx = self.startGeometry:x() + diff
            if newh > 0 and newx > 0 then
                local newg = QtCore.QRect(self.startGeometry)
                newg:setX(newx)
                newg:setHeight(newh)
                self:setGeometry(newg)
            end
        elseif self.dragTop then
            local diff = globalMousePos:y() - self.startGeometry:y()
            local newy = self.startGeometry:y() + diff
            if newy > 0 and newy < h - 50 then
                local newg = QtCore.QRect(self.startGeometry)
                newg:setY(newy)
                self:setGeometry(newg)
            end
        elseif self.dragLeft then
            local diff = globalMousePos:x() - self.startGeometry:x()
            local newx = self.startGeometry:x() + diff
            if newx > 0 and newx < w - 50 then
                local newg = QtCore.QRect(self.startGeometry)
                newg:setX(newx)
                self:setGeometry(newg)
            end
        elseif self.dragRight then
            local diff = globalMousePos:x() - (self.startGeometry:x() + self.startGeometry:width())
            local neww = self.startGeometry:width() + diff
            if neww > 0 then
                local newg = QtCore.QRect(self.startGeometry)
                newg:setWidth(neww)
                newg:setX(self.startGeometry:x())
                self:setGeometry(newg)
            end
        elseif self.dragBottom then
            local diff = globalMousePos:y() - (self.startGeometry:y() + self.startGeometry:height())
            local newh = self.startGeometry:height() + diff
            if newh > 0 then
                local newg = QtCore.QRect(self.startGeometry)
                newg:setHeight(newh)
                newg:setY(self.startGeometry:y())
                self:setGeometry(newg)
            end
        end
    else
        -- no mouse pressed
        if not self:updateMouseBorderHit(globalMousePos, false) then
            self.dragTop = false
            self.dragLeft = false
            self.dragRight = false
            self.dragBottom = false
            self:setCursor(QtCore.ArrowCursor)
        end
    end
end

-- pos in global virtual desktop coordinates
function Class:leftBorderHit(pos)
    local rect = self:geometry()
    return pos:x() >= rect:x() and pos:x() <= rect:x() + CONST_DRAG_BORDER_SIZE
end

function Class:rightBorderHit(pos)
    local rect = self:geometry()
    local tmp = rect:x() + rect:width()
    return pos:x() <= tmp and pos:x() >= (tmp - CONST_DRAG_BORDER_SIZE)
end

function Class:topBorderHit(pos)
    local rect = self:geometry()
    return pos:y() >= rect:y() and pos:y() <= rect:y() + CONST_DRAG_BORDER_SIZE
end

function Class:bottomBorderHit(pos)
    local rect = self:geometry()
    local tmp = rect:y() + rect:height()
    return pos:y() <= tmp and pos:y() >= (tmp - CONST_DRAG_BORDER_SIZE)
end

function Class:mousePressEvent(event)
    if self:isMaximized() then
        return
    end

    self.mousePressed = true
    self.startGeometry = self:geometry()

    local globalMousePos = self:mapToGlobal(QtCore.QPoint(event:x(), event:y()))
    self:updateMouseBorderHit(globalMousePos, true)
end

function Class:mouseReleaseEvent(event)
    if self:isMaximized() then
        return
    end

    self.mousePressed = false
    local switchBackCursorNeeded = self.dragTop or self.dragLeft or self.dragRight or self.dragBottom
    self.dragTop = false
    self.dragLeft = false
    self.dragRight = false
    self.dragBottom = false
    if switchBackCursorNeeded then
        self:setCursor(QtCore.ArrowCursor)
    end
end

function Class:eventFilter(obj, event)
    if not self:isMaximized() then
        -- check mouse move event when mouse is moved on any object
        if event:type() == 'MouseMove' then
            if QtCore.isInstanceOf(event, QtGui.QMouseEvent) then
                self:checkBorderDragging(event)
            end
        -- press is triggered only on frame window
        elseif event:type() == 'MouseButtonPress' and obj == self then
            if QtCore.isInstanceOf(event, QtGui.QMouseEvent) then
                self:mousePressEvent(event)
            end
        elseif event:type() == 'MouseButtonRelease' then
            if QtCore.isInstanceOf(event, QtGui.QMouseEvent) then
                self:mouseReleaseEvent(event)
            end
        end
    end
    return QtWidgets.QWidget.eventFilter(self, obj, event)
end

return Class
