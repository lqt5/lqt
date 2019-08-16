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
local QtWidgets = require 'qtwidgets'

local Class = QtCore.Class('MainWindow', QtWidgets.QMainWindow) {}

function Class:__init()
    qSetupUi('mainwindow.ui', self)
end

return Class
