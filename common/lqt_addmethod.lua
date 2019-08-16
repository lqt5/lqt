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

return function(QtCore
    , QObject_metatable
    , LQT_OBJMETASTRING
    , LQT_OBJMETADATA
    , LQT_OBJSLOTS
    , LQT_OBJSIGS
    , MetaVoidType
    , MetaConvertType
)
    local function hook(self, signature, func, access)
        local metaName = 'LuaObject('.. tostring(self) .. ')'
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
            [-4] = access,
        }

        -- MetaTypes[n]
        for idx,p in ipairs(params) do
            local argName = string.format('arg%d', idx)
            addMetaString(argName)
            local type = MetaConvertType(p)
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

    ----------------------------------------------------------------------------------------------------
    --- Creates a deep copy of an object.
    ----------------------------------------------------------------------------------------------------
    local function deepCopy(tab)
        local lookup = {}
        local function _copy(value)
            if type(value) ~= 'table' then
                return value
            elseif lookup[value] then
                return lookup[value]
            end
            local new = {}
            lookup[value] = new
            for k,v in pairs(value) do
                new[_copy(k)] = _copy(v)
            end
        end
        return _copy(tab)
    end
    ----------------------------------------------------------------------------------------------------
    -- call __static_init(static constructor)
    ----------------------------------------------------------------------------------------------------
    local staticInit = (function()
        local __cache = setmetatable({}, { __mode = 'k' })

        local function __init(classDef)
            if __cache[classDef] then
                return
            end
            __cache[classDef] = true

            local __super = rawget(classDef, '__super')
            if __super then
                __init(__super)
            end

            local __static_init = rawget(classDef, '__static_init')
            if type(__static_init) == 'function' then

                -- local metaStrings = __super and __super[LQT_OBJMETASTRING] or nil
                -- local metaData = __super and __super[LQT_OBJMETADATA] or nil
                -- local metaSlots = __super and __super[LQT_OBJSLOTS] or nil
                -- local metaSignals = __super and __super[LQT_OBJSIGS] or nil

                -- classDef[LQT_OBJMETASTRING] = deepCopy(metaStrings)
                -- classDef[LQT_OBJMETADATA] = deepCopy(metaData)
                -- classDef[LQT_OBJSLOTS] = deepCopy(metaSlots)
                -- classDef[LQT_OBJSIGS] = deepCopy(metaSignals)
                -- classDef[LQT_OBJMETADATA_STORE] = ''
                -- classDef[LQT_OBJMETASTRING_STORE] = ''

                __static_init(classDef)
            end     
        end

        return __init
    end)()
    ----------------------------------------------------------------------------------------------------
    -- trigger lqtAddOverride virtual-bind function
    ----------------------------------------------------------------------------------------------------
    local function addOverride(inst, classDef)
        local __super = rawget(classDef, '__super')
        if __super then
            addOverride(inst, __super)
        end

        for k,v in pairs(classDef) do
            if type(v) == 'function' then
                inst[k] = v
                inst[k] = nil
            end
        end
    end
    -- reversed fields, cannot used in class defitition table
    local reversedFields = {
        'new',
        '__name',
        '__classDef',
        '__proto',
        '__super',
    }
    ----------------------------------------------------------------------------------------------------
    -- 'Is a class' check.
    ----------------------------------------------------------------------------------------------------
    local isClass = function (x)
        return type(x) == 'table' and type(x.__classDef) == 'table'
    end
    ----------------------------------------------------------------------------------------------------
    -- 'Is an object' check.
    ----------------------------------------------------------------------------------------------------
    local isObject = function (x)
        return type(x) == 'userdata' and isClass(x.__class)
    end
    ----------------------------------------------------------------------------------------------------
    -- 'Is an instance of' check.
    --  @param x Object that is tested for being an instance of class.
    --  @param cls A class that the object is tested against.
    --  @return Returns `true` if `obj` is an immediate instance of `cls` or one of it's ancestors.
    ----------------------------------------------------------------------------------------------------
    local isInstanceOf = (function()
        local function checkQt(obj, cls)
            if type(obj) ~= 'userdata' or type(cls) ~= 'table' then
                return false
            end
            local __type = rawget(cls, '__type')
            return __type and (obj[__type] ~= nil)
        end

        local function check(obj, cls)
            if not isObject(obj) then
                return false
            end

            local ret = false

            local env = debug.getfenv(obj)
            local __class = rawget(env, '__class')

            while __class and __class ~= cls do
                -- check if obj create by __proto(Qt objects)
                if __class.__proto == cls then
                    return true
                end
                __class = rawget(__class, '__super')
            end

            return __class == cls
        end

        local clsCaches = {}

        return function(obj, cls)
            local objCaches = clsCaches[cls]
            local key = tostring(obj)
            if objCaches then
                local flag = objCaches[key]
                if flag ~= nil then
                    return flag
                end
            end

            local ret = checkQt(obj, cls) or check(obj, cls)

            if not objCaches then
                objCaches = setmetatable({}, { __mode = 'k' })
                clsCaches[cls] = objCaches
            end
            objCaches[key] = ret

            return ret
        end
    end)()

    rawset(QtCore, 'isClass', isClass)
    rawset(QtCore, 'isObject', isObject)
    rawset(QtCore, 'isInstanceOf', isInstanceOf)

    local function errorNew()
        error('attempt to call `new` from an instance')
    end

    rawset(QtCore, 'Class', function(name, proto)
        assert(type(name) == 'string', 'Class name must be an string')

        local function createInst(inst, classDef, ...)
            local env = debug.getfenv(inst)
            env.new = errorNew
            env.__class = classDef
            -- set object env inherit super(self) env
            setmetatable(env, { __index = classDef })

            -- call __static_init once
            --  for class object
            staticInit(classDef)

            -- trigger lqtAddOverride virtual-bind function
            addOverride(inst, classDef)

            -- call __init(custom constructor)
            local __init = rawget(classDef, '__init')
            if type(__init) == 'function' then
                __init(inst, ...)
            end

            return inst
        end

        return function(classDef)
            if not classDef then
                classDef = {}
            end

            for _,name in ipairs(reversedFields) do
                assert(rawget(classDef, name) == nil
                    , string.format('`%s` is reversed classDef field!', name)
                )
            end

            classDef.__name = name
            classDef.__classDef = classDef
            classDef.__proto = proto.__proto and proto.__proto or proto
            classDef.__super = proto.__classDef and proto or nil

            local function ctor(new, ctorArgs)
                assert(type(ctorArgs) == 'table' or ctorArgs == nil, 'ctorArgs must be table or nil')
                return ctorArgs and new(unpack(ctorArgs)) or new()
            end

            classDef.new = function(ctorArgs, ...)
                local inst = ctor(classDef.__proto.new, ctorArgs)
                inst.__gc = false
                return createInst(inst, classDef, ...)
            end

            return setmetatable(classDef, {
                __index = function(_,k)
                    -- call __static_init once
                    --  for class object
                    staticInit(classDef)

                    local v = rawget(classDef, k)
                    if v ~= nil then
                        return v
                    end

                    v = proto[k]

                    if type(v) == nil then
                        error(string.format('Class `%s` : can not get undeclared member variable `%s`', name, k), 2)
                    end

                    return v
                end,
                __call = function(self, ctorArgs, ...)
                    local inst = ctor(classDef.__proto, ctorArgs)
                    return createInst(inst, classDef, ...)
                end,
            })
        end
    end)

    -- also modify the static QObject::create function
    -- local QObject_global = QtCore['QObject']
    -- QObject_global.create = create

    return true
end
