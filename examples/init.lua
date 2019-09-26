--------------------------------------------------------------------------------
-- get source path of 'init.lua'
--------------------------------------------------------------------------------
local function get_source_path()
	local info = debug.getinfo(1)
	return info.source:sub(2)
end
--------------------------------------------------------------------------------
-- setup cpath/luapath
--------------------------------------------------------------------------------
local dlpath = get_source_path():gsub('init.lua'
	, jit.os == 'Windows' and '../build/lib/RelWithDebInfo/?.dll' or '../build/lib/?.so'
)
package.cpath = package.cpath .. ';' .. dlpath

local luapath = table.concat({
	arg[0]:gsub('[/\\][^/^\\]*%.lua$', '/?.lua'),
	get_source_path():gsub('init.lua', '?.lua'),
}, ';')

package.path = package.path .. ';' .. luapath
--------------------------------------------------------------------------------
-- use strict to avoid undeclared global variables access
--------------------------------------------------------------------------------
require 'strict'
--------------------------------------------------------------------------------
-- reload embed script
--  for development use
--------------------------------------------------------------------------------
local QtCore = require 'qtcore'
local function reload_embed()
    for k,_ in pairs(package.preload) do
        if k:find('embed') then
            package.preload[k] = nil
        end
    end
    for k,_ in pairs(package.loaded) do
        if k:find('embed') then
            package.loaded[k] = nil
        end
    end
    local luapath = get_source_path():gsub('init.lua', '../common/?.lua')
    package.path = package.path .. ';' .. luapath
    local f = require 'embed.main'
    f(QtCore, {
        'Lqt MetaStringData',
        'Lqt MetaData',
        'Lqt Slots',
        'Lqt Signatures',
        'Lqt Properties',
    })
end
reload_embed()
--------------------------------------------------------------------------------
-- QFlags::testFlag
--------------------------------------------------------------------------------
QtCore.testFlag = function(flags, field)
    for _,flag in ipairs(flags) do
        if flag == field then
            return true
        end
    end
    return false
end
--------------------------------------------------------------------------------
-- Qt useful routines
--------------------------------------------------------------------------------
rawset(_G, 'SIGNAL', function(s) return '2' .. s end)
rawset(_G, 'SLOT', function (s) return '1' .. s end)
rawset(_G, 'tr', assert(QtCore.QObject.tr))
rawset(_G, 'qApp', function() return QtCore.QCoreApplication.instance() end)
--------------------------------------------------------------------------------
-- Qt message logger
--------------------------------------------------------------------------------
local function qLogger()
    local info = debug.getinfo(2)
    return QtCore.QMessageLogger(info.short_src, info.currentline, info.namewhat)
end
rawset(_G, 'qDebug', function(...)
    return qLogger():debug(...)
end)
rawset(_G, 'qInfo', function(...)
    return qLogger():info(...)
end)
rawset(_G, 'qWarning', function(...)
    return qLogger():warning(...)
end)
rawset(_G, 'qCritical', function(...)
    return qLogger():critical(...)
end)
rawset(_G, 'qFatal', function(...)
    return qLogger():fatal(...)
end)
--------------------------------------------------------------------------------
-- Qt ui loader
--------------------------------------------------------------------------------
rawset(_G, 'qSetupUi', function(path, root, customBuilder)
    local QtUiTools = require 'qtuitools'

    local file = QtCore.QFile(path)
    file:open(QtCore.QIODevice.ReadOnly)

    local QtWidgets = require 'qtwidgets'
    local QtOpenGL = require 'qtopengl'
   
    local QtQml = require 'qtqml'
    local QtQuick = require 'qtquick'
    local QtQuickWidgets = require 'qtquickwidgets'

    local QtWebEngineCore = require 'qtwebenginecore'
    local QtWebEngineWidgets = require 'qtwebenginewidgets'

    local function createWidget(className, parent)
        local class = QtWidgets[className]
            or QtOpenGL[className]
            or QtQuickWidgets[className]
            or QtWebEngineWidgets[className]

        if class then
            return class.new(parent)
        end
        print('Unknown ui widget : ' .. tostring(className))
    end

    local loader = QtUiTools.QUiLoader()
    function loader:createWidget(className, parent, name)
        if not parent then
            return root
        end

        local widget = customBuilder and customBuilder(className, parent, name) or nil
        if widget == nil then
            -- try use lqt class.new to create widget
            --  you can use __addsignal/__addslot on created object
            widget = createWidget(className:toStdString(), parent)
        end
        -- set widget object name
        if widget ~= nil then
        	widget:setObjectName(name)
        	return widget
        end
        -- use default uitools widget creator
        return QtUiTools.QUiLoader.createWidget(self, className, parent, name)
    end

    local function traversalChildren(widget, callback)
        for name,child in pairs(widget:children()) do
            callback(name, child)
            traversalChildren(child, callback)
        end
    end

    local ui = {}

    local formWidget = loader:load(file)
    traversalChildren(formWidget, function(name, child)
        ui[name] = child
    end)

    root.ui = ui

    QtCore.QMetaObject.connectSlotsByName(root)

    return formWidget
end)
--------------------------------------------------------------------------------
-- for debug purpuse
--------------------------------------------------------------------------------
rawset(_G, 'gc', function()
	print('gc start')
	collectgarbage()
	print('gc end')
end)
--------------------------------------------------------------------------------
-- Cleanup lqt ref's before application shutdown
--------------------------------------------------------------------------------
local qCleanup = function()
    -- cleanup registry ref class
    local LQT_REF_CLASS = "Registry Ref Class"
    local registry = debug.getregistry()
    registry[LQT_REF_CLASS] = {}
    -- remove lqt registry data in all instances
    for _,inst in ipairs(QtCore.instances()) do
        local env = debug.getfenv(inst)
        local removals = {}
        for k,v in pairs(env) do
            if k:match('^[%*]?Lqt') then
                table.insert(removals, k)
            end
        end
        for _,k in ipairs(removals) do
            rawset(env, k, nil)
        end
    end
    -- do full gc
    gc()
