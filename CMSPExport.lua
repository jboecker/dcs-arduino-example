CMSPExport = {}
CMSPExport.HOST = "localhost"
CMSPExport.PORT = 7777

package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"
  
socket = require("socket")

local function parse_indication(indicator_id)
	local ret = {}
	local li = list_indication(indicator_id)
	if li == "" then return nil end
	local m = li:gmatch("([^\n]+)\n")
	while true do
		local separator = m()
		if not separator then break end
		local name = m()
		local value = m()
		ret[name] = value
	end
	return ret
end

local function get_cmsp_lines()
	local cmsp = parse_indication(7)
	if not cmsp then
		local emptyline = string.format("%20s", "") -- 20 spaces
		return emptyline, emptyline
	else
		local tu = cmsp["txt_UP"]
		local line1 = string.format("%-4s", tu:sub(0, 4))..
				 " "..string.format("%-4s", tu:sub(5, 8))..
				 " "..string.format("%-4s", tu:sub(9, 12))..
				 " "..string.format("%-4s", tu:sub(13, 16))
		local line2 = string.format("%-4s", cmsp["txt_DOWN1"])..
				 " "..string.format("%-4s", cmsp["txt_DOWN2"])..
				 " "..string.format("%-4s", cmsp["txt_DOWN3"])..
				 " "..string.format("%-4s", cmsp["txt_DOWN4"])
		return line1, line2
	end
end

-- Prev Export functions.
local PrevExport = {}
PrevExport.LuaExportStart = LuaExportStart
PrevExport.LuaExportStop = LuaExportStop
PrevExport.LuaExportBeforeNextFrame = LuaExportBeforeNextFrame
PrevExport.LuaExportAfterNextFrame = LuaExportAfterNextFrame


-- Lua Export Functions
LuaExportStart = function()

	CMSPExport.conn = socket.udp()
	CMSPExport.conn:setsockname("*", 0)
	CMSPExport.conn:setoption("broadcast", true)
	CMSPExport.conn:settimeout(0)
	
	CMSPExport.listenconn = socket.udp()
	CMSPExport.listenconn:setsockname("*", 7778)
	CMSPExport.listenconn:settimeout(0)
	
	-- Chain previously-included export as necessary
	if PrevExport.LuaExportStart then
		PrevExport.LuaExportStart()
	end
end

LuaExportStop = function()
	CMSPExport.conn:close()
	-- Chain previously-included export as necessary
	if PrevExport.LuaExportStop then
		PrevExport.LuaExportStop()
	end
end

local function processInputLine(line)
	local cmd, args = line:match("^([^ ]+) (.*)")
	if cmd == "MASTER-CAUTION-BTN" then
		local sys_controller = GetDevice(24)
		if args == "1" then
			sys_controller:performClickableAction(3001, 1.0)
		end
		if args == "0" then
			sys_controller:performClickableAction(3001, 0.0)
		end
	end
end

local rxbuf = ""
function LuaExportBeforeNextFrame()
	CMSPExport.listenconn:settimeout(0.001)
	local lInput = nil
	
	while true do
		lInput = CMSPExport.listenconn:receive()
		if not lInput then break end
		rxbuf = rxbuf .. lInput
	end
	
	while true do
		local line, rest = rxbuf:match("^([^\n]+)\n(.*)")
		if line then
			rxbuf = rest
			processInputLine(line)
		else
			break
		end
	end
	
	-- Chain previously-included export as necessary
	if PrevExport.LuaExportBeforeNextFrame then
		PrevExport.LuaExportBeforeNextFrame()
	end
	
end

local nextLowFreqStepTime = 0
local nextHighFreqStepTime = 0
function LuaExportAfterNextFrame()

	local curTime = LoGetModelTime()

	if curTime >= nextHighFreqStepTime then
		-- runs 100 times per second
		nextHighFreqStepTime = curTime + .01
		
		local mwarn = GetDevice(0):get_argument_value(404)
		socket.try(CMSPExport.conn:sendto(string.format("MC-LED %d\n", mwarn), CMSPExport.HOST, CMSPExport.PORT))
	end

	if curTime >= nextLowFreqStepTime then
		-- runs 10 times per second
		nextLowFreqStepTime = curTime + .1
		
		local line1, line2 = get_cmsp_lines()
		socket.try(CMSPExport.conn:sendto("CMSP1 "..line1.."\n".."CMSP2 "..line2.."\n", CMSPExport.HOST, CMSPExport.PORT))
	end

	-- Chain previously-included export as necessary
	if PrevExport.LuaExportAfterNextFrame then
		PrevExport.LuaExportAfterNextFrame()
	end
end


