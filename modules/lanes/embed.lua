-- compile script to bytecode
local compile = true

local modules = {
	{ 'src/lanes', 'lanes' },
}

local lqt_embed = {
	'#include <lua.h>',
	'#include <lualib.h>',
	'#include <lauxlib.h>',
}

local out_path = arg[1]
if not out_path then
	out_path = '.'
end

local in_path = arg[2]
if not in_path then
	in_path = '../src/lanes'
end

local function log(fmt, ...)
	print(string.format(fmt, ...))
end

local function readFile(path)
	local fp = assert(io.open(path, 'rb'), 'Unable to open file : ' .. path)
	local src = fp:read '*all'
	fp:close()
	return src
end

local function saveFile(path, data)
	local fp = assert(io.open(path, 'wb'), 'Unable to save file : ' .. path)
	fp:write(data)
	fp:close()
end

local function lua2h(input_path, output_path, ident, module_name)
	log(' >> Parsing `%s`', input_path)
	local src = readFile(input_path)

	table.insert(lqt_embed
		, string.format('#include "embed_%s.h"', ident)
	)

	if compile then
		-- do not strip debug info
		local func,err = loadstring(src, '@' .. input_path)
		if err then error(err) end
		src = string.dump(func, false)
	end

	local bytes = {}
	src:gsub('.', function(c)
		if #bytes == 0 then
			table.insert(bytes, '\t\t')
		end
		table.insert(bytes, string.format('%d, ', string.byte(c)))
		-- add newline every 16 bytes
		if #bytes % 17 == 16 then
			table.insert(bytes, '\n\t\t')
		end
	end)

	saveFile(output_path, string.format([[LUA_API int luaopen_%s(lua_State *L)
{
	static const unsigned char code[] = {
%s
	};

    if (luaL_loadbuffer(L, (const char *)code, sizeof(code), (const char *)"@%s") != 0)
        lua_error(L);

    if (lua_pcall(L, 0, LUA_MULTRET, 0) != 0)
        lua_error(L);

    return 1;
}
]]
		, ident
		, table.concat(bytes, '')
		, input_path
	))
	end

for _,info in ipairs(modules) do
	local input_path = string.format('%s/%s.lua', in_path, info[1])
	local ident = info[2]:gsub('%.', '_')
	local output_path = string.format('%s/embed_%s.h', out_path, ident)
	print(string.format('Convert %s -> %s', input_path, output_path))
	lua2h(input_path, output_path, ident, info[2])
end

table.insert(lqt_embed, '')

saveFile(string.format('%s/embed.c', out_path)
	, table.concat(lqt_embed, '\n')
)
