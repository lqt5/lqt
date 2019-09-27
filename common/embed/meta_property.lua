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
--[[
function Class:__static_init()
    self:__addproperty('{type} {name}', {
        -- A READ accessor function is required if no MEMBER variable was specified.
        --  It is for reading the property value. Ideally, a const function is used for this purpose,
        --  and it must return either the property's type or a const reference to that type.
        --  e.g., QWidget::focus is a read-only property with READ function, QWidget::hasFocus().
        READ = self.getFunction,

        -- A MEMBER variable association is required if no READ accessor function is specified.
        --  This makes the given member variable readable and writable without the need of creating
        --  READ and WRITE accessor functions.
        --  It's still possible to use READ or WRITE accessor functions in addition to
        --  MEMBER variable association (but not both), if you need to control the variable access.
        MEMBER = 'memberName',

        -- A WRITE accessor function is optional.
        --  It is for setting the property value. It must return void and must take exactly one argument,
        --  either of the property's type or a pointer or reference to that type.
        --  e.g., QWidget::enabled has the WRITE function QWidget::setEnabled().
        --  Read-only properties do not need WRITE functions.
        --  e.g., QWidget::focus has no WRITE function.
        WRITE = self.setFunction,
  
        -- A RESET function is optional.
        --  It is for setting the property back to its context specific default value.
        --  e.g., QWidget::cursor has the typical READ and WRITE functions,
        --  QWidget::cursor() and QWidget::setCursor(), and it also has a RESET function,
        --  QWidget::unsetCursor(), since no call to QWidget::setCursor() can mean reset to the
        --  context specific cursor. The RESET function must return void and take no parameters.
        RESET = self.resetFunction,

        -- A NOTIFY signal is optional. If defined, it should specify one existing signal
        --  in that class that is emitted whenever the value of the property changes.
        --  NOTIFY signals for MEMBER variables must take zero or one parameter,
        --  which must be of the same type as the property.
        --  The parameter will take the new value of the property.
        --  The NOTIFY signal should only be emitted when the property has really been changed,
        --  to avoid bindings being unnecessarily re-evaluated in QML, for example.
        --  Qt emits automatically that signal when needed for MEMBER properties that
        --  do not have an explicit setter.
        NOTIFY = 'notifySignal({type})',

        -- A REVISION number is optional. If included,
        --  it defines the property and its notifier signal to be used in a particular revision
        --  of the API (usually for exposure to QML). If not included, it defaults to 0.
        REVERSION = num,

        -- The DESIGNABLE attribute indicates whether the property should be visible
        --  in the property editor of GUI design tool (e.g., Qt Designer).
        --  Most properties are DESIGNABLE (default true). Instead of true or false,
        --  you can specify a boolean member function.
        DESIGNABLE = true or false or self.isDesignableFunction,

        -- The SCRIPTABLE attribute indicates whether this property should be accessible
        --  by a scripting engine (default true). Instead of true or false,
        --  you can specify a boolean member function.
        SCRIPTABLE = true or false or self.isScriptableFunction,

        -- The STORED attribute indicates whether the property should be thought of as
        --  existing on its own or as depending on other values.
        --  It also indicates whether the property value must be saved when storing
        --  the object's state. Most properties are STORED (default true),
        --  but e.g., QWidget::minimumWidth() has STORED false, because its value is just
        --  taken from the width component of property QWidget::minimumSize(), which is a QSize.
        STORED = true or false,

        -- The USER attribute indicates whether the property is designated as the user-facing
        --  or user-editable property for the class. Normally,
        --  there is only one USER property per class (default false).
        --  e.g., QAbstractButton::checked is the user editable property for (checkable) buttons.
        --  Note that QItemDelegate gets and sets a widget's USER property.
        USER = true or false,

        -- The presence of the CONSTANT attribute indicates that the property value is constant.
        --  For a given object instance, the READ method of a constant property must return
        --  the same value every time it is called. This constant value may be different for
        --  different instances of the object. A constant property cannot have a WRITE method
        --  or a NOTIFY signal.
        CONSTANT = true or false,

        -- The presence of the FINAL attribute indicates that the property will not be
        --  overridden by a derived class. This can be used for performance optimizations in some cases,
        --  but is not enforced by moc. Care must be taken never to override a FINAL property.
        FINAL = true or false,
    })
end
]]
local QtCore

