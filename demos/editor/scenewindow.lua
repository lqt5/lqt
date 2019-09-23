--[[*************************************************************************
Copyright (c) 2019-2019 Saniko

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
***************************************************************************]]
local QtCore = require 'qtcore'
local QtWidgets = require 'qtwidgets'
local QtWebEngineWidgets = require 'qtwebenginewidgets'

local WebUiHandler = require 'webuihandler'

local Class = QtCore.Class('SceneWindow', QtWidgets.QDockWidget) {}

function Class:__static_init()
	WebUiHandler.registerUrlScheme()
	local profile = QtWebEngineWidgets.QWebEngineProfile()
	local handler = WebUiHandler()
	profile:installUrlSchemeHandler(WebUiHandler.schemeName, handler)

	self.handler = handler
	self.profile = profile
end

function Class:__init()
	local page = QtWebEngineWidgets.QWebEnginePage.new(self.profile)
	page:load(WebUiHandler.aboutUrl)

	local view = QtWebEngineWidgets.QWebEngineView.new(self)
	view:setPage(page)
	self:setWidget(view)

    self:setContentsMargins(0, 0, 0, 0)
	self:setFeatures { 'DockWidgetMovable' }
	self:setWindowTitle('Scene Editor')

	view:connect(SIGNAL 'loadFinished(bool)', function(_,ok)
		-- print('loadFinished', ok)
		-- view:page():runJavaScript('App.instance.addPictures()')

		view:page():runJavaScript('document.location.href', function(value)
			print(value:value():toStdString())
		end)
	end)

	self.webView = view
end

function Class:__uninit()
	-- custom web engine profile view page must manual delete
	--	avoid gc crash
	self.webView:page():delete()
end

return Class
