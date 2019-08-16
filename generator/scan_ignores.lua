dofile(arg[0]:gsub('generator[/\\].+', 'examples/init.lua'))

local lfs = require 'lfs'

local function readLines(fullPath)
	local fp = io.open(fullPath, 'rb')
	local src = fp:read '*all'
	fp:close()
	return src
end

local cache = {}

local function scanTemplate(mod, source, ret)
	ret = ret or {}
	local list = {}
	table.insert(ret, {
		mod = mod,
		list = list,
	})

	for t,p in source:gmatch('(Q[%w]+)<([%w%*,%s]+)>\n') do
		local name = string.format('%s<%s>', t, p)
		if not cache[name]
			and not p:find('T$')
			and not p:find('^T')
			and not p:find(',T,')
			and not p:find('^E')
			and not p:find('^A,')
			and not p:find('^Key,')
			and not p:find('^N')
			and #p > 1
			and p ~= 'void'
		then
			cache[name] = true
			table.insert(list, name)
		end
	end
	return ret
end

local modules = {}
for name in lfs.dir('../build') do
	local mod = name:match('^ignores_(qt.+)%.csv$')
	if mod then
		local fullPath = string.format('../build/%s', name)
		table.insert(modules, {
			mod = mod,
			fullPath = fullPath,
		})
	end
end
local orders = {
	'qtcore',
	'qtnetwork',
	'qtsql',
	'qtpositioning',
	'qtqml',
	'qtgui',
	'qtwidgets',
	'qtopengl',
	'qtprintsupport',
	'qtuitools',
	'qtquick',
	'qtquickwidgets',
	'qtwebchannel',
	'qtwebenginecore',
	'qtwebenginewidgets',
	'qtscript',
	'qtscripttools',
	'qttest',
}
for i,k in ipairs(orders) do
	orders[k] = i
end

table.sort(modules, function(left, right)
	return (orders[left.mod] or math.huge) < (orders[right.mod] or math.huge)
end)

local results = {}
for _,m in ipairs(modules) do
	local source = readLines(m.fullPath)
	scanTemplate(m.mod, source, results)
end

for _,info in ipairs(results) do
	local mod = info.mod
	local list = info.list
	table.sort(list)
	for _,name in ipairs(list) do
		print(string.format("%s\t'%s',", mod,name))
	end
end
