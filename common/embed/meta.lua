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
-- locals from lqt_embed.cpp
local QtCore, LQT_OBJMETASTRING, LQT_OBJMETADATA, LQT_OBJSLOTS, LQT_OBJSIGS

local CMetaStrings = require 'embed.meta_strings'
local CMetaData = require 'embed.meta_data'

----------------------------------------------------------------------------------------------------
-- Initialize
----------------------------------------------------------------------------------------------------
local function init(self)
    local metaStrings = self[LQT_OBJMETASTRING]
    -- No metaStrings or data.owner not equal to self (parent's owner data), re-create new data
    if not metaStrings or metaStrings.owner ~= self then
        local metaName = string.format('%s('.. tostring(self) .. ')'
            , (type(self) == 'table' and rawget(self, '__name') or nil) or 'LuaObject'
        )
        metaStrings = CMetaStrings(self
            -- classname & empty string
            , { metaName, '' }
            -- clone parent's owner data
            , metaStrings
        )
        self[LQT_OBJMETASTRING] = metaStrings
    end
    -- No metaData or data.owner not equal to self (parent's owner data), re-create new data
    local metaData = self[LQT_OBJMETADATA]
    if not metaData or metaData.owner ~= self then
        metaData = CMetaData(self
            , metaStrings
            -- clone parent's owner data
            , metaData
        )
        self[LQT_OBJMETADATA] = metaData
    end
    return metaData
end
----------------------------------------------------------------------------------------------------
-- Add signal/slot for qt object
----------------------------------------------------------------------------------------------------
local function addMethod(self, signature, access, func)
    local metaData = init(self)

    metaData:addMethod(signature, access, func)

    local metaSlots, metaSignals = metaData:build()

    self[LQT_OBJSLOTS] = metaSlots
    self[LQT_OBJSIGS] = metaSignals
end
----------------------------------------------------------------------------------------------------
-- Validate method(signal/slot) name
----------------------------------------------------------------------------------------------------
local function checkMethodName(methodName)
    local name,args = string.match(methodName, '^(.*)%((.*)%)$')
    return name ~= nil and args ~= nil
end
----------------------------------------------------------------------------------------------------
-- Entry
----------------------------------------------------------------------------------------------------
return function(...)
	local LQT
	QtCore, LQT = ...
	LQT_OBJMETASTRING, LQT_OBJMETADATA, LQT_OBJSLOTS, LQT_OBJSIGS = unpack(LQT)

    CMetaStrings.setup(...)
    CMetaData.setup(...)

    local QObject_metatable = debug.getregistry()['QObject*']

    rawset(QObject_metatable, '__addslot', function(self, name, func, access)
        assert(type(func) == 'function'
            , string.format('__addslot("%s") `func` is not function!', name)
        )

        if not checkMethodName(name) then
            error(string.format('Invalid slot name : `%s`', name))
        end

        return addMethod(self, name, access or 'public', func)
    end)

    rawset(QObject_metatable, '__addsignal', function(self, name, access)
        if not checkMethodName(name) then
            error(string.format('Invalid signal name : `%s`', name))
        end

        return addMethod(self, name, access or 'public')
    end)

    rawset(QObject_metatable, '__emit', function(self, name, ...)
        local meta = self:metaObject()
        meta.invokeMethod(self, name, QtCore.AutoConnection, ...)
    end)

    QtCore.QObject.__addslot = QObject_metatable.__addslot
    QtCore.QObject.__addsignal = QObject_metatable.__addsignal
    QtCore.QObject.__emit = QObject_metatable.__emit

    -- TODO:
    --  this:__addproperty()
    --  this:__addenum()
    --  this:__addset()
end
