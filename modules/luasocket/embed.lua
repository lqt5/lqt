-- compile script to bytecode
local compile = true

local modules = {
	{ 'src/ftp', 'socket.ftp' },
	{ 'src/headers', 'socket.headers' },
	{ 'src/http', 'socket.http' },
	{ 'src/ltn12', 'socket.ltn12' },
	{ 'src/mbox', 'socket.mbox' },
	{ 'src/mime', 'socket.mime' },
	{ 'src/smtp', 'socket.smtp' },
	{ 'src/socket', 'socket', },
	{ 'src/tp', 'socket.tp', },
	{ 'src/url', 'socket.url' },
	-- { 'etc/dict', 'socket.dict' },
	-- { 'etc/lp', 'socket.lp' },
	-- { 'etc/tftp', 'socket.tftp' },
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
	in_path = '../src/luasocket/src'
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

-- local lqt_embed = {}
-- local lqt_modules = {}

-- local function lua2h(input)
-- end

-- lua2h(string.format('%s/../common/embed/main.lua', path))

-- write main embed header
table.insert(lqt_embed, '')

-- table.insert(lqt_embed, [[static const luaL_Reg modules[] = {]])

-- for _,info in ipairs(modules) do
-- 	local module_name = info[2]
-- 	table.insert(lqt_embed
-- 		, string.format('    { "%s", luaopen_%s },', module_name, module_name:gsub('%.', '_'))
-- 	)
-- end

-- table.insert(lqt_embed, [[
--     { 0, 0 }
-- };

-- static int luax_preload(lua_State *L, lua_CFunction f, const char *name)
-- {
--     lua_getglobal(L, "package");
--     lua_getfield(L, -1, "preload");
--     lua_pushcfunction(L, f);
--     lua_setfield(L, -2, name);
--     lua_pop(L, 2);
--     return 0;
-- }

-- static int luaopen_embed_preload(lua_State *L) {

--     // Preload module loaders.
--     for (int i = 0; modules[i].name != NULL; i++)
--         luax_preload(L, modules[i].func, modules[i].name);

-- 	return 0;
-- }
-- ]])

saveFile(string.format('%s/embed.c', out_path)
	, table.concat(lqt_embed, '\n')
)
