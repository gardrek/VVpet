local emu = {}
local vpet = {}
local api = {}

function love.load()
	-- Love set-up stuff
	io.stdout:setvbuf('no') -- enable normal use of the print() command
	love.graphics.setDefaultFilter('nearest', 'nearest', 0)

	emu.cozy = 2
	emu.center = {}
	emu.scale = 4
	emu.bg = {}
	emu.bg.image = love.graphics.newImage('bg.jpg')
	emu.bg.x, emu.bg.y = 0, 0

	-- set up sandbox environments
	vpet.env = {}
	vpet.hwenv = {}
	local env_globals = {
		-- Functions and variables
		--'garbagecollect', 'dofile', '_G', 'getfenv', 'load', 'loadfile',
		--'loadstring', 'setfenv', 'rawequal', 'rawget', 'rawset',
		'assert', 'error', 'getmetatable', 'ipairs',
		'next', 'pairs', 'pcall', 'print',
		'select', 'tonumber', 'tostring', 'type',
		'unpack', '_VERSION', 'xpcall',
		-- Libraries
		'math', 'table'
	}
	for i,v in ipairs(env_globals) do
		vpet.env[v]=_G[v]
		vpet.hwenv[v]=_G[v]
	end
	for k,v in pairs(api) do
		vpet.env[k]=v
	end
	vpet.env._G = vpet.env
	vpet.hwenv._G = vpet.hwenv

	vpet.inputmap = {
		-- system buttons - these buttons are handled differently when an app is run from inside another app
		back = {'backspace', 'tab'}, -- use to return to a previous screen or cancel something. TODO: hold for x seconds to send home key press, hold for x + y seconds to force-close app
		home = {'escape', 'r'}, -- TODO: pressing home pauses/exits the app, returning to the calling app. long press force-quits the app. If the app is the top-level app, a force quit will restart the app
		reset = {'f10'}, -- TODO: reset pinhole, clears all user data
		-- screen buttons - numbered left to right
		['1'] = {'1', 'z', 'kp1'},
		['2'] = {'2', 'x', 'kp2'},
		['3'] = {'3', 'c', 'kp3'},
		-- action buttons are assigned a letter, starting with 'a' for the most-used button
		-- NOTE: The standard vPET does not have action buttons
		a = {'n'},
		b = {'b'},
		-- direction buttons:
		left = {'a', 'left', 'kp4'},
		right = {'d', 'right', 'kp6'},
		up = {'w', 'up', 'kp8'},
		down = {'s', 'down', 'kp5'},
	}

	-- stores a table of which button inputs are down
	vpet.input = {}

	-- load hardware
	vpet.hw = vpet:loadhardware('hw/vpet64/')

	if not vpet.hw then
		error('Base hardware failed to load!')
	end

	local spritefile = 'rom/sprites.png'
	if not love.filesystem.exists(spritefile) then
		spritefile = 'rom/nocart.png'
	end
	if not love.filesystem.exists(spritefile) then
		spritefile = love.graphics.newImage(love.image.newImageData(64, 64))
	end

	if vpet.hw.output then
		for i1, unit in ipairs(vpet.hw.output) do
			if unit.type == 'lcd' then
				print('LCD unit '..i1..' loaded')
				unit.vrom.quad = love.graphics.newQuad(0, 0, unit.vrom.w, unit.vrom.h, unit.vrom.w, unit.vrom.h)
				vpet:loadvrom(unit,2,spritefile)
				for i2, subunit in ipairs(unit) do
					if subunit.type == 'dotmatrix' then
						--subunit.canvas = love.graphics.newCanvas(subunit.w, subunit.h, 'normal', 0)
						subunit.canvas = unit.vrom[subunit.page]
						subunit.canvas:renderTo(
							function()
								love.graphics.clear(unit.colors[0])
							end
						)
					end
					print('Subunit '..i2..', type '..subunit.type..', of LCD '..i1..' loaded')
				end
			elseif unit.type == 'led' then
				unit.on = true
			end
		end
	end

	if vpet.hw.base then
		vpet.hw.base.minw = vpet.hw.base.minw or vpet.hw.base.w
		vpet.hw.base.minh = vpet.hw.base.minh or vpet.hw.base.h
	end

	local cartfolder = 'carts/'
	cartfolder='rom/'
	--cartfolder = cartfolder..'tictactoe/'

	-- load the cart script
	local success
	success, cart = vpet:loadscript(cartfolder..'cart.lua')
	if success then
		print('Cart loaded')
	else
		cart = {}
		success, cart = vpet:loadscript('rom/splash.lua')
		if success then
			print('Using default cart...')
		else
			error('Could not load default cart!')
		end
	end

	love.resize()
