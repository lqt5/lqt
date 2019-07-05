package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'

local s = tostring{}

local f = QtCore.QFile('tmp_file')
print('open file => ', f:open{'WriteOnly'})
print('write to file => ', f:write(s))
print('flush file =>', f:flush())
print('close file => ', f:close())
print('reopen file =>', f:open{'ReadOnly'})
print('correct read => ', f:readAll()==s)
