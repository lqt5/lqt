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
local QtCore
local Flags = require 'embed.flags'
----------------------------------------------------------------------------------------------------
-- Meta string container
----------------------------------------------------------------------------------------------------
local Class = {}
----------------------------------------------------------------------------------------------------
-- Setup locals from lqt_embed.cpp
----------------------------------------------------------------------------------------------------
function Class.setup(...)
    QtCore = ...
    Class = QtCore.Class('MetaMethod')(Class)
end
----------------------------------------------------------------------------------------------------
-- Extract signal/slot name & arguments
----------------------------------------------------------------------------------------------------
local function extractArgs(signature)
    local name,args = string.match(signature, '^(.*)%((.*)%)$')
    local params = {}
    for arg in args:gmatch('[^,]+') do
        table.insert(params, arg)
    end
    return name,params
end
----------------------------------------------------------------------------------------------------
-- Generate flags
----------------------------------------------------------------------------------------------------
local function generateFlags(isSignal, access)
    local flags = isSignal and Flags.MethodFlags.MethodSignal or Flags.MethodFlags.MethodSlot
    if access == 'private' then
        flags = flags + Flags.MethodFlags.AccessPrivate
    elseif access == 'protected' then
        flags = flags + Flags.MethodFlags.AccessProtected
    else -- access == 'public' then
        flags = flags + Flags.MethodFlags.AccessPublic
    end
    return flags
end
----------------------------------------------------------------------------------------------------
-- Constructor
----------------------------------------------------------------------------------------------------
function Class:__init(index, metaStrings, signature, access, func)
	-- Meta strings
	self.metaStrings = metaStrings
	-- Method signature(etc: `click()`)
	self.signature = signature
	-- Access(public/protected/private)
	self.access = access
	-- Method callback func, signal if func is nil
	self.func = func or false
	-- Method flags
	self.flags = generateFlags(not func, access)
	-- Method name string index
	self.nameIndex = -1
	-- Sarameters data(ParamTypes[]/NameIndies[])
	self.parameters = {}
	-- Sort index (used for table.sort)
	self.index = index
end
----------------------------------------------------------------------------------------------------
-- Get method header data size
----------------------------------------------------------------------------------------------------
function Class.headerSize()
	return 5
end
----------------------------------------------------------------------------------------------------
-- Write method header data
----------------------------------------------------------------------------------------------------
function Class:writeHeader(data, offset)
    -- name index
    table.insert(data, self.nameIndex)
    -- argc
    table.insert(data, #self.parameters / 2)
    -- parameters offset
    table.insert(data, offset)
    -- tag
    table.insert(data, 2)
    -- flags
    table.insert(data, self.flags)
    -- increment data offset
    offset = (offset + 1 + #self.parameters)
    return offset
end
----------------------------------------------------------------------------------------------------
-- Write method parameter data
----------------------------------------------------------------------------------------------------
function Class:writeParameter(data)
    -- return_type always is void
    table.insert(data, QtCore.QMetaType.Type.Void)
    -- parameters(MetaTypes[n] + NameIndex[n]
    for _,val in ipairs(self.parameters) do
        table.insert(data, val)
    end
end
----------------------------------------------------------------------------------------------------
-- Build meta method data
----------------------------------------------------------------------------------------------------
function Class:build()
    local name,params = extractArgs(self.signature)
    -- add meta string(method name)
    self.nameIndex = self.metaStrings:insert(name)

    local parameters = self.parameters
    -- Parameters MetaTypes[n]
    for idx,p in ipairs(params) do
        local argName = string.format('arg%d', idx)
        self.metaStrings:insert(argName)
        local type = QtCore.QMetaType.type(p)
        if type == 0 then
            local stringIndex = self.metaStrings:insert(p)
            type = Flags.MetaDataFlags.IsUnresolvedType + stringIndex
        end
        table.insert(parameters, type)
    end
    -- Parameters NameIndies[n]
    for idx,p in ipairs(params) do
        local argName = string.format('arg%d', idx)
        table.insert(parameters	, self.metaStrings:indexOf(argName))
    end
end

return Class