local bit = require 'bit'

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
    Class = QtCore.Class('MetaProperty')(Class)
end
local Fields = {
    READ = 'function',
    WRITE = 'function',
    NOTIFY = 'string',
    RESET = 'function',
    DESIGNABLE = { 'boolean', 'function' },
    SCRIPTABLE = { 'boolean', 'function' },
    STORED = { 'boolean', 'function' },
    USER = { 'boolean', 'function' },
    EDITABLE = { 'boolean', 'function' },
    REVERSION = 'number',
    CONSTANT = 'boolean',
    FINAL = 'boolean',
}
----------------------------------------------------------------------------------------------------
-- Parse property info
--
-- Q_PROPERTY(int intProperty READ intProperty WRITE setIntProperty NOTIFY intPropertyChanged)
--  10, QMetaType::Int, 0x00495103, // ResolveEditable Notify Designable Readable StdCppSet Stored Scriptable Writable
--
-- Q_PROPERTY(QString stringProperty MEMBER m_string WRITE setStringProperty RESET resetStringProperty)
--  11, QMetaType::QString, 0x00095107, // Resettable ResolveEditable Designable Readable StdCppSet Stored Scriptable Writable
--
-- Q_PROPERTY(bool boolProperty READ boolProperty REVISION 9527 FINAL)
--  12, QMetaType::Bool, 0x00895801, // ResolveEditable Designable Revisioned Readable Stored Scriptable Final
--
-- Q_PROPERTY(double doubleProperty MEMBER m_double WRITE setDoubleProperty NOTIFY doublePropertyChanged RESET resetDoubleProperty DESIGNABLE doublePropertyDesignable SCRIPTABLE doublePropertyScriptable STORED false USER false)
--  13, QMetaType::Double, 0x00485107, // Resettable ResolveEditable Notify Designable Readable StdCppSet Scriptable Writable
--
-- Q_PROPERTY(bool boolProperty READ boolProperty REVISION 9527 CONSTANT FINAL)
--  12, QMetaType::Bool, 0x00895c01, // ResolveEditable Designable Revisioned Readable Stored Scriptable Constant Final
----------------------------------------------------------------------------------------------------
local function parsePropertyInfo(name, info)
    local function check(cond, fmt, ...)
        if not cond then
            local errmsg = string.format(fmt, ...)
            error(string.format('`%s`: %s', name, errmsg))
        end
    end
    check(not (info.READ ~= nil and info.MEMBER ~= nil), 'READ/MEMBER conflict, only one of them can be used')
    check(info.READ or info.MEMBER, 'Missing field READ/MEMBER')
    check(not (info.CONSTANT and (info.WRITE or info.NOTIFY or info.RESET)), 'CONSTANT property can not use WRITE/NOTIFY/RESET')

    -- Validate info filed
    for key,types in pairs(Fields) do
        local val = info[key]
        local valType = type(val)

        if val == nil then
            -- ignore nil
        elseif type(types) == 'table' then
            local fail = true
            for _,tp in ipairs(types) do
                if valType == tp then
                    fail = false
                    break
                end
            end
            check(not fail, 'The field %s must be %s', key, table.concat(types, '/'))
        elseif valType ~= types then
            check(false, 'The field %s must be a %s', key, types)
        end
    end

    -- Wrap MEMBER reader function
    if info.MEMBER then
        info.READ = function(self)
            if self[info.MEMBER] == nil then
                error('No such member value named : ' .. info.MEMBER)
            end
            return self[info.MEMBER]
        end
    end

    -- Automate emit notify signal when value changed/reseted
    if info.NOTIFY then
        local function wrap(func)
            if not func then
                return
            end

            return function(self, ...)
                func(self, ...)

                local signal,args = string.match(info.NOTIFY, '^(.*)%((.*)%)$')
                if #args > 0 then
                    if select('#', ...) == 1 then
                        self:__emit(signal, { args, ... })
                    else
                        self:__emit(signal, { args, info.READ(self) })
                    end
                else
                    self:__emit(signal)
                end
            end
        end
        info.WRITE = wrap(info.WRITE)
        info.RESET = wrap(info.RESET)

        -- Automate emit notify signal when value changed/reseted
        if info.RESET then
            wrap(info.RESET)
        end
    end

    local flags = Flags.PropertyFlags.Readable

    if info.WRITE then
        flags = flags + Flags.PropertyFlags.Writable
        flags = flags + Flags.PropertyFlags.StdCppSet
    end

    if info.RESET then
        flags = flags + Flags.PropertyFlags.Resettable
    end

    -- EnumOrFlag = 0x00000008,
    -- -- Override = 0x00000200,

    if info.CONSTANT then
        flags = flags + Flags.PropertyFlags.Constant
    end

    if info.FINAL then
        flags = flags + Flags.PropertyFlags.Final
    end

    if info.DESIGNABLE == nil or info.DESIGNABLE then
        flags = flags + Flags.PropertyFlags.Designable
    end
    -- ResolveDesignable = 0x00002000,

    if info.SCRIPTABLE == nil or info.SCRIPTABLE then
        flags = flags + Flags.PropertyFlags.Scriptable
    end
    -- ResolveScriptable = 0x00008000,

    if info.STORED == nil or info.STORED then
        flags = flags + Flags.PropertyFlags.Stored
    end
    -- ResolveStored = 0x00020000,

    -- Editable = 0x00040000,
    if info.EDITABLE == nil or info.EDITABLE then
        flags = flags + Flags.PropertyFlags.ResolveEditable
    end

    if info.USER then
        flags = flags + Flags.PropertyFlags.User
    end
    -- ResolveUser = 0x00200000,

    if info.NOTIFY then
        flags = flags + Flags.PropertyFlags.Notify
    end

    if info.REVERSION then
        flags = flags + Flags.PropertyFlags.Revisioned
    end

    return flags, info.REVERSION or 0, {
        info.NOTIFY or false,
        info.READ or false,
        info.WRITE or false,
        info.RESET or false,
        info.DESIGNABLE or true,
        info.SCRIPTABLE or true,
        info.STORED or false,
        info.EDITABLE or false,
        info.USER or false,
    }
