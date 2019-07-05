package.cpath = package.cpath .. ';../build/lib/?.so'

local QtCore = require 'qtcore'
local QtSql = require 'qtsql'

local db = QtSql.QSqlDatabase.addDatabase("QSQLITE", "conn1")
db:setDatabaseName("numbers.db")
if not db:open() then
	local err = db:lastError()
	print('!!!', err:text():toLocal8Bit())
end
print('ok', db)

db:exec("CREATE TABLE IF NOT EXISTS tab (n INT)")

local q = QtSql.QSqlQuery(db)
q:prepare("INSERT INTO tab VALUES (:n)")

for i=1,10 do
	q:bindValue("n", QtCore.QVariant(i))
	q:exec()
end

local q2 = QtSql.QSqlQuery(db)
q2:exec("SELECT * FROM tab")
while q2:next() do
	local v = q2:value(0)
	print(v:toInt())
end
