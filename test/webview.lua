#!/usr/bin/lua
package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWebKit = require 'qtwebkit'

local app = QtGui.QApplication(1 + select('#', ...), {arg[0], ...})

local address = tostring(arg[1])

if address == 'nil' then
	address = 'www.lua.org'
end

print('Loading site  '..address..' ...')

local webView = QtWebKit.QWebView()
webView:connect('2loadFinished(bool)', function()
	print('Loaded', webView:url():toEncoded())
end)
webView:setUrl(QtCore.QUrl("http://" .. address))
webView:show()

app.exec()



