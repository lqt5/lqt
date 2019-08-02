package.cpath = package.cpath .. ';../build/lib/?.so'

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
	-- TODO:why string placeholder not works fine?
	-- q:bindValue('n', v)
	-- print(q:boundValue('n'):type())
	q:bindValue(0, v)
	print(q:boundValue(0):type())
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
