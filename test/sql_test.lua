#!/usr/bin/lua
dofile(arg[0]:gsub('test[/\\].+', 'examples/init.lua'))

local QtCore = require 'qtcore'
local QtSql = require 'qtsql'

local db = QtSql.QSqlDatabase.addDatabase('QSQLITE', 'CONN1')
db:setDatabaseName(':memory:')
if not db:open() then
	local err = db:lastError()
	print('!!!', err:text():toLocal8Bit())
end

print('ok', db)

db:exec('CREATE TABLE IF NOT EXISTS tab (n INT)')

local q = QtSql.QSqlQuery(db)
q:prepare('INSERT INTO tab VALUES (:n)')

for i=1,10 do
	local v = QtCore.QVariant(i)
	q:bindValue(':n', v)
	q:exec()
end

local q2 = QtSql.QSqlQuery(db)
q2:exec('SELECT * FROM tab')
while q2:next() do
	local v = q2:value('n')
	print(v:toInt())
end

-- TODO:fix crash (comment this line)
os.exit()
