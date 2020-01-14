#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require'qtcore'

local tag = 'ShareMemory@Key'

local sm = QtCore.QSharedMemory(tag)
sm:create(1024, 'ReadWrite')

print(sm)

local sm2 = QtCore.QSharedMemory(tag)
sm2:attach 'ReadWrite'

local ffi = require 'ffi'
ffi.cdef [[
typedef struct {
  int req;
  int resp;
  char data[1000];
} Singleton;
]]

local sp = ffi.cast('Singleton *', sm:data())
local sp2 = ffi.cast('Singleton *', sm2:data())

sp.req = 1
sp.resp = 2
sp.data = 'hello, world'

-- sm:delete()

-- sm = nil

-- collectgarbage()

print(sp2.req, sp2.resp, ffi.string(sp2.data))

-- local sm3 = QtCore.QSharedMemory(tag)
-- sm3:attach 'ReadWrite'
