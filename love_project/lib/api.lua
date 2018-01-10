local vpet = vpet

local api = {}
api.vpet = {}
api.draw = {}
api.hw = {}
api.os = {
	time = os.time,
	date = os.date,
	difftime = os.difftime,
}

-- Following are the functions and variables which can be accessed from within the script

-- Hardware commands
function api.hw.getInfo()
	local enum = {}
	local hw = vpet.hw
	enum.info = {}
	enum.output = {}
	enum.input = {}

	if hw.info then
		enum.info.name = hw.info.name or ''
		if hw.info.version then
			enum.info.version = {}
			for i = 1, 3 do
				enum.info.version[i] = hw.info.version[i]
			end
		else
			enum.info.version = {0, 0, 0}
		end
	end

	if hw.output then
		for i0, unit in ipairs(hw.output) do
			enum.output[i0] = {}
			enum.output[i0].type = unit.type
			if unit.type == 'led' then
			elseif unit.type == 'lcd' then
				enum.output[i0].colors = #unit.colors + 1
				if unit.colornames then
					enum.output[i0].colornames = {}
					for name, number in pairs(unit.colornames) do
						enum.output[i0].colornames[name] = number
					end
				end
				for i1, subunit in ipairs(unit) do
					enum.output[i0][i1] = {}
					enum.output[i0][i1].type = subunit.type
					if subunit.type == 'dotmatrix' then
						enum.output[i0][i1].w = subunit.w
						enum.output[i0][i1].h = subunit.h
					--elseif subunit.type == '' then
						--enum.output[i0][i1].w = subunit.w
						--enum.output[i0][i1].h = subunit.h
					end
				end
			end
		end
	end

	if hw.input then
		if hw.input.buttons then
			enum.input.buttons = {}
			for name, _ in pairs(hw.input.buttons) do
				enum.input.buttons[name] = true
			end
		end
	end

	return enum
end

-- Old hardware commands, to be deprecated

-- TODO: Deprecate?
function api.hw.btn(button)
	return vpet.input[button]
end

-- TODO: Deprecate
function api.vpet.led(value, led)
	led = led or vpet.hw.output.defaultled
	if value ~= nil then
		led.on = value and true or false
	end
	return led.on
end

-- TODO: Deprecate in favor of an image loading system that's less batty
function api.vpet.loadpage(file, page, lcd)
	local appstate = vpet.appstack:peek()
	lcd = lcd or vpet.hw.output.defaultlcd
	page = page or #appstate.vram + 1
	if file then
		appstate.vram[page] = vpet:newpage(appstate.dir..file, lcd)
	else
		appstate.vram[page] = vpet:newpage(nil, lcd)
	end
	return page
end

-- App control commands

function api.os.subapp(appname, cansub)
	if not vpet.cansub then
		return false, 'App does not have permission to call other apps.'
	end
	local app, appdir = vpet:loadapp(appname, vpet.appdir) -- FIXME: probably not the best way to control this
	if app then
		local appstate ={
			name = appname,
			dir = appdir,
			chunk = app,
			vram = {
				draw = {},
			},
		}
		appstate.desthw = vpet.hw.output.defaultlcd
		appstate.srchw = appstate -- INCEPTION??
		for i = 0, #vpet.hw.output.defaultlcd.vram do
			appstate.vram[i] = vpet.hw.output.defaultlcd.vram[i]
		end
		function appstate.vram:getColorRGB(index)
			vpet.hw.output.defaultlcd:getColorRGB(index)
		end
		vpet.appstack:push(appstate)
		api.draw.setColor(1, 0)
		api.draw.setDest(0, 'screen')
		api.draw.setSrc(0, 'screen')
		local old_cansub = vpet.cansub
		vpet.cansub = cansub
		local ok
		ok, appstate.app = pcall(appstate.chunk)
		if not ok then
			vpet.appstack:pop(appstate)
			print('app failed to load')
			vpet.cansub = old_cansub
			return false, appstate.app
		end
		if not appstate.app.callback then
			function appstate.app:callback(func, ...)
				if type(self[func]) == 'function' then
					local ok, err = pcall(self[func], self, ...)
					if not ok then
						print(err)
						vpet:terminate()
					end
				end
			end
		end
		if type(appstate.app) ~= 'table' then
			vpet.appstack:pop(appstate)
			vpet.cansub = old_cansub
			return false, 'app returned ' .. type(appstate.app) .. ' instead of table'
		else
			if not appstate.vram[1] then
				appstate.vram[1] = vpet:newpage()
			end
			api.draw.setSrc(0, 'screen')
			api.draw.setSrc(1, 'app')
			api.draw.setColor(1, 0)
			return true
		end
	else
		return false, appdir
	end
end

