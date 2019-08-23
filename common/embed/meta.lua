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

--[[
enum PropertyFlags  {
    Invalid = 0x00000000,
    Readable = 0x00000001,
    Writable = 0x00000002,
    Resettable = 0x00000004,
    EnumOrFlag = 0x00000008,
    StdCppSet = 0x00000100,
//     Override = 0x00000200,
    Constant = 0x00000400,
    Final = 0x00000800,
    Designable = 0x00001000,
    ResolveDesignable = 0x00002000,
    Scriptable = 0x00004000,
    ResolveScriptable = 0x00008000,
    Stored = 0x00010000,
    ResolveStored = 0x00020000,
    Editable = 0x00040000,
    ResolveEditable = 0x00080000,
    User = 0x00100000,
    ResolveUser = 0x00200000,
    Notify = 0x00400000,
    Revisioned = 0x00800000
};

enum MethodFlags  {
    AccessPrivate = 0x00,
    AccessProtected = 0x01,
    AccessPublic = 0x02,
    AccessMask = 0x03, //mask

    MethodMethod = 0x00,
    MethodSignal = 0x04,
    MethodSlot = 0x08,
    MethodConstructor = 0x0c,
    MethodTypeMask = 0x0c,

    MethodCompatibility = 0x10,
    MethodCloned = 0x20,
    MethodScriptable = 0x40,
    MethodRevisioned = 0x80
};

enum MetaObjectFlags { // keep it in sync with QMetaObjectBuilder::MetaObjectFlag enum
    DynamicMetaObject = 0x01,
    RequiresVariantMetaObject = 0x02,
    PropertyAccessInStaticMetaCall = 0x04 // since Qt 5.5, property code is in the static metacall
};

enum MetaDataFlags {
    IsUnresolvedType = 0x80000000,
    TypeNameIndexMask = 0x7FFFFFFF,
    IsUnresolvedSignal = 0x70000000
};

enum EnumFlags {
    EnumIsFlag = 0x1,
    EnumIsScoped = 0x2
};

self:__addproperty('name', {
    read = self.read,
    write = self.write,
    reset = self.reset,
    notify = 'textChanged'
    revision = 0,
    stored = true,
    user = false,
    constant = true,
    final = true,
})

Q_PROPERTY(type name
           (READ getFunction [WRITE setFunction] |
            MEMBER memberName [(READ getFunction | WRITE setFunction)])
           [RESET resetFunction]
           [NOTIFY notifySignal]
           [REVISION int]
           [DESIGNABLE bool]
           [SCRIPTABLE bool]
           [STORED bool]
           [USER bool]
           [CONSTANT]
           [FINAL])

-- Q_PROPERTY(QString text MEMBER m_text NOTIFY textChanged FINAL)
]]
--[[
/****************************************************************************
** Meta object code from reading C++ file 'document.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.12.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../markdowneditor/document.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'document.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.12.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_Document_t {
    QByteArrayData data[4];
    char stringdata0[27];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_Document_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_Document_t qt_meta_stringdata_Document = {
    {
QT_MOC_LITERAL(0, 0, 8), // "Document"
QT_MOC_LITERAL(1, 9, 11), // "textChanged"
QT_MOC_LITERAL(2, 21, 0), // ""
QT_MOC_LITERAL(3, 22, 4) // "text"

    },
    "Document\0textChanged\0\0text"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_Document[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   14, // methods
       1,   22, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   19,    2, 0x06 /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::QString,    3,

 // properties: name, type, flags
       3, QMetaType::QString, 0x00495803,

 // properties: notify_signal_id
       0,

       0        // eod
};

void Document::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        Document *_t = static_cast<Document *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->textChanged((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (Document::*)(const QString & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&Document::textChanged)) {
                *result = 0;
                return;
            }
        }
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty) {
        Document *_t = static_cast<Document *>(_o);
        Q_UNUSED(_t)
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = _t->m_text; break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        Document *_t = static_cast<Document *>(_o);
        Q_UNUSED(_t)
        void *_v = _a[0];
        switch (_id) {
        case 0:
            if (_t->m_text != *reinterpret_cast< QString*>(_v)) {
                _t->m_text = *reinterpret_cast< QString*>(_v);
                Q_EMIT _t->textChanged(_t->m_text);
            }
            break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    }
#endif // QT_NO_PROPERTIES
}

QT_INIT_METAOBJECT const QMetaObject Document::staticMetaObject = { {
    &QObject::staticMetaObject,
    qt_meta_stringdata_Document.data,
    qt_meta_data_Document,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *Document::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *Document::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_Document.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int Document::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 1)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 1)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 1;
    }
#ifndef QT_NO_PROPERTIES
   else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 1;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void Document::textChanged(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
]]


--[[
class MyClass : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Priority priority READ priority WRITE setPriority NOTIFY priorityChanged)

public:
    MyClass(QObject *parent = 0);
    ~MyClass();

    enum Priority { High, Low, VeryHigh, VeryLow };
    Q_ENUM(Priority)

    void setPriority(Priority priority)
    {
        m_priority = priority;
        emit priorityChanged(priority);
    }
    Priority priority() const
    { return m_priority; }

signals:
    void priorityChanged(Priority);

private:
    Priority m_priority;
};

/****************************************************************************
** Meta object code from reading C++ file 'myclass.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.12.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../markdowneditor/myclass.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'myclass.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.12.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_MyClass_t {
    QByteArrayData data[9];
    char stringdata0[69];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_MyClass_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_MyClass_t qt_meta_stringdata_MyClass = {
    {
QT_MOC_LITERAL(0, 0, 7), // "MyClass"
QT_MOC_LITERAL(1, 8, 15), // "priorityChanged"
QT_MOC_LITERAL(2, 24, 0), // ""
QT_MOC_LITERAL(3, 25, 8), // "Priority"
QT_MOC_LITERAL(4, 34, 8), // "priority"
QT_MOC_LITERAL(5, 43, 4), // "High"
QT_MOC_LITERAL(6, 48, 3), // "Low"
QT_MOC_LITERAL(7, 52, 8), // "VeryHigh"
QT_MOC_LITERAL(8, 61, 7) // "VeryLow"

    },
    "MyClass\0priorityChanged\0\0Priority\0"
    "priority\0High\0Low\0VeryHigh\0VeryLow"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_MyClass[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   14, // methods
       1,   22, // properties
       1,   26, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   19,    2, 0x06 /* Public */,

 // signals: parameters
    QMetaType::Void, 0x80000000 | 3,    2,

 // properties: name, type, flags
       4, 0x80000000 | 3, 0x0049510b,

 // properties: notify_signal_id
       0,

 // enums: name, alias, flags, count, data
       3,    3, 0x0,    4,   31,

 // enum data: key, value
       5, uint(MyClass::High),
       6, uint(MyClass::Low),
       7, uint(MyClass::VeryHigh),
       8, uint(MyClass::VeryLow),

       0        // eod
};

void MyClass::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        MyClass *_t = static_cast<MyClass *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->priorityChanged((*reinterpret_cast< Priority(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (MyClass::*)(Priority );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MyClass::priorityChanged)) {
                *result = 0;
                return;
            }
        }
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty) {
        MyClass *_t = static_cast<MyClass *>(_o);
        Q_UNUSED(_t)
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< Priority*>(_v) = _t->priority(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        MyClass *_t = static_cast<MyClass *>(_o);
        Q_UNUSED(_t)
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setPriority(*reinterpret_cast< Priority*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    }
#endif // QT_NO_PROPERTIES
}

QT_INIT_METAOBJECT const QMetaObject MyClass::staticMetaObject = { {
    &QObject::staticMetaObject,
    qt_meta_stringdata_MyClass.data,
    qt_meta_data_MyClass,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *MyClass::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MyClass::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_MyClass.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int MyClass::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 1)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 1)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 1;
    }
#ifndef QT_NO_PROPERTIES
   else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 1;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 1;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void MyClass::priorityChanged(Priority _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
]]
