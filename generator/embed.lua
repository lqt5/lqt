if not path then
	path = '.'
end

-- generate ../common/lqt_addmethod.h
print '\tGenerate common/lqt_addmethod.h'
local fp = io.open(string.format('%s/../common/lqt_addmethod.lua', path), 'rb')
local script = fp:read '*all'
fp:close()

-- script = string.dump(loadstring(script, '@common/lqt_addmethod.lua'), false)

local bytes = {}
script:gsub('.', function(c)
	if #bytes == 0 then
		table.insert(bytes, '\t')
	end
	table.insert(bytes, string.format('%d, ', string.byte(c)))
	-- table.insert(bytes, string.format('0x%02X, ', string.byte(c)))
	if #bytes % 17 == 16 then
		table.insert(bytes, '\n\t')
	end
end)

fp = io.open(string.format('%s/../common/lqt_addmethod.h', path), 'wb')
fp:write(string.format('static const unsigned char add_method_string[] = {\n%s\n};\n'
	, table.concat(bytes, '')
))
fp:close()
