--
-- strict.lua
-- checks uses of undeclared global variables
-- All global variables must be 'declared' through a regular assignment
-- (even assigning nil will do) in a main chunk before being used
-- anywhere or assigned to inside a function.
--

local getinfo, error, rawset, rawget = debug.getinfo, error, rawset, rawget

local mt = getmetatable(_G)
if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end

mt.__declared = {}

local function what ()
  local d = getinfo(3, "S")
  return d and d.short_src or "[C]"
end

mt.__newindex = function (t, n, v)
  if not mt.__declared[n] then
    local w = what()
    -- main.lua/c函数/内嵌string函数
    --  可以修改global
    if w ~= "main" and w ~= "[C]" and w:find('^%[string') ~= 1 then
      error("Assign to undeclared variable '"..n.."'", 2)
    end
    mt.__declared[n] = true
  end
  rawset(t, n, v)
end

mt.__index = function (t, n)
  if not mt.__declared[n] and what() ~= "C" then
    error("Variable '"..n.."' is not declared", 2)
  end
  return rawget(t, n)
end
