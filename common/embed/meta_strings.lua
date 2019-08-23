--[[*************************************************************************
Copyright (c) 2019-2019 Saniko

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
***************************************************************************]]

----------------------------------------------------------------------------------------------------
-- Meta string container
----------------------------------------------------------------------------------------------------
local Class = {}

----------------------------------------------------------------------------------------------------
-- Setup locals from lqt_embed.cpp
----------------------------------------------------------------------------------------------------
function Class.setup(...)
end
----------------------------------------------------------------------------------------------------
-- Create an Class object
----------------------------------------------------------------------------------------------------
function Class.create(initial)
    local ret = initial or {}
    setmetatable(ret, { __index = Class })
    return ret
end
----------------------------------------------------------------------------------------------------
-- Add meta string(ignore duplicate string)
----------------------------------------------------------------------------------------------------
function Class:insert(input)
    for i,s in ipairs(self) do
        if s == input then
            return i - 1
        end
    end
    table.insert(self, input)
    return #self - 1
end
----------------------------------------------------------------------------------------------------
-- Get meta string index(0-base) from string literals
----------------------------------------------------------------------------------------------------
function Class:indexOf(input)
    for i,s in ipairs(self) do
        if s == input then
            return i - 1
        end
    end
    error('Invalid meta string : ' .. input)
end

return Class
