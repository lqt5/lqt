module("enums", package.seeall)

local print_enum = fprint(assert(io.open(module_name.._src..module_name..'_enum.cpp', 'w')))


local function filter(enum)
	local c = fullnames[enum.xarg.context]
	if c.xarg.access == 'private' then
		return true
	end
	-- local n = enum.xarg.name
	-- if n~=string.lower(n) and not string.match(n, '_') then
		return false
	-- end
	-- return true
end

local enum_list = {}

local function copy_enums(index)
	for e in pairs(index) do
		if e.label=='Enum'
			and not string.match(e.xarg.fullname, '%b<>') then
			if e.xarg.access=='public' and not filter(e) then
				enum_list[e.xarg.fullname] = e
			elseif e.xarg.access == 'protected' then
				-- register it anyway
				enum_list[e.xarg.fullname] = e
				local c = fullnames[e.xarg.context]
				assert(type(c) == "table" and c.label == "Class", "cannot find parent of enum "..e.xarg.fullname)
				if not c.protected_enums then c.protected_enums = {} end
				table.insert(c.protected_enums, e)
			end
		end
	end
end

local function fill_enum_values()
	for _,e in pairs(enum_list) do
		local values = {}
		for _, v in ipairs(e) do
			if v.label=='Enumerator' then
				table.insert(values, v)
			end
		end
		e.values = values
	end
end

function fill_enum_tables()
	for _,e in pairs(enum_list) do
		local table = 'lqt_Enum lqt_enum'..e.xarg.id..'[] = {\n'
		for _,v in pairs(e.values) do
			if #v.xarg.classname > 0 then
				table = table .. '  { "' .. v.xarg.name
					.. '", true, static_cast<int>('..v.xarg.fullname..') },\n'
			else
				table = table .. '  { "' .. v.xarg.name
					.. '", false, static_cast<int>('..v.xarg.fullname..') },\n'
			end
		end
		table = table .. '  { 0, 0 }\n'
		table = table .. '};\n'
		e.enum_table = table
	end
end

function fill_typesystem(types)
	local etype = function(e)
		local en = e.xarg.fullname
		local lqt_name = string.gsub(en, '::', '.')
		return {
			push = function(n)
				return 'lqtL_pushenum(L, (int) '..n..', "'..lqt_name..'")', 1
			end,
			get = function(n, type_name)
				return 'static_cast<'..(type_name or en)..'>'
				..'(lqtL_toenum(L, '..n..', "'..lqt_name..'"))', 1
			end,
			test = function(n)
				return 'lqtL_isenum(L, '..n..', "'..lqt_name..'")', 1
			end,
			onstack = string.gsub(en, '::', '.')..',',
			defect = 10, -- check these last
		}
	end
	for _,e in pairs(enum_list) do
		if not types[e.xarg.fullname] then
			types[e.xarg.fullname] = etype(e)
		else
			--io.stderr:write(e.xarg.fullname, ': already present\n')
		end
	end
end


function print_enum_tables()
	for _,e in pairs(enum_list) do
		if e.xarg.access == 'public' then
			print_enum('static ' .. e.enum_table)
		end
	end
	return enums
end

function print_enum_creator(mod)
	local out = 'static lqt_Enumlist lqt_enum_list[] = {\n'
	for _,e in pairs(enum_list) do
		if e.xarg.access == 'public' then
			out = out..'  { lqt_enum'..e.xarg.id..', "'..string.gsub(e.xarg.fullname, "::", ".")..'" },\n'
		end
	end
	out = out..'  { 0, 0 },\n};\n'
	out = out .. 'void lqt_create_enums_'..mod..' (lua_State *L) {\n'
	out = out .. '  lqtL_createenumlist(L, lqt_enum_list);  return;\n}\n'
	print_enum(out)
end

---------------------------------------------------------------------

function preprocess(index)
	copy_enums(index)
end

function process(index, types)
	fill_enum_values()
	fill_enum_tables()
	fill_typesystem(types)
end

function output()
	print_enum(output_includes)
	print_enum_tables()
	print_enum_creator(module_name)
end