end
----------------------------------------------------------------------------------------------------
-- Constructor
----------------------------------------------------------------------------------------------------
function Class:__init(metaStrings, type, name, info)
    -- Meta strings
    self.metaStrings = metaStrings
    -- Property type
    self.type = type
    -- Property name
    self.name = name
    -- Property name string index
    self.nameIndex = metaStrings:insert(name)

    -- Parse property info
    local flags,revision,routines = parsePropertyInfo(name, info)
    -- Insert property type to routines, used in lqt_metacall.cpp
    table.insert(routines, 1, type)

    -- Property flags
    self.flags = flags
    -- Property revision
    self.revision = revision
    -- Routines/callbacks { READ, WRITE, NOTIFY, DESIGNABLE, SCRIPTABLE }
    self.routines = routines
end
----------------------------------------------------------------------------------------------------
-- Get notify signal id
----------------------------------------------------------------------------------------------------
function Class:getNotifyId(metaData)
    if bit.band(self.flags, Flags.PropertyFlags.Notify) == 0 then
        return 0
    end
    local notifySignal = self.routines[2]

    for idx,method in pairs(metaData.methods) do
        if method.signature == notifySignal then
            return idx - 1
        end
    end
    error(string.format('Unknown property `%s` notify id: `%s`'
        , self.name
        , notifySignal
    ))
end

return Class
