#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require 'qtcore'
-- require 'class'

local object = QtCore.QObject()
object:__addsignal('clicked()')
object:__addslot('echo()', function() print 'echo' end)
object:connect('2clicked()', object, '1echo()')

object:__emit('clicked')
local app = QtCore.QCoreApplication.new(1, {'test_class'})

local Base = QtCore.Class('Base', QtCore.QObject) {
    __static_init = function(self)
        print('Base __static_init', self)
        self:__addsignal('BaseSignal()')
        self:__addslot('BaseSlot()', function() print 'BaseSlot' end)
    end,
    __init = function(self, name)
        print('Base __init', self)
        self.name = name
        -- table.foreach(self:__methods(), print)
        -- print(debug.traceback())
        self:connect('2BaseSignal()', self, '1BaseSlot()')
    end,
    __uninit = function(self)
        print('__uninit', self)
    end,
    dumpBase = function(self)
        table.foreach(debug.getfenv(self), print)
    end,
    emit = function(self)
        self:__emit('BaseSignal')
    end,
}

local Super
Super = QtCore.Class('Super', Base) {
    __static_init = function(self)
        print('Super __static_init', self)
        self:__addsignal('SuperSignal()')
        self:__addslot('SuperSlot()', function() print 'SuperSlot' end)
    end,
    __init = function(self, name, id)
        Super.__super.__init(self, name)
        print('Super __init', self)
        self.id = id
        self:connect('2SuperSignal()', self, '1SuperSlot()')
    end,
    __uninit = function(self)
        print('__uninit', self)
    end,
    dumpSuper = function(self)
        self:dumpBase()
        -- Super.__super.dumpBase(self)
    end,
    emit = function(self)
        -- print('>> Super emit BaseSignal <<')
        -- self:__emit('BaseSignal')
        -- print('>> Super emit SuperSignal <<')
        -- self:__emit('SuperSignal')
        Super.__super.emit(self)
        self:__emit('SuperSignal')
        -- print(Super.__super.emit)
    end,
}

local Child
Child = QtCore.Class('Child', Super) {
    __static_init = function(self)
        print('Child __static_init', self)
        self:__addsignal('ChildSignal()')
        self:__addslot('ChildSlot()', function() print 'ChildSlot' end)
    end,
    __init = function(self, name, id, hp)
        Child.__super.__init(self, name, id)
        self.hp = hp
        self:connect('2ChildSignal()', self, '1ChildSlot()')
    end,
    __uninit = function(self)
        print('__uninit', self)
    end,
    dumpChild = function(self)
        self:dumpSuper()
        -- Child.__super.dumpSuper(self)
    end,
    emit = function(self)
        -- self:__emit('BaseSignal')
        -- self:__emit('SuperSignal')
        -- self:__emit('ChildSignal')
        Child.__super.emit(self)
        self:__emit('ChildSignal')
        -- print(Child.__super.__name)
    end,
}

local function testLocalCtor()
    local base = Base({}, 'base')
    print('>> dump base <<')
    base:dumpBase()

    local super = Super({}, 'super', 10086)
    print('>> dump super <<')
    super:dumpSuper()

    local child = Child({}, 'child', 9527, 3.1415926)
    print('>> dump child <<')
    child:dumpChild()

    print('>> base methods <<')
    table.foreach(base:__methods(), print)

    print('>> super methods <<')
    table.foreach(super:__methods(), print)

    print('>> child methods <<')
    table.foreach(child:__methods(), print)

    print('>> test signal/slot <<')
    base:emit()
    print ''
    super:emit()
    print ''
    child:emit()

    print('>> isClass/isObject <<')
    print(QtCore.isClass(Base))
    print(QtCore.isClass(base))

    print(QtCore.isObject(Base))
    print(QtCore.isObject(base))

    print('>> isInstanceOf <<')
    print(QtCore.isInstanceOf(base, Base))
    print(QtCore.isInstanceOf(super, Base))

    print(QtCore.isInstanceOf(super, Child))

    print(QtCore.isInstanceOf(child, Super))
    print(QtCore.isInstanceOf(child, Child))

    print(QtCore.isInstanceOf(base, Super))
    print(QtCore.isInstanceOf(child, QtCore.QObject))

    print(QtCore.isInstanceOf(app, QtCore.QObject))
    print(QtCore.isInstanceOf(app, QtCore.QCoreApplication))
end
testLocalCtor()

local function testNew()
    local base = Base.new({}, 'base')
    local super = Super.new({}, 'super', 10086)
    local child = Child.new({}, 'child', 9527, 3.1415926)
end
testNew()

print('>> new objects(before gc) <<')
table.foreach(debug.getregistry()['Registry Ref Class'], print)

print('>> start gc <<')
collectgarbage()
print('>> end gc <<')

print('>> new objects(after gc) <<')
table.foreach(debug.getregistry()['Registry Ref Class'], print)
