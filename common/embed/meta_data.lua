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
----------------------------------------------------------------------------------------------------
-- Meta string container
----------------------------------------------------------------------------------------------------
local Class = {}
----------------------------------------------------------------------------------------------------
-- Setup locals from lqt_embed.cpp
----------------------------------------------------------------------------------------------------
function Class.setup(...)
    QtCore = ...
end
----------------------------------------------------------------------------------------------------
-- Create an Class object
----------------------------------------------------------------------------------------------------
function Class.create(...)
    local ret = {}
    setmetatable(ret, { __index = Class })
    ret:__init(...)
    return ret
end
----------------------------------------------------------------------------------------------------
-- Constructor
----------------------------------------------------------------------------------------------------
function Class:__init(metaStrings)
    -- meta strings
    self.metaStrings = metaStrings
    -- use for store added methods
    self.methods = {}
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
-- Add method(signal/slot)
----------------------------------------------------------------------------------------------------
function Class:addMethod(signature, access, func)
    local name,params = extractArgs(signature)
    -- add meta string(method name)
    self.metaStrings:insert(name)

    local methodInfo = {
        -- method name index
        nameIndex = self.metaStrings:indexOf(name),
        signature = signature,
        func = func,
        access = access,
    }

    -- MetaTypes[n]
    for idx,p in ipairs(params) do
        local argName = string.format('arg%d', idx)
        self.metaStrings:insert(argName)
        local type = QtCore.QMetaType.type(p)
        if type == 0 then
            local stringIndex = self.metaStrings:insert(p)
            type = 0x80000000 + stringIndex
        end
        table.insert(methodInfo, type)
    end
    -- NameIndex[n]
    for idx,p in ipairs(params) do
        local argName = string.format('arg%d', idx)
        table.insert(methodInfo, self.metaStrings:indexOf(argName))
    end

    -- add new method info
    if not func then
        local inserted = false
        -- is signal, insert before slot
        for idx = #self.methods,1,-1 do
            local info = self.methods[idx]
            if not info[-3] then
                table.insert(self.methods, idx + 1, methodInfo)
                inserted = true
                break
            end
        end

        if not inserted then
            table.insert(self.methods, 1, methodInfo)
        end
    else
        table.insert(self.methods, methodInfo)
    end
end
----------------------------------------------------------------------------------------------------
-- Build meta data
----------------------------------------------------------------------------------------------------
function Class:build()
    -- Get meta methods(slot) table
    local metaMethods = self.methods

    local metaSlots = {}
    local metaSignals = {}

    -- Cleanup meta data
    for i = #self,1,-1 do
        self[i] = nil
    end
    -- Initial meta data struct
    for _,val in ipairs {
        -- Qt5 meta data header
        8,                      -- revision
        0,                      -- classname
        0, 0,                   -- classinfo
        #metaMethods, 14,       -- methods(count, offset)
        0, 0,                   -- properties
        0, 0,                   -- enums/sets
        0, 0,                   -- constructors
        0,                      -- flags
        0,                      -- signalCount
        -- Qt5 meta method data
    } do
        table.insert(self, val)
    end

    local function addSignalSlot(signature, func)
        if func then
            table.insert(metaSlots, func)
            table.insert(metaSignals, {
                -- Object slot name
                signature,
                -- LqtSlotAcceptor slot name
                '__slot' .. signature:match '%b()',
            })
        else
            table.insert(metaSlots, false)
            table.insert(metaSignals, false)
        end
    end

    local offset = #self + (#metaMethods * 5)
    -- build slot methods

    local signalCount = 0
    -- signals: name, argc, parameters, tag, flags
    for _,methodInfo in ipairs(metaMethods) do
        local func = methodInfo.func
        if not func then
            local access = methodInfo.access
            -- name index
            table.insert(self, methodInfo.nameIndex)
            -- argc
            table.insert(self, #methodInfo / 2)
            -- parameters offset
            table.insert(self, offset)
            -- tag
            table.insert(self, 2)
            -- flags
            --  2bit { Method, Signal, Slot, Constructor }
            --  2bit { Private, Protected, Public }
            if access == 'private' then
                table.insert(self, 4) -- 0100 Signal Private
            elseif access == 'protected' then
                table.insert(self, 5) -- 0101 Signal Protected
            else -- access == 'public' then
                table.insert(self, 6) -- 0110 Signal Public
            end
            -- increment data offset
            offset = (offset + 1 + #methodInfo)
            signalCount = signalCount + 1

            addSignalSlot(methodInfo.signature, false)
        end
    end
    self[14] = signalCount

    -- slots: name, argc, parameters, tag, flags
    for _,methodInfo in ipairs(metaMethods) do
        local func = methodInfo.func
        if func then
            local access = methodInfo.access
            -- name index
            table.insert(self, methodInfo.nameIndex)
            -- argc
            table.insert(self, #methodInfo / 2)
            -- parameters offset
            table.insert(self, offset)
            -- tag
            table.insert(self, 2)
            -- flags
            --  2bit { Method, Signal, Slot, Constructor }
            --  2bit { Private, Protected, Public }
            if access == 'private' then
                table.insert(self, 8)  -- 1000 Slot Private
            elseif access == 'protected' then
                table.insert(self, 9)  -- 1001 Slot Protected
            else -- access == 'public' then
                table.insert(self, 10) -- 1010 Slot Public
            end
            -- increment data offset
            offset = (offset + 1 + #methodInfo)

            addSignalSlot(methodInfo.signature, func)
        end
    end

    -- signals: parameters
    --  return_type param_types[argc] string_index[args]
    for _,methodInfo in ipairs(metaMethods) do
        local func = methodInfo.func
        if not func then
            -- return_type always is void
            table.insert(self, QtCore.QMetaType.Type.Void)
            -- parameters(MetaTypes[n] + NameIndex[n]
            for _,data in ipairs(methodInfo) do
                table.insert(self, data)
            end
        end
    end

    -- slots: parameters
    --  return_type param_types[argc] string_index[args]
    for _,methodInfo in ipairs(metaMethods) do
        local func = methodInfo.func
        if func then
            -- return_type always is void
            table.insert(self, QtCore.QMetaType.Type.Void)
            -- parameters(MetaTypes[n] + NameIndex[n]
            for _,data in ipairs(methodInfo) do
                table.insert(self, data)
            end
        end
    end
    -- eod
    table.insert(self, 0)

    return metaSlots, metaSignals
end

return Class