function api.os.quit()
	if not vpet.running then error'' end -- Should not be necessary; running api.* functions should be disallowed whenan app is not running, or maybe in general, hm
	local appstate = vpet.appstack:peek()
	local app = appstate.app
	if app then
		app:callback('event', 'quit', {})
		app:callback('quit')
	else
		print('api.os.quit with no app')
	end
	vpet:terminate()
end

function api.os.listapps()
	if vpet.cansub then return vpet:listapps('apps/') else error('App does not have permission to use listapps()') end
end

-- These are the new draw functions --------

function api.draw.setColor(color, bgcolor)
	local appstate = vpet.appstack:peek()
	local drawstate = appstate.vram.draw
	drawstate.color = color or drawstate.color
	drawstate.bgcolor = bgcolor or drawstate.bgcolor
	love.graphics.setColor(appstate.desthw:getColorRGB(drawstate.color))
end

function api.draw.getColor()
	local drawstate = vpet.appstack:peek().vram.draw
	return drawstate.color, drawstate.bgcolor
end

-- TODO: merge the common parts of these two functions. remember, DRY not WET
function api.draw.setDest(page, hw)
	local appstate = vpet.appstack:peek()
	if type(hw) == 'number' then
		if vpet.hw.output[hw] then
			appstate.desthw = vpet.hw.output[hw]
		else
			error('invalid argument #2 to setDest: LCD ' .. tostring(hw) .. ' does not exist', 2)
		end
	elseif hw == 'app' then
		appstate.desthw = appstate
	elseif hw == 'screen' then
		appstate.desthw = vpet.hw.output.defaultlcd
	else
		error('invalid argument #2 to setDest of type ' .. type(hw), 2)
	end
	if type(page) == 'number' then
		if appstate.desthw.vram[page] then
			appstate.destpage = page
		else
			error('invalid argument #1 to setDest: page ' .. type(page) .. ' does not exist', 2)
		end
	--elseif not page then
		--appstate.destpage = 0
	else
		error('invalid argument #1 to setDest of type ' .. type(page), 2)
	end
	appstate.dest = appstate.desthw.vram[appstate.destpage]
end

function api.draw.setSrc(page, hw)
	local appstate = vpet.appstack:peek()
	if type(hw) == 'number' then
		if vpet.hw.output[hw] then
			appstate.srchw = vpet.hw.output[hw]
		else
			error('invalid argument #2 to setSrc: LCD ' .. tostring(hw) .. ' does not exist', 2)
		end
	elseif hw == 'app' then
		appstate.srchw = appstate
	elseif hw == 'screen' then
		appstate.srchw = vpet.hw.output.defaultlcd
	else
		error('invalid argument #2 to setSrc of type ' .. type(hw), 2)
	end
	if type(page) == 'number' then
		if appstate.srchw.vram[page] then
			appstate.srcpage = page
		else
			error('invalid argument #1 to setSrc: page ' .. type(page) .. ' does not exist', 2)
		end
	--elseif not page then
		--appstate.srcpage = 0
	else
		error('invalid argument #1 to setSrc of type ' .. type(page), 2)
	end
	appstate.src = appstate.srchw.vram[appstate.srcpage]
end

function api.draw.cls(color)
	local vram = vpet.appstack:peek().vram
	local oldc, bgc = api.draw.getColor()
	api.draw.setColor(color or bgc)
	api.draw.rect()
	api.draw.setColor(oldc)
end

function api.draw.rect(x, y, w, h)
	api.draw.setColor()
	local appstate = vpet.appstack:peek()
	if type(x) == 'table' then
		local rect = x
		x = rect.x or 0
		y = rect.y or 0
		w = rect.w or appstate.dest:getWidth()
		h = rect.h or appstate.dest:getHeight()
	else
		x = x or 0
		y = y or 0
		w = w or appstate.dest:getWidth()
		h = h or appstate.dest:getHeight()
	end
	appstate.dest:renderTo(function()
		love.graphics.rectangle('fill', x, y, w, h)
	end)
end

function api.draw.pix(x, y)
	api.draw.setColor()
	x = math.floor(x)
	y = math.floor(y)
	vpet.appstack:peek().dest:renderTo(function()
		love.graphics.points(x, y + 1) -- UPSTREAM: LOVE2D has an off-by-one error to account for here
	end)
end

function api.draw.blit(srcx, srcy, w, h, destx, desty)
	local appstate = vpet.appstack:peek()
	srcx = srcx or 0
	srcy = srcy or 0
	w = w or appstate.dest:getWidth()
	h = h or appstate.dest:getHeight()
	destx = destx or 0
	desty = desty or 0
	local quad = vpet.hw.output.defaultlcd.vram.quad
	quad:setViewport(srcx, srcy, w, h)
	love.graphics.setColor(vpet.const.imageColor)
	appstate.dest:renderTo(function()
		love.graphics.draw(appstate.src, quad, destx, desty)
	end)
	api.draw.setColor()
