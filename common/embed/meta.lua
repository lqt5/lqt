local QtCore
local LQT_OBJMETASTRING, LQT_OBJMETADATA, LQT_OBJSLOTS, LQT_OBJSIGS

local function hook(self, signature, func, access)
    local metaName = string.format('%s('.. tostring(self) .. ')'
        , (type(self) == 'table' and rawget(self, '__name') or nil) or 'LuaObject'
    )
    local metaStrings = self[LQT_OBJMETASTRING]
    local metaData = self[LQT_OBJMETADATA]
    local metaSlots = {}
    local metaSignals = {}
    local metaMethods

    -- add meta string(ignore duplicate string)
    local function addMetaString(str)
        for i,s in ipairs(metaStrings) do
            if s == str then
                return i - 1
            end
        end
        table.insert(metaStrings, str)
        return #metaStrings - 1
    end
    -- get meta string index from string literal
    local function metaStringIndex(str)
        for i,s in ipairs(metaStrings) do
            if s == str then
                -- lua index -> c++ index
                return i - 1
            end
        end
        error('Invalid meta string : ' .. str)
    end

    local function extractArgs()
        local name,args = string.match(signature, '^(.*)%((.*)%)$')
        -- addMetaString(name)
        local params = {}
        for arg in args:gmatch('[^,]+') do
            table.insert(params, arg)
        end
        return name,params
    end

    if metaStrings == nil then
        -- print ('adding a slot!', self, signature)
        -- Initialize
        metaStrings = {
            -- classname
            metaName,
            -- empty string
            '',
        }

        metaMethods = {}
    else
        -- get meta methods table
        metaMethods = metaData[-1]
    end

    -- build meta data array
    local function buildMetaData()
        metaData = {
            -- use for store added methods
            [-1] = metaMethods,

            -- Qt5 meta data header
            8,                      -- revision
            0,                      -- classname
            0, 0,                   -- classinfo
            #metaMethods, 14,   -- methods(count, offset)
            0, 0,                   -- properties
            0, 0,                   -- enums/sets
            0, 0,                   -- constructors
            0,                      -- flags
            0,                      -- signalCount
            -- Qt5 meta method data
        }

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

        local offset = #metaData + (#metaMethods * 5)
        -- build slot methods

        local signalCount = 0
        -- signals: name, argc, parameters, tag, flags
        for _,methodInfo in ipairs(metaMethods) do
            local func = methodInfo[-3]
            if not func then
                local access = methodInfo[-4]
                -- name index
                table.insert(metaData, methodInfo[-1])
                -- argc
                table.insert(metaData, #methodInfo / 2)
                -- parameters offset
                table.insert(metaData, offset)
                -- tag
                table.insert(metaData, 2)
                -- flags
                --  2bit { Method, Signal, Slot, Constructor }
                --  2bit { Private, Protected, Public }
                if access == 'private' then
                    table.insert(metaData, 4) -- 0100 Signal Private
                elseif access == 'protected' then
                    table.insert(metaData, 5) -- 0101 Signal Protected
                else -- access == 'public' then
                    table.insert(metaData, 6) -- 0110 Signal Public
                end
                -- increment data offset
                offset = (offset + 1 + #methodInfo)
                signalCount = signalCount + 1

                addSignalSlot(methodInfo[-2], false)
            end
        end
        metaData[14] = signalCount

        -- slots: name, argc, parameters, tag, flags
        for _,methodInfo in ipairs(metaMethods) do
            local func = methodInfo[-3]
            if func then
                local access = methodInfo[-4]
                -- name index
                table.insert(metaData, methodInfo[-1])
                -- argc
                table.insert(metaData, #methodInfo / 2)
                -- parameters offset
                table.insert(metaData, offset)
                -- tag
                table.insert(metaData, 2)
                -- flags
                --  2bit { Method, Signal, Slot, Constructor }
                --  2bit { Private, Protected, Public }
                if access == 'private' then
                    table.insert(metaData, 8)  -- 1000 Slot Private
                elseif access == 'protected' then
                    table.insert(metaData, 9)  -- 1001 Slot Protected
                else -- access == 'public' then
                    table.insert(metaData, 10) -- 1010 Slot Public
                end
                -- increment data offset
                offset = (offset + 1 + #methodInfo)

                addSignalSlot(methodInfo[-2], func)
            end
        end

        -- signals: parameters
        --  return_type param_types[argc] string_index[args]
        for _,methodInfo in ipairs(metaMethods) do
            local func = methodInfo[-3]
            if not func then
                -- return_type always is void
                table.insert(metaData, QtCore.QMetaType.Type.Void)
                -- parameters(MetaTypes[n] + NameIndex[n]
                for _,data in ipairs(methodInfo) do
                    table.insert(metaData, data)
                end
            end
        end

        -- slots: parameters
        --  return_type param_types[argc] string_index[args]
        for _,methodInfo in ipairs(metaMethods) do
            local func = methodInfo[-3]
            if func then
                -- return_type always is void
                table.insert(metaData, QtCore.QMetaType.Type.Void)
                -- parameters(MetaTypes[n] + NameIndex[n]
                for _,data in ipairs(methodInfo) do
                    table.insert(metaData, data)
                end
            end
        end
        -- eod
        table.insert(metaData, 0)
    end

    local name,params = extractArgs()
    -- add meta string(method name)
    addMetaString(name)

    local methodInfo = {
        -- method name index
        [-1] = metaStringIndex(name),
        [-2] = signature,
        [-3] = func,
        [-4] = access,
    }

    -- MetaTypes[n]
    for idx,p in ipairs(params) do
        local argName = string.format('arg%d', idx)
        addMetaString(argName)
        local type = QtCore.QMetaType.type(p)
        if type == 0 then
            local stringIndex = addMetaString(p)
            type = 0x80000000 + stringIndex
        end
        table.insert(methodInfo, type)
    end
    -- NameIndex[n]
    for idx,p in ipairs(params) do
        local argName = string.format('arg%d', idx)
        table.insert(methodInfo, metaStringIndex(argName))
    end

    -- add new method info
    if not func then
        local inserted = false
        -- is signal, insert before slot
        for idx = #metaMethods,1,-1 do
            local info = metaMethods[idx]
            if not info[-3] then
                table.insert(metaMethods, idx + 1, methodInfo)
                inserted = true
                break
            end
        end

        if not inserted then
            table.insert(metaMethods, 1, methodInfo)
        end
    else
        table.insert(metaMethods, methodInfo)
    end

    buildMetaData()

    -- print(string.format('Add method `%s` - (%s)\n\tSignal: %s\n\tMethodInfo: %s\n\tMetaString: %s\n\tMetaData[%d]: %s'
    --     , signature
    --     , self
    --     , '__slot' .. signature:match '%b()'
    --     , table.concat(methodInfo, ' ')
    --     , table.concat(metaStrings, ', ')
    --     , #metaData, table.concat(metaData, ' ')
    -- ))

    self[LQT_OBJMETASTRING] = metaStrings
    self[LQT_OBJMETADATA] = metaData
    self[LQT_OBJSLOTS] = metaSlots
    self[LQT_OBJSIGS] = metaSignals
end

local function checkMethodName(methodName)
    local name,args = string.match(methodName, '^(.*)%((.*)%)$')
    return name ~= nil and args ~= nil
end

return function(...)
	local LQT
	QtCore, LQT = ...
	LQT_OBJMETASTRING, LQT_OBJMETADATA, LQT_OBJSLOTS, LQT_OBJSIGS = unpack(LQT)

    local QObject_metatable = debug.getregistry()['QObject*']

    rawset(QObject_metatable, '__addslot', function(self, name, func, access)
        assert(type(func) == 'function'
            , string.format('__addslot("%s") `func` is not function!', name)
        )

        if not checkMethodName(name) then
            error(string.format('Invalid slot name : `%s`', name))
        end

        return hook(self, name, func, access or 'public')
    end)

    rawset(QObject_metatable, '__addsignal', function(self, name, access)
        if not checkMethodName(name) then
            error(string.format('Invalid signal name : `%s`', name))
        end

        return hook(self, name, nil, access or 'public')
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