end
--------------------------------------------------------------------------------
-- get application class(console/gui/widget)
--------------------------------------------------------------------------------
local function createApplication(type, argc, argv)
    local function class()
        if type == 'console' then
            return QtCore.QCoreApplication
        elseif type == 'gui' then
            local QtGui = require 'qtgui'
            return QtGui.QGuiApplication
        elseif type == 'widget' then
            local QtGui = require 'qtgui'
            local QtWidgets = require 'qtwidgets'
            return QtWidgets.QApplication
        else
            error('invalid type ' .. tostring(type))
        end
    end
    local AppClass = class()

    local app = AppClass(argc, argv)
    -- Override notify funciton to handle script execute error
    function app:notify(receiver, event)
        local succ,ret = pcall(AppClass.notify, self, receiver, event)
        if succ then
            return ret
        else
            print(ret)
            return false
        end
    end
    -- Add core error handler, display error message box after script error
    if type == 'widget' then
        QtCore.setErrorHandler(function(errmsg)
            -- Try to load qtwidgets module
            local succ,QtWidgets = pcall(require, 'qtwidgets')
            if not succ then
                return
            end
            -- QtWidgets successfully loaded, showing an error message box
            QtWidgets.QMessageBox.critical(nil
                , tr 'Script error'
                , errmsg
            )
        end)
    end

    return app
end
--------------------------------------------------------------------------------
-- qt main func
--------------------------------------------------------------------------------
local function qMain(type, args, main)
    -- keep all qt object's in sandbox function
    local function sandbox()
        local app = createApplication(type, #args, args)

        local succ,window = pcall(main, app)
        if succ and window then
            window:show()
        end

        if not succ then
            error(window)
        end

        -- run full gc after main-window created
        --  delete Class()[local ctor] or Class.new()[ref class] problem~~~
        --  after gc, all non referenced local ctor object will been deleted
        collectgarbage()

        return app
    end
    -- call qCleanup to remove all qt object's ref from lua env and collect garbage
    local succ,app = xpcall(sandbox, debug.traceback)
    -- Run application mainloop
    local ret = succ and app.exec() or -1
    -- gc all object's without Application
    qCleanup()
    -- gc app
    if succ then
        app = nil
        -- avoid luacheck error(assign nil to app is unused)
        if not app then
            qCleanup()
        end
    else
        error(app)
    end
    return ret
end
--------------------------------------------------------------------------------
-- qml examples main func
--------------------------------------------------------------------------------
local function qQmlMain(name, ...)
    local QtGui = require 'qtgui'
    local QtQml = require 'qtqml'
    local QtQuick = require 'qtquick'

    QtCore.QCoreApplication.setAttribute(QtCore.AA_EnableHighDpiScaling)

    local app = QtGui.QGuiApplication(1 + select('#', unpack(arg)), { arg[0], unpack(arg) })
    app.setOrganizationName('QtProject')
    app.setOrganizationDomain('qt-project.org')
    app.setApplicationName(QtCore.QFileInfo(app.applicationFilePath()):baseName())

    local view = QtQuick.QQuickView()
    if os.getenv('QT_QUICK_CORE_PROFILE') == '1' then
        local f = view:format()
        f:setProfile(QtGui.QSurfaceFormat.CoreProfile)
        f:setVersion(4, 4)
        view:setFormat(f)
    end
    if os.getenv('QT_QUICK_MULTISAMPLE') == '1' then
        local f = view:format()
        f:setSamples(4)
        view:setFormat(f)
    end
    view.connect(view:engine(), SIGNAL 'quit()', app, SLOT 'quit()')
    local selector = QtQml.QQmlFileSelector.new(view:engine(), view)
    view:setSource(QtCore.QUrl(name))
    if view:status() == QtQuick.QQuickView.Error then
        return -1
    end
    view:setResizeMode(QtQuick.QQuickView.SizeRootObjectToView)
    view:show()
    return app.exec()
end
--------------------------------------------------------------------------------
-- qt test main func
--------------------------------------------------------------------------------
local function qTestMain(type, Class)
    local QtTest = require 'qttest'

    QtTest.QCOMPARE = function(actual, expected)
        local info = debug.getinfo(2)
        QtTest.qCompare(actual, expected, 'actual', 'excepted', info.short_src, info.currentline)
    end

    local app = createApplication(type, 1, { 'qt test' })
    app.setAttribute(QtCore.AA_Use96Dpi, true)

    QtTest.setMainSourcePath(debug.getinfo(2).short_src)

    return QtTest.qExec(Class(), 1, { 'qt test' })
end
--------------------------------------------------------------------------------
-- LuaQt Global functions
--------------------------------------------------------------------------------
rawset(_G, 'qCleanup', qCleanup)
rawset(_G, 'qMain', qMain)
rawset(_G, 'qQmlMain', qQmlMain)
rawset(_G, 'qTestMain', qTestMain)
--------------------------------------------------------------------------------
-- hook print lua api, flush after print
--------------------------------------------------------------------------------
local print = _G.print
_G.print = function(...)
    print(...)
    io.flush()
end
