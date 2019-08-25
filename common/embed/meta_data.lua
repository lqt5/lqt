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

local bit = require 'bit'

local Flags = require 'embed.flags'
local MetaMethod = require 'embed.meta_method'
local MetaProperty = require 'embed.meta_property'
----------------------------------------------------------------------------------------------------
-- Meta string container
----------------------------------------------------------------------------------------------------
local Class = {}
----------------------------------------------------------------------------------------------------
-- Setup locals from lqt_embed.cpp
----------------------------------------------------------------------------------------------------
function Class.setup(...)
    QtCore = ...
    Class = QtCore.Class('MetaData')(Class)

    MetaMethod.setup(...)
    MetaProperty.setup(...)
end
----------------------------------------------------------------------------------------------------
-- Constructor
----------------------------------------------------------------------------------------------------
function Class:__init(owner, metaStrings, clone)
    -- data ownerd class
    self.owner = owner
    -- meta strings
    self.metaStrings = metaStrings
    -- store added methods
    self.methods = {}
    -- store added properties
    self.properties = {}
    -- Copy for super data
    if clone then
        for _,val in pairs(clone.methods) do
            -- ref to MetaMethod (readonly!)
            table.insert(self.methods, val)
        end
        for _,val in pairs(clone.properties) do
            -- ref to MetaMethod (readonly!)
            table.insert(self.properties, val)
        end
    end
end
----------------------------------------------------------------------------------------------------
-- Return methods(signal/slot) count
----------------------------------------------------------------------------------------------------
function Class:methodCount()
    return #self.methods
end
----------------------------------------------------------------------------------------------------
-- Add method(signal/slot)
----------------------------------------------------------------------------------------------------
function Class:addMethod(signature, access, func)
    local index = #self.methods
    -- makes slot order after signal
    if func then
        index = index + 0x80000000
    end

    local methodInfo = MetaMethod(index, self.metaStrings
        , signature
        , access
        , func
    )
    methodInfo:build()

    table.insert(self.methods, methodInfo)

    -- sort methods
    table.sort(self.methods, function(left, right)
        return left.index < right.index
    end)
end
----------------------------------------------------------------------------------------------------
-- Add property
----------------------------------------------------------------------------------------------------
function Class:addProperty(type, name, info)
    local property = MetaProperty(self.metaStrings, type, name, info)
    table.insert(self.properties, property)
end
----------------------------------------------------------------------------------------------------
-- Build meta data
----------------------------------------------------------------------------------------------------
function Class:build()
    -- Get meta methods(slot) table
    local metaMethods = self.methods

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
        self:methodCount(), 14, -- methods(count, offset)
        #self.properties, 0,    -- properties
        0, 0,                   -- enums/sets
        0, 0,                   -- constructors
        0,                      -- flags
        0,                      -- signalCount
        -- Qt5 meta method data
    } do
        table.insert(self, val)
    end

    local metaSlots = {}
    local metaSignals = {}
    local metaProperties = {}

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

    local offset = #self + (self:methodCount() * MetaMethod.headerSize())

    local signalCount = 0
    -- build signal/slot methods data
    --  signals: name, argc, parameters, tag, flags
    --  slots: name, argc, parameters, tag, flags
    for _,methodInfo in ipairs(metaMethods) do
        -- write meta header data
        offset = methodInfo:writeHeader(self, offset)
        -- no func, is an signal
        if not methodInfo.func then
            signalCount = signalCount + 1
        end
        -- add lqt signal/slot func
        addSignalSlot(methodInfo.signature, methodInfo.func)
    end
    self[14] = signalCount

    -- build singal/slot parameters data(ReturnType/ParamTypes[]/NameIndies[])
    -- signals/slots: parameters
    --  return_type param_types[argc] string_index[args]
    for _,methodInfo in ipairs(metaMethods) do
        -- Write method parameter data
        methodInfo:writeParameter(self)
    end

    -- write properties data offset
    self[8] = offset

    local property_notify = false
    local property_revision = false
    -- properties: name, type, flags
    for _,property in ipairs(self.properties) do
        table.insert(self, property.nameIndex)
        table.insert(self, property.type)
        table.insert(self, property.flags)

        table.insert(metaProperties, property.routines)

        if not property_notify and bit.band(property.flags, Flags.PropertyFlags.Notify) ~= 0 then
            property_notify = true
        end

        if not property_revision and bit.band(property.flags, Flags.PropertyFlags.Revisioned) ~= 0 then
            property_revision = true
        end
    end

    -- properties: notify_signal_id
    if property_notify then
        for _,property in ipairs(self.properties) do
            local id = property:getNotifyId(self)
            table.insert(self, id)
        end
    end

    -- properties: revision
    if property_revision then
        for _,property in ipairs(self.properties) do
            table.insert(self, property.revision)
        end
    end

    -- eod
    table.insert(self, 0)

    return metaSlots, metaSignals, metaProperties
end

return Class
--[[
#ifndef MYCLASS_H
#define MYCLASS_H

#include <QObject>
#include <QString>

class MyClass : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int intProperty READ intProperty WRITE setIntProperty NOTIFY intPropertyChanged)
    Q_PROPERTY(QString stringProperty MEMBER m_string WRITE setStringProperty RESET resetStringProperty)
    Q_PROPERTY(bool boolProperty READ boolProperty REVISION 9527 FINAL)
    Q_PROPERTY(double doubleProperty MEMBER m_double WRITE setDoubleProperty NOTIFY doublePropertyChanged RESET resetDoubleProperty DESIGNABLE doublePropertyDesignable SCRIPTABLE doublePropertyScriptable STORED false USER false)

public:
    explicit MyClass(QObject *parent = nullptr) : QObject(parent) {}

    void setText(const QString &text);

    int intProperty() const { return m_int; }
    void resetStringProperty() {}
    bool boolProperty() const { return m_bool; }
    void resetDoubleProperty() {}

public slots:
    void setIntProperty(int value) { m_int = value; }
    void setStringProperty(const QString& value) { m_string = value; }
    void setDoubleProperty(double value) { m_double = value; }

signals:
    void intPropertyChanged(int);
    void textChanged(const QString &text);
    void doublePropertyChanged(const double& value);

private:
    bool m_bool;
    int m_int;
    QString m_string;
    double m_double;
};

