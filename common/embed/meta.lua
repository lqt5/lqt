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
local QtCore, LQT_OBJMETASTRING, LQT_OBJMETADATA, LQT_OBJSLOTS, LQT_OBJSIGS, LQT_OBJPROPS

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
-- Validate method(signal/slot) name
----------------------------------------------------------------------------------------------------
local function checkMethodName(methodName)
    local name,args = string.match(methodName, '^(.*)%((.*)%)$')
    return name ~= nil and args ~= nil
end
----------------------------------------------------------------------------------------------------
-- Meta closures, register to QObject and QtCore.QObject
----------------------------------------------------------------------------------------------------
local MetaClosures = {}
----------------------------------------------------------------------------------------------------
-- Add an custom qt slot
----------------------------------------------------------------------------------------------------
function MetaClosures.__addslot(self, signature, func, access)
    assert(type(func) == 'function'
        , string.format('__addslot("%s") `func` is not function!', signature)
    )

    if not checkMethodName(signature) then
        error(string.format('Invalid slot signature : `%s`', signature))
    end

    local metaData = init(self)

    metaData:addMethod(signature, access, func)

    local metaSlots, metaSignals, metaProperties = metaData:build()

    self[LQT_OBJSLOTS] = metaSlots
    self[LQT_OBJSIGS] = metaSignals
    self[LQT_OBJPROPS] = metaProperties
end
----------------------------------------------------------------------------------------------------
-- Add an custom qt signal
----------------------------------------------------------------------------------------------------
function MetaClosures.__addsignal(self, signature, access)
    if not checkMethodName(signature) then
        error(string.format('Invalid signal signature : `%s`', signature))
    end

    local metaData = init(self)

    metaData:addMethod(signature, access)

    local metaSlots, metaSignals, metaProperties = metaData:build()

    self[LQT_OBJSLOTS] = metaSlots
    self[LQT_OBJSIGS] = metaSignals
    self[LQT_OBJPROPS] = metaProperties
end
----------------------------------------------------------------------------------------------------
-- Add an custom qt proerty
----------------------------------------------------------------------------------------------------
function MetaClosures.__addproperty(self, signature, info)
    local metaData = init(self)

    local type,name = signature:match('([%w%d_]+%*?)%s+([%w%d_]+)')
    if not type or not name then
        error(string.format('Invalid property signature : `%s`', signature))
    end

    local metaType = QtCore.QMetaType.type(type)
    if metaType == QtCore.QMetaType.UnknownType or metaType >= QtCore.QMetaType.User then
        error(string.format('Unknown property type : `%s`', type))
    end

    metaData:addProperty(metaType, name, info)

    local metaSlots, metaSignals, metaProperties = metaData:build()

    self[LQT_OBJSLOTS] = metaSlots
    self[LQT_OBJSIGS] = metaSignals
    self[LQT_OBJPROPS] = metaProperties
end
----------------------------------------------------------------------------------------------------
-- Emit an signal
----------------------------------------------------------------------------------------------------
function MetaClosures.__emit(self, name, ...)
    local meta = self:metaObject()
    meta.invokeMethod(self, name, QtCore.AutoConnection, ...)
end
----------------------------------------------------------------------------------------------------
-- Entry
----------------------------------------------------------------------------------------------------
return function(...)
	local LQT
	QtCore, LQT = ...
	LQT_OBJMETASTRING, LQT_OBJMETADATA, LQT_OBJSLOTS, LQT_OBJSIGS, LQT_OBJPROPS = unpack(LQT)

    CMetaStrings.setup(...)
    CMetaData.setup(...)

    local QObject_metatable = debug.getregistry()['QObject*']

    for name,func in pairs(MetaClosures) do
        rawset(QObject_metatable, name, func)
        QtCore.QObject[name] = func
    end

    -- TODO:
    --  this:__addenum()
    --  this:__addset()
end
