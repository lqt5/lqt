local dlpath = arg[0]:gsub('examples/.+', 'build/lib/?.so;build/lib/?.dll')
package.cpath = package.cpath .. ';' .. dlpath

local QtCore = require 'qtcore'

--------------------------------------------------------------------------------
-- Qt useful routines
--------------------------------------------------------------------------------
_G.SIGNAL = function(s) return '2' .. s end
_G.SLOT = function (s) return '1' .. s end
_G.tr = assert(QtCore.QObject.tr)

--------------------------------------------------------------------------------
-- for debug purpuse
--------------------------------------------------------------------------------
_G.gc = function()
	print('gc start')
	collectgarbage()
	print('gc end')
end
--------------------------------------------------------------------------------
-- qml examples main func
--------------------------------------------------------------------------------
_G.qml_main = function(name, ...)
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
