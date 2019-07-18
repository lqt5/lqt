--[[
 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
       6,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       3,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    2,   44,    2, 0x06 /* Public */,
       6,    1,   49,    2, 0x06 /* Public */,
       8,    1,   52,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
      11,    2,   55,    2, 0x09 /* Protected */,
      12,    1,   60,    2, 0x09 /* Protected */,
      13,    1,   63,    2, 0x09 /* Protected */,

 // signals: parameters
    QMetaType::Void, 0x80000000 | 3, QMetaType::Bool,    4,    5,
    QMetaType::Void, QMetaType::QIcon,    7,
    QMetaType::Void, 0x80000000 | 9,   10,

 // slots: parameters
    QMetaType::Void, 0x80000000 | 3, QMetaType::Bool,    4,    5,
    QMetaType::Void, QMetaType::QIcon,    7,
    QMetaType::Void, 0x80000000 | 9,   10,

       0        // eod
]]

return function(QObject_global
    , QObject_metatable
    , LQT_OBJMETASTRING
    , LQT_OBJMETADATA
    , LQT_OBJSLOTS
    , LQT_OBJSIGS
    , MetaVoidType
    , MetaConvertType
)
    local function hook(self, signature, func)
        local metaName = 'LuaObject('.. tostring(self) .. ')'
        local metaStrings = self[LQT_OBJMETASTRING]
        local metaData = self[LQT_OBJMETADATA]
        local metaSlots = {}
        local metaSignals = {}
        local metaMethods

        -- add meta string(ignore duplicate string)
        local function addMetaString(str)
            for _,s in ipairs(metaStrings) do
                if s == str then
                    return
                end
            end
            table.insert(metaStrings, str)
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
                    table.insert(metaSignals, '__slot' .. signature:match '%b()')
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
                    -- name index
                    table.insert(metaData, methodInfo[-1])
                    -- argc
                    table.insert(metaData, #methodInfo / 2)
                    -- parameters offset
                    table.insert(metaData, offset)
                    -- tag
                    table.insert(metaData, 2)
                    -- flags
                    table.insert(metaData, 0x0A)
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
                    -- name index
                    table.insert(metaData, methodInfo[-1])
                    -- argc
                    table.insert(metaData, #methodInfo / 2)
                    -- parameters offset
                    table.insert(metaData, offset)
                    -- tag
                    table.insert(metaData, 2)
                    -- flags
                    table.insert(metaData, 0x0A)
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
                    table.insert(metaData, MetaVoidType)
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
                    table.insert(metaData, MetaVoidType)
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
        }

        -- MetaTypes[n]
        for idx,p in ipairs(params) do
            local argName = string.format('arg%d', idx)
            addMetaString(argName)
            table.insert(methodInfo, MetaConvertType(p))
        end
        -- NameIndex[n]
        for idx,p in ipairs(params) do
            local argName = string.format('arg%d', idx)
            table.insert(methodInfo, metaStringIndex(argName))
        end

        -- add new method info
        table.insert(metaMethods, methodInfo)

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

    rawset(QObject_metatable, '__addslot', function(self, name, func)
        assert(type(func) == 'function'
            , string.format('__addslot("%s") `func` is not function!', name)
        )

        if not checkMethodName(name) then
            error(string.format('Invalid slot name : `%s`', name))
        end

        return hook(self, name, func)
    end)

    rawset(QObject_metatable, '__addsignal', function(self, name)
        if not checkMethodName(name) then
            error(string.format('Invalid signal name : `%s`', name))
        end

        return hook(self, name)
    end)

    -- TODO:
    --  this:__addproperty()
    --  this:__addenum()
    --  this:__addset()

    rawset(QObject_metatable, 'create', function(self, ctor_args, ...)
        -- call __static_init once
        --  for class object
        if self.__static_init ~= nil then
            self:__static_init()
            self.__static_init = false
        end

        local obj = self.new(unpack(ctor_args or {}))

        local super_env = debug.getfenv(self)
        if super_env then
            -- set object env inherit super(self) env
            local obj_env = setmetatable({}, { __index = super_env })
            debug.setfenv(obj, obj_env)

            for k,v in pairs(super_env) do
                -- trigger lqtAddOverride virtual-bind function
                obj[k] = v
                obj[k] = nil
            end
        end

        local __init = rawget(super_env, '__init')
        if type(__init) == 'function' then
            __init(obj, ...)
        end

        obj.__super = self

        return obj
    end)
    -- also modify the static QObject::create function
    -- QObject_global.create = create

    return true
end
