local dlpath = arg[0]:gsub('examples/.+', 'build/lib/?.so;build/lib/?.dll')
package.cpath = package.cpath .. ';' .. dlpath

local QtCore = require 'qtcore'

--------------------------------------------------------------------------------
-- Qt useful routines
--------------------------------------------------------------------------------
_G.SIGNAL = function(s) return '2' .. s end
_G.SLOT = function (s) return '1' .. s end
_G.tr = assert(QtCore.QObject.tr)

--------------------------------------------------------------------------------
-- for debug purpuse
--------------------------------------------------------------------------------
_G.gc = function()
	print('gc start')
	collectgarbage()
	print('gc end')
end