#endif // MYCLASS_H

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
    QByteArrayData data[14];
    char stringdata0[179];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_MyClass_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_MyClass_t qt_meta_stringdata_MyClass = {
    {
QT_MOC_LITERAL(0, 0, 7), // "MyClass"
QT_MOC_LITERAL(1, 8, 18), // "intPropertyChanged"
QT_MOC_LITERAL(2, 27, 0), // ""
QT_MOC_LITERAL(3, 28, 11), // "textChanged"
QT_MOC_LITERAL(4, 40, 4), // "text"
QT_MOC_LITERAL(5, 45, 21), // "doublePropertyChanged"
QT_MOC_LITERAL(6, 67, 5), // "value"
QT_MOC_LITERAL(7, 73, 14), // "setIntProperty"
QT_MOC_LITERAL(8, 88, 17), // "setStringProperty"
QT_MOC_LITERAL(9, 106, 17), // "setDoubleProperty"
QT_MOC_LITERAL(10, 124, 11), // "intProperty"
QT_MOC_LITERAL(11, 136, 14), // "stringProperty"
QT_MOC_LITERAL(12, 151, 12), // "boolProperty"
QT_MOC_LITERAL(13, 164, 14) // "doubleProperty"

    },
    "MyClass\0intPropertyChanged\0\0textChanged\0"
    "text\0doublePropertyChanged\0value\0"
    "setIntProperty\0setStringProperty\0"
    "setDoubleProperty\0intProperty\0"
    "stringProperty\0boolProperty\0doubleProperty"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_MyClass[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
       6,   14, // methods
       4,   62, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       3,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   44,    2, 0x06 /* Public */,
       3,    1,   47,    2, 0x06 /* Public */,
       5,    1,   50,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
       7,    1,   53,    2, 0x0a /* Public */,
       8,    1,   56,    2, 0x0a /* Public */,
       9,    1,   59,    2, 0x0a /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::Int,    2,
    QMetaType::Void, QMetaType::QString,    4,
    QMetaType::Void, QMetaType::Double,    6,

 // slots: parameters
    QMetaType::Void, QMetaType::Int,    6,
    QMetaType::Void, QMetaType::QString,    6,
    QMetaType::Void, QMetaType::Double,    6,

 // properties: name, type, flags
      10, QMetaType::Int, 0x00495103, // ResolveEditable Notify Designable Readable StdCppSet Stored Scriptable Writable
      11, QMetaType::QString, 0x00095107, // Resettable ResolveEditable Designable Readable StdCppSet Stored Scriptable Writable
      12, QMetaType::Bool, 0x00895801, // ResolveEditable Designable Revisioned Readable Stored Scriptable Final
      13, QMetaType::Double, 0x00485107, // Resettable ResolveEditable Notify Designable Readable StdCppSet Scriptable Writable

 // properties: notify_signal_id
       0,
       0,
       0,
       2,

 // properties: revision
       0,
       0,
    9527,
       0,

       0        // eod
};

void MyClass::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        MyClass *_t = static_cast<MyClass *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->intPropertyChanged((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 1: _t->textChanged((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 2: _t->doublePropertyChanged((*reinterpret_cast< const double(*)>(_a[1]))); break;
        case 3: _t->setIntProperty((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 4: _t->setStringProperty((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 5: _t->setDoubleProperty((*reinterpret_cast< double(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (MyClass::*)(int );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MyClass::intPropertyChanged)) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (MyClass::*)(const QString & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MyClass::textChanged)) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (MyClass::*)(const double & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MyClass::doublePropertyChanged)) {
                *result = 2;
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
        case 0: *reinterpret_cast< int*>(_v) = _t->intProperty(); break;
        case 1: *reinterpret_cast< QString*>(_v) = _t->m_string; break;
        case 2: *reinterpret_cast< bool*>(_v) = _t->boolProperty(); break;
        case 3: *reinterpret_cast< double*>(_v) = _t->m_double; break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        MyClass *_t = static_cast<MyClass *>(_o);
        Q_UNUSED(_t)
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setIntProperty(*reinterpret_cast< int*>(_v)); break;
        case 1: _t->setStringProperty(*reinterpret_cast< QString*>(_v)); break;
        case 3: _t->setDoubleProperty(*reinterpret_cast< double*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
        MyClass *_t = static_cast<MyClass *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 1: _t->resetStringProperty(); break;
        case 3: _t->resetDoubleProperty(); break;
        default: break;
        }
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
        if (_id < 6)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 6)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 6;
    }
#ifndef QT_NO_PROPERTIES
   else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        bool *_b = reinterpret_cast<bool*>(_a[0]);
        switch (_id) {
        case 3: *_b = doublePropertyDesignable(); break;
        default: break;
        }
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        bool *_b = reinterpret_cast<bool*>(_a[0]);
        switch (_id) {
        case 3: *_b = doublePropertyScriptable(); break;
        default: break;
        }
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 4;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void MyClass::intPropertyChanged(int _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void MyClass::textChanged(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void MyClass::doublePropertyChanged(const double & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
]]