end

function love.update(dt)
	if cart.update and type(cart.update) == 'function' then
		cart:update(dt)
	end
end

function love.draw()
	love.graphics.setColor(0xff, 0xff, 0xff, 0xff)


	-- scenery background image
	love.graphics.draw(
		emu.bg.image,
		emu.bg.x, emu.bg.y,
		0, emu.bg.scale
	)

	-- base console
	if vpet.hw.base.image then
		love.graphics.draw(
			vpet.hw.base.image,
			emu.center.x + vpet.hw.base.x * emu.scale,
			emu.center.y + vpet.hw.base.y * emu.scale,
			0, emu.scale
		)
	end

	-- draw buttons
	if vpet.hw.input and vpet.hw.input.buttons then
		local image
		for k,v in pairs(vpet.hw.input.buttons) do
			image = vpet.input[k] and v.image_down or v.image_up or v.image
			if image then
				love.graphics.draw(
					image,
					emu.center.x + (v.x - v.w / 2) * emu.scale,
					emu.center.y + (v.y - v.h / 2) * emu.scale,
					0, emu.scale
				)
			end
		end
	end

	--draw outputs
	if vpet.hw.output then
		for index, unit in ipairs(vpet.hw.output) do
			if unit.type == 'led' then
				image = unit.on and unit.image_on or unit.image_off
				if image then
					love.graphics.setColor(0xff, 0xff, 0xff, 0xff)
					love.graphics.draw(
						image,
						emu.center.x + (unit.x - unit.w / 2) * emu.scale,
						emu.center.y + (unit.y - unit.h / 2) * emu.scale,
						0, emu.scale
					)
				end
			elseif unit.type == 'lcd' then
				love.graphics.setColor(unit.bgcolor or {0xff, 0xff, 0xff, 0xff})
				love.graphics.rectangle(
					'fill',
					emu.center.x + (unit.x - unit.w / 2) * emu.scale,
					emu.center.y + (unit.y - unit.h / 2) * emu.scale,
					unit.w * emu.scale, unit.h * emu.scale
				)
				for subindex, subunit in ipairs(unit) do
					if subunit.type == 'dotmatrix' then
						love.graphics.setColor(0xff, 0xff, 0xff, 0xff)
						--TODO: fix this and add support for more than one matrix/output type
						if index == 1 then
							subunit.canvas:renderTo(function()
								if cart.draw and type(cart.draw) == 'function' then
									cart:draw()
								end
							end)
						end
						love.graphics.draw(
							subunit.canvas,
							emu.center.x + (unit.x + subunit.x - subunit.w / 2) * emu.scale,
							emu.center.y + (unit.y + subunit.y - subunit.h / 2) * emu.scale,
							0, emu.scale
						)
					end
				end
			end
		end
	end
end

function love.keypressed(key, scancode, isrepeat)
	if not isrepeat then
		if key == '9' then
			emu.cozy = emu.cozy - 1
			if emu.cozy < 0 then
				emu.cozy = 0
			end
			love.resize()
		elseif key == '0' then
			emu.cozy = emu.cozy + 1
			if emu.cozy > 7 then
				emu.cozy = 7
			end
			love.resize()
		end
		--print(emu.cozy)
		--print(key, 'pressed')
		vpet.keyevent(key)
	end
end

function love.keyreleased(key, scancode, isrepeat)
	if not isrepeat then
		--print(key, 'released')
		vpet.keyevent(key, true)
	end
end

function love.resize(w, h)
	w = w or love.graphics.getWidth()
	h = h or love.graphics.getHeight()
	--print(w,h)
	emu.center.x = math.floor(w/2)
	emu.center.y = math.floor(h/2)
	emu.bg.scale = math.max(w / emu.bg.image:getWidth(), h / emu.bg.image:getHeight())
	emu.bg.x = emu.center.x - (emu.bg.image:getWidth()/2 * emu.bg.scale)
	emu.bg.y = emu.center.y - (emu.bg.image:getHeight()/2 * emu.bg.scale)
	local scale = math.min(math.floor(w / vpet.hw.base.minw), math.floor(h / vpet.hw.base.minh))
	emu.scale = math.max(scale - emu.cozy, 1)
