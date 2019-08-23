#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require 'qtcore'

local Base = QtCore.Class('Base') {
    __static_init = function(self)
        print('Base __static_init', self)
    end,
    __init = function(self, name)
        print('Base __init', self)
        self.name = name
    end,
    dumpBase = function(self)
        table.foreach(self, print)
    end,
}

local Super
Super = QtCore.Class('Super', Base) {
    __static_init = function(self)
        print('Super __static_init', self)
    end,
    __init = function(self, name, id)
        Super.__super.__init(self, name)
        print('Super __init', self)
        self.id = id
    end,
    __uninit = function(self)
        print('__uninit', self)
    end,
    dumpSuper = function(self)
        self:dumpBase()
    end,
}

local Child
Child = QtCore.Class('Child', Super) {
    __static_init = function(self)
        print('Child __static_init', self)
    end,
    __init = function(self, name, id, hp)
        print('Child _init', self)
        Child.__super.__init(self, name, id)
        self.hp = hp
    end,
    __uninit = function(self)
        print('__uninit', self)
    end,
    dumpChild = function(self)
        self:dumpSuper()
    end,
}

local function testLocalCtor()
    local base = Base('base')
    print('>> dump base <<')
    base:dumpBase()

    local super = Super('super', 10086)
    print('>> dump super <<')
    super:dumpSuper()

    local child = Child('child', 9527, 3.1415926)
    print('>> dump child <<')
    child:dumpChild()

    print('>> isLua <<')
    print(base.__lua)
    print(super.__lua)
    print(child.__lua)

    print('>> isClass/isObject <<')
    assert(QtCore.isClass(Base))
    print(base.__class)
    assert(not QtCore.isClass(base))

    assert(not QtCore.isObject(Base))
    assert(QtCore.isObject(base))

    print('>> isInstanceOf <<')
    assert(QtCore.isInstanceOf(base, Base))
    assert(QtCore.isInstanceOf(super, Base))

    assert(not QtCore.isInstanceOf(super, Child))

    assert(QtCore.isInstanceOf(child, Super))
    assert(QtCore.isInstanceOf(child, Child))

    assert(not QtCore.isInstanceOf(base, Super))
    assert(not QtCore.isInstanceOf(child, QtCore.QObject))
end
testLocalCtor()

local function testNew()
    local base = Base.new({}, 'base')
    local super = Super.new({}, 'super', 10086)
    local child = Child.new({}, 'child', 9527, 3.1415926)
end
testNew()
