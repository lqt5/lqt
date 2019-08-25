#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require 'qtcore'

local qa = QtCore.QCoreApplication.new(1, {'test_property'})

local Object = QtCore.Class('Object', QtCore.QObject) {}

function Object:__static_init()
	self:__addsignal('intPropertyChanged(int)', 'public')
	self:__addsignal('doublePropertyChanged(double)', 'public')
	self:__addsignal('objectPropertyChanged(QObject*)', 'public')

	self:__addslot('setIntProperty(int)', self.setIntProperty, 'public')
	self:__addslot('setStringProperty(QString)', self.setStringProperty, 'public')
	self:__addslot('setDoubleProperty(double)', self.setDoubleProperty, 'public')

	self:__addproperty('int intProperty', {
		READ = self.intProperty,
		WRITE = self.setIntProperty,
		NOTIFY = 'intPropertyChanged(int)',
	})
	self:__addproperty('QString stringProperty', {
		-- MEMBER = 'stringValue',
		READ = self.stringProperty,
		WRITE = self.setStringProperty,
		RESET = self.resetStringProperty,
	})
	self:__addproperty('bool boolProperty', {
		READ = self.boolProperty,
		REVERSION = 9527,
		FINAL = true,
		-- CONSTANT = true,
	})
	self:__addproperty('double doubleProperty', {
		MEMBER = 'doubleValue',
		WRITE = self.setDoubleProperty,
		NOTIFY = 'doublePropertyChanged(double)',
		RESET = self.resetDoubleProperty,
		DESIGNABLE = self.doublePropertyDesignable,
		SCRIPTABLE = self.doublePropertyScriptable,
		STORED = self.doublePropertyStored,
		EDITABLE = self.doublePropertyEditable,
		USER = self.doublePropertyUser,
	})
	self:__addproperty('QObject* objectProperty', {
		READ = self.objectProperty,
		WRITE = self.setObjectProperty,
		NOTIFY = 'objectPropertyChanged(QObject*)',
	})
end

function Object:__init()
	self:setObjectName('Object')

	self.intValue = 0
	self.stringValue = 'initial string'
	self.boolValue = true
	self.doubleValue = 0
	self.objectValue = false

	self:connect(SIGNAL 'doublePropertyChanged(double)', function(_,val)
		print('doublePropertyChanged(double)', val)
	end)
end

function Object:intProperty()
	return self.intValue
end

function Object:setIntProperty(value)
	self.intValue = value
end

function Object:stringProperty()
	return self.stringValue
end

function Object:setStringProperty(value)
	self.stringValue = value
end

function Object:resetStringProperty()
	self.stringValue = ''
end

function Object:boolProperty()
	return self.boolValue
end

function Object:setDoubleProperty(value)
	self.doubleValue = value
end

function Object:resetDoubleProperty()
	self.doubleValue = 0
end

function Object:doublePropertyDesignable()
	return true
end

function Object:doublePropertyScriptable()
	return false
end

function Object:doublePropertyStored()
	return true
end

function Object:doublePropertyEditable()
	return false
end

function Object:doublePropertyUser()
	return true
end

function Object:objectProperty()
	return self.objectValue or nil
end

function Object:setObjectProperty(value)
	self.objectValue = value or false
end

-- for name,func in pairs(Object) do
-- 	if type(func) == 'function' then
-- 		Object[name] = function(...)
-- 			print('invoke', name, ...)
-- 			return func(...)
-- 		end
-- 	end
-- end

local obj = Object()

local v = QtCore.QVariant()
v:setValue(obj)
assert(v:value() == obj)

print(obj:property('objectName'):value():toStdString())

print(obj:property('stringProperty'):value():toStdString())
obj:setProperty('stringProperty', QtCore.QString 'hello, world')
print(obj:property('stringProperty'):value():toStdString())

obj:setProperty('intProperty', 9527)
print(obj:property('intProperty'):value())

local metaObject = obj:metaObject()
local metaProperty = metaObject:property(metaObject:indexOfProperty('doubleProperty'))
print(metaProperty:isDesignable(obj)
	, metaProperty:isScriptable(obj)
	, metaProperty:isStored(obj)
	, metaProperty:isEditable(obj)
	, metaProperty:isUser(obj)
)
metaProperty:reset(obj)

obj:setProperty('doubleProperty', 3.14)
print(obj:property('doubleProperty'):value())

local metaObject = obj:metaObject()
for i = 1,metaObject:propertyCount() do
	local property = metaObject:property(i - 1)
	print(property:typeName(), property:name(), property:read(obj):value())
end