end

function vpet.keyevent(key, released)
	local changed=false
	if cart.event and type(cart.event)=='function' then -- TODO: refactor this to be a check into a table of declared functions
		for k,v in pairs(vpet.inputmap) do
			changed=false
			for i,bind in ipairs(v) do
				if bind==key then
					changed=true
				end
			end
			if changed then
				vpet.input[k] = not released
				cart:event('button', {button = k, up = released, down = not released})
			end
		end
	end
end

function vpet:loadvrom(lcd,page,file)
	local image, raw
	if type(file) ~= 'string' then
		image = file
	elseif file then
		image = love.graphics.newImage(file)
	else
		--image = love.graphics.newImage()
	end
	raw = image:getData()
	raw:mapPixel(
		function(x, y, r, g, b, a)
			a = a < 128 and 0 or 255
			local distance
			local closest = 16777216
			local color
			for i = 0, #lcd.colors do v = lcd.colors[i]
				distance = (v[1] - r) * (v[1] - r) + (v[2] - g) * (v[2] - g) + (v[3] - b) * (v[3] - b)
				if distance < closest then
					closest = distance
					color = v
				end
			end
			return color[1], color[2], color[3], a
		end
	)
	lcd.vrom[page] = love.graphics.newImage(raw)
end

function vpet:loadscript(script, env)
	local _LuaBCHeader = string.char(0x1B)..'LJ'
	local exists = love.filesystem.exists(script)
	if exists then
		if love.filesystem.read(script, 3) == _LuaBCHeader then
			print('Bytecode is not allowed.')
			return false
		end
	else
		print('script '..script..' failed to load: file not opened')
		return false
	end
	local ok, f = pcall(love.filesystem.load, script)
	if not ok then print('script '..script..' failed to load: script error') return false, f end
	setfenv(f, env or self.env)
	return pcall(f)
end

function vpet:loadhardware(dir)
	local success, hw, error = vpet:loadscript(dir..'/hw.lua', self.hwenv)
	local loaded = {dir = dir}
	local hw_errors = 0
	local id = dir
	local file

	function finish(...)
		if hw_errors == 0 then
			print('Hardware '..id..' loaded with no errors.')
		elseif hw_errors == -1 then
			print('Hardware '..id..' failed to load.')
		elseif hw_errors < 0 then
			print('Hardware '..id..' loaded with negative zero errors. :P')
		else
			print('Hardware '..id..' loaded with '..hw_errors..' errors.')
		end
		return ...
	end

	function load_images(dest, source, names, errormessage)
		if not names then
			for i, v in ipairs(source) do
				file = dir..v
				if love.filesystem.exists(file) then
					dest[i] = love.graphics.newImage(file)
				else
					print('hardware '..id..': '..errormessage..' image "'..file..'" not loaded')
					hw_errors = hw_errors + 1
				end
			end
		else
			for i, v in ipairs(names) do
				if source[v] then
					file = dir..source[v]
					if love.filesystem.exists(file) then
						dest[v] = love.graphics.newImage(file)
					else
						print('hardware '..id..': '..errormessage..' image "'..file..'" not loaded')
						hw_errors = hw_errors + 1
					end
				end
			end
		end
	end

	if not success then
		hw_errors = -1
		return finish(false, error)
	end

	if type(hw) ~='table' then
		print('hardware descriptor script in "'..dir..'" returned '..type(hw)..', not table.')
		hw_errors = -1
		return finish(false, hw)
	end

	local categories = {'info', 'base', 'output', 'input'}
	for i,v in ipairs(categories) do
		if type(hw[v]) ~= 'table' and type(hw[v]) ~= 'nil' then
			print('hardware error: key "'..tostring(v)..'" must be table if it exists')
			hw_errors = hw_errors + 1
		end
	end

	if hw_errors > 0 then return finish({}) end

	if hw.info then
		id = hw.info.name or dir
		loaded.info = hw.info
	end
	if hw.base then
		loaded.base = {}
		local malformed = false
		for i,v in ipairs{'x', 'y', 'w', 'h', 'minw', 'minh'} do
			if hw.base[v] then
				loaded.base[v] = hw.base[v]
			else
				hw_errors = hw_errors + 1
				malformed = true
				loaded.base[v] =  i <= 2 and 0 or 20
				-- the line above makes the base geometry pretty small but at least it errors so you know. also HAAAX
			end
		end
		file = dir..hw.base.image
		if love.filesystem.exists(file) then
			loaded.base.image = love.graphics.newImage(file)
		else
			print('hardware '..id..': base image "'..file..'" not loaded')
			hw_errors = hw_errors + 1
		end
		if malformed then
			print('hardware '..id..': base geometry malformed')
		end
	end
	-- TODO: This function currently does VERY LITTLE checking that outputs are correctly formed
	if hw.output then
		loaded.output = {}
		local unit
		for i1, o in ipairs(hw.output) do
			if o.type then
				unit = {type = o.type}
				for i2, type in pairs{'led', 'lcd'} do
					if o.type == type then
						unit.x = o.x
						unit.y = o.y
						unit.w = o.w
						unit.h = o.h
					end
				end
				if o.type == 'led' then
					load_images(unit, o, {'image_on', 'image_off'}, 'LED'..tostring(i1))
				elseif o.type == 'lcd' then
					unit.bgcolor = o.bgcolor
					unit.colors = o.colors
					if o.vrom then
						unit.vrom = {}
						unit.vrom.w = o.vrom.w
						unit.vrom.h = o.vrom.h
						unit.vrom[0] = love.graphics.newCanvas(unit.vrom.w, unit.vrom.h, 'normal', 0)
						load_images(unit.vrom, o.vrom, nil, 'VROM')
					end
					local subunit
					for i3, hw_subunit in ipairs(o) do
						subunit = {type = hw_subunit.type}
						if hw_subunit.type == 'dotmatrix' or hw_subunit.type == 'backlight' or hw_subunit.type == 'vrom' then
							for key, value in pairs(hw_subunit) do
								subunit[key] = value
							end
						end
						table.insert(unit, subunit)
					end
				end
				table.insert(loaded.output, unit)
			else
				print('unknown output not loaded')
			end
		end
	end
	if hw.input then
		loaded.input = {}
		if hw.input.buttons then
			loaded.input.buttons = {}
			for button,t in pairs(hw.input.buttons) do
				loaded.input.buttons[button] = {
					x = t.x,
					y = t.y,
					h = t.h,
					w = t.w,
				}
				load_images(loaded.input.buttons[button], t, {'image', 'image_up', 'image_down'}, 'Button')
			end
		end
	end

	return finish(loaded)
