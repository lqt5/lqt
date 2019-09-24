if not path then
	path = '.'
end
-- compile script to bytecode
local compile = false

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

local lqt_embed = {}
local lqt_modules = {}

local function lua2h(input)
	local output = input .. '.h'
	local symbol = input:match('([%w_%d]+)%.lua$')

	log(' >> Parsing `%s`', input)
	local src = readFile(input)

	for mod in src:gmatch('require [%\']embed%.([%w%d_]+)[%\']') do
		if not lqt_modules[mod] then
			lqt_modules[mod] = mod

			table.insert(lqt_modules, mod)
			local module_path = input:gsub('([%w%d_]+)%.lua$', mod .. '.lua')
			lua2h(module_path)
		end
	end

	table.insert(lqt_embed
		, string.format('#include "%s"', output:gsub('.+/common/', ''))
	)

	if compile then
		-- do not strip debug info
		local func,err = loadstring(src, '@' .. input)
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

	saveFile(output, string.format([[static int luaopen_embed_%s(lua_State *L)
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
	, symbol
	, table.concat(bytes, '')
	, input
))
end

lua2h(string.format('%s/../common/embed/main.lua', path))

-- write main embed header
table.insert(lqt_embed, '')

table.insert(lqt_embed, [[static const luaL_Reg modules[] = {]])

for _,name in ipairs(lqt_modules) do
	table.insert(lqt_embed
		, string.format('    { "embed.%s", luaopen_embed_%s },', name, name)
	)
end

table.insert(lqt_embed, [[
    { 0, 0 }
};

static int luax_preload(lua_State *L, lua_CFunction f, const char *name)
{
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    lua_pushcfunction(L, f);
    lua_setfield(L, -2, name);
    lua_pop(L, 2);
    return 0;
}

static int luaopen_embed_preload(lua_State *L) {

    // Preload module loaders.
    for (int i = 0; modules[i].name != nullptr; i++)
        luax_preload(L, modules[i].func, modules[i].name);

	return 0;
}
]])

saveFile(string.format('%s/../common/lqt_embed.h', path)
	, table.concat(lqt_embed, '\n')
)