end

function api.draw.text(str, x, y, align, rect)
	local appstate = vpet.appstack:peek()
	str = tostring(str)
	x = x or 0
	y = y or 0
	align = align or 1
	-- TODO: currently, text uses a special src page that can be colorized.
	-- I'd like to generalize this eventually and implement a system for
	-- loading this sort of colorable, 1-bit image in general
	local oldc, bgc = api.draw.getColor()
	local oldsrc = appstate.src
	appstate.src = vpet.hw.output.defaultlcd.vram.font
	local ch, srcx, srcy, xi, yi, width
	width = #str * 4
	xi = ((align - 1) * width) / 2
	yi = 0
	if rect then
		api.draw.setColor(type(rect) == 'number' and rect or bgc)
		api.draw.rect(x + xi - 1, y + yi, width + 1, 8)
	end
	-- FIXME: HAAAAXXXX
	local oldImageColor = vpet.const.imageColor
	vpet.const.imageColor = appstate.desthw:getColorRGB(oldc)
	for i = 1, #str do
		ch = str:byte(i)
		srcx = (ch % 16) * 4
		srcy = math.floor(ch / 16) * 8
		api.draw.blit(srcx, srcy, 4, 8, x + (i - 1) * 4 + xi, y + yi)
	end
	vpet.const.imageColor = oldImageColor
	api.draw.setColor(oldc, bgc)
	appstate.src = oldsrc
end

function api.draw.line(x0, y0, x1, y1)
	api.draw.setColor()
	x0 = math.floor(x0)
	x1 = math.floor(x1)
	y0 = math.floor(y0)
	y1 = math.floor(y1)
	local dx = math.abs(x1 - x0)
	local sx = x0 < x1 and 1 or -1
	local dy = math.abs(y1 - y0)
	local sy = y0 < y1 and 1 or -1
	local err = math.floor((dx > dy and dx or -dy) / 2)
	local e2 = 0
	while true do
		api.draw.pix(x0, y0)
		if x0 == x1 and y0 == y1 then break end
		e2 = err
		if e2 >= -dx then
			err = err - dy
			x0 = x0 + sx
		end
		if e2 < dy then
			err = err + dx
			y0 = y0 + sy
		end
	end
end

--[[
function api.draw.circleOld(x0, y0, radius)
	api.draw.setColor()
	x0 = math.floor(x0)
	y0 = math.floor(y0)
	radius = math.floor(radius)

	local x = radius - 1
	local y = 0
	local dx = 1
	local dy = 1
	local err = dx - bit.lshift(radius, 1)

	local DEBUG_breakout = 100
	while x >= y and DEBUG_breakout > 0 do
		DEBUG_breakout = DEBUG_breakout - 1
		api.draw.pix(x0 + x, y0 + y)
		api.draw.pix(x0 + y, y0 + x)
		api.draw.pix(x0 - y, y0 + x)
		api.draw.pix(x0 - x, y0 + y)
		api.draw.pix(x0 - x, y0 - y)
		api.draw.pix(x0 - y, y0 - x)
		api.draw.pix(x0 + y, y0 - x)
		api.draw.pix(x0 + x, y0 - y)

		if err <= 0 then
			y = y + 1
			err = err + dy
			dy = dy + 2
		end

		if err > 0 then
			x = x - 1
			dx = dx + 2
			err = err + dx - bit.lshift(radius, 1)
		end
	end
end

function api.draw.circle(xc, yc, r)
	local x = 0
	local y = r
	local d = 3 - 2 * r

	local DEBUG_breakout = 100
	while y >= x or DEBUG_breakout < 0 do
		DEBUG_breakout = DEBUG_breakout - 1
		-- for each pixel we will
		-- draw all eight pixels
		api.draw.pix(xc + x, yc + y)
		api.draw.pix(xc + y, yc + x)
		api.draw.pix(xc - y, yc + x)
		api.draw.pix(xc - x, yc + y)
		api.draw.pix(xc - x, yc - y)
		api.draw.pix(xc - y, yc - x)
		api.draw.pix(xc + y, yc - x)
		api.draw.pix(xc + x, yc - y)

		x = x + 1

		-- check for decision parameter
		-- and correspondingly 
		-- update d, x, y
		if d > 0 then
			y = y - 1
			d = d + 4 * (x - y) + 10
		else
			d = d + 4 * x + 6
		end
	end
end
--]]

-- FIXME: this is only for Backwards compatibility
api.vpet.listapps = api.os.listapps
api.vpet.quit = api.os.quit
api.vpet.subapp = api.os.subapp
api.vpet.btn = api.hw.btn

return api