end

-- Following are the functions which can be called from within the script
-- TODO: also, make them better

function api.drawsprite(sx,sy,x,y)
	api.blit(sx*4, sy*4, 4, 4, x, y)
end

function api.blit(srcx, srcy, w, h, destx, desty, src, dest, lcd)
	lcd = lcd or 1 -- FIXME because hardcoding the first output as the lcd is bad mmkay
	lcd = vpet.hw.output[lcd]
	src = src or 2
	dest = dest or 0
	srcx = srcx or 0
	srcy = srcy or 0
	w = w or lcd.vrom.w
	h = h or w or lcd.vrom.h
	destx = destx or 0
	desty = desty or 0
	lcd.vrom.quad:setViewport(srcx, srcy, w, h)
	lcd.vrom[dest]:renderTo(function()
		love.graphics.draw(lcd.vrom[src], lcd.vrom.quad, destx, desty)
	end)
end

function api.pix(x, y, color, dest, lcd)
	lcd = lcd or 1 -- FIXME because hardcoding the first output as the lcd is bad mmkay
	lcd = vpet.hw.output[lcd]
	dest = dest or 0
	color = color or 1
	local oldc = {love.graphics.getColor()}
	love.graphics.setColor(lcd.colors[color])
	lcd.vrom[dest]:renderTo(function()
		love.graphics.point(x, y)
	end)
	love.graphics.setColor(oldc)
end

function api.cls(c, dest, lcd)
	c = c or 0
	c = math.floor(c)%2
	lcd = lcd or 1 -- FIXME: FIXXXXXXXMEEEEEE hardwired
	lcd = vpet.hw.output[lcd]
	dest = dest or 0
	lcd.vrom[dest]:renderTo(function()
		love.graphics.clear(lcd.colors[c])
	end)
end

function api.led(value)
	local led = vpet.hw.output[2] -- FIXME: FIXXXXXXXMEEEEEE hardwired
	if value ~= nil then
		led.on = value and true or false
	end
	return led.on
end
