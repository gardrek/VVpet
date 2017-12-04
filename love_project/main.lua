local emu = {}
local vpet = {}
local api = {}
local mouse = {}

function love.load()
	-- Love set-up stuff
	io.stdout:setvbuf('no') -- enable normal use of the print() command
	love.graphics.setDefaultFilter('nearest', 'nearest', 0)

	mouse.last_x, mouse.last_y = love.mouse.getPosition()
	mouse.x, mouse.y = love.mouse.getPosition()

	emu.cozy = 2
	emu.center = {}
	emu.scale = 4
	emu.bg = {
		x = 0,
		y = 0,
		image = love.graphics.newImage('bg.jpg')
	}

	vpet.inputmap = {
		-- system buttons - these buttons are handled differently when an app is run from inside another app
		back = {'backspace', 'tab'}, -- use to return to a previous screen or cancel something. TODO: hold for x seconds to send home key press, hold for y more seconds to force-close app
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

	vpet.inputreversemap = {} -- Oh, I'm not like the input at all... Some would say, I'm the reverse.

	for button, vvv in pairs(vpet.inputmap) do
		for iii, emukey in ipairs(vvv) do
			vpet.inputreversemap[emukey] = button
		end
		vpet.input[button] = false
	end

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
	vpet.env.vpet = {}
	for k,v in pairs(api) do
		vpet.env[k]=v
		vpet.env.vpet[k]=v
	end
	vpet.env._G = vpet.env
	vpet.hwenv._G = vpet.hwenv

	-- hardware uses these variables to load _other_ hardware
	vpet.hwenv.dofile = _G.dofile
	vpet.hwenv.hwdir = 'hw/'

	vpet.env.vpet.btn = vpet:readonlytable(vpet.input) -- This way, apps can't spoof the table, hopefully

	-- load hardware
	vpet.hw = vpet:loadhardware('vpet64.lua', vpet.hwdir)

	--vpet.hw = vpet:loadhardware('hw/vpet64_test/')

	if not vpet.hw then
		error('Base hardware failed to load!')
	end

	if vpet.hw.output then
		local num_lcds, num_leds = 0, 0
		for i1, unit in ipairs(vpet.hw.output) do
			if unit.type == 'lcd' then
				num_lcds = num_lcds + 1
			elseif unit.type == 'led' then
				num_leds = num_leds + 1
			end
		end
		print('LCDs:', num_lcds,'LEDs: ', num_leds)
		for i1, unit in ipairs(vpet.hw.output) do
			if unit.type == 'lcd' then
				print('LCD unit '..i1..' loaded')
				unit.vram.quad = love.graphics.newQuad(0, 0, unit.vram.w, unit.vram.h, unit.vram.w, unit.vram.h)
				for i2, subunit in ipairs(unit) do
					if subunit.type == 'dotmatrix' then
					end
					print('Subunit '..i2..', type '..tostring(subunit.type)..', of LCD '..i1..' loaded')
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

	-- load the cart script and sprites

	local cartfolder
	cartfolder = 'carts/'
	--cartfolder = cartfolder..'tictactoe/'
	cartfolder = cartfolder..'pixelimagetest/'

	cartfolder = 'rom/'

	local spritefile = cartfolder .. '/sprites.png'
	if not love.filesystem.exists(spritefile) then
		spritefile = 'rom/nocart.png'
	end
	if not love.filesystem.exists(spritefile) then
		spritefile = love.graphics.newImage(love.image.newImageData(64, 64))
	end

	if vpet.hw.output.defaultlcd then
		vpet:initvram(vpet.hw.output.defaultlcd, 2, spritefile)
	end

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
	vpet:updatemousecheap()
	if cart.update and type(cart.update) == 'function' then
		cart:update(dt)
	end
end

function vpet:updatemousecheap()
	local x1, y1, x2, y2
	mouse.last_x, mouse.last_y = mouse.x, mouse.y
	mouse.x, mouse.y = love.mouse.getPosition()
	local was_pressed = mouse.down
	mouse.down = love.mouse.isDown(1)
	for key, obj in pairs(vpet.hw.input.buttons) do
		x1, y1, x2, y2 =
			emu.center.x + (obj.x - obj.w / 2) * emu.scale,
			emu.center.y + (obj.y - obj.h / 2) * emu.scale,
			emu.center.x + (obj.x + obj.w / 2) * emu.scale,
			emu.center.y + (obj.y + obj.h / 2) * emu.scale
		if mouse.x <= x2 and mouse.x > x1 and mouse.y <= y2 and mouse.y > y1 then
			if mouse.down and not was_pressed then
				mouse.pressed_key = key
				mouse.pressed = true
			end
		end
	end
	if mouse.pressed then
		vpet:setInput(mouse.pressed_key, true)
		-- TODO: refactor this to be a check into a table of declared functions
		mouse.pressed = false
	elseif was_pressed and not mouse.down and mouse.pressed_key then
		vpet:setInput(mouse.pressed_key, false)
		-- TODO: refactor this to be a check into a table of declared functions
	end
end

function vpet:updatemouse()
	local x1, y1, x2, y2
	local was_hovering = mouse.hovering
	mouse.hovering = false
	mouse.last_x, mouse.last_y = mouse.x, mouse.y
	mouse.x, mouse.y = love.mouse.getPosition()
	mouse.down = love.mouse.isDown(1)
	for key, obj in pairs(vpet.hw.input.buttons) do
		x1, y1, x2, y2 =
			emu.center.x + (obj.x - obj.w / 2) * emu.scale,
			emu.center.y + (obj.y - obj.h / 2) * emu.scale,
			emu.center.x + (obj.x + obj.w / 2) * emu.scale,
			emu.center.y + (obj.y + obj.h / 2) * emu.scale
		if mouse.x <= x2 and mouse.x > x1 and mouse.y <= y2 and mouse.y > y1 then
			mouse.hovering = true
			if not (
				mouse.last_x <= x2 and mouse.last_x > x1 and
				mouse.last_y <= y2 and mouse.last_y > y1
			) then
				-- Starts hovering a button when the mouse button did not go down on another gui button
				mouse.hover_key = key
			elseif mouse.down and not mouse.pressed_key then
				-- mouse button clicked gui button on this frame
				mouse.pressed_key = key
				mouse.holding = true
				print(mouse.hover_key, mouse.pressed_key, mouse.holding)
			elseif mouse.down and key == mouse.pressed_key then
				mouse.holding = true
			end
		end
	end
	if not mouse.down then
		mouse.pressed_key = false
		mouse.holding = false
	end
	if was_hovering and not mouse.hovering then
		-- Stops hovering any button.
		mouse.hover_key = false
		mouse.holding = false
	end
	print(mouse.hover_key, mouse.pressed_key, mouse.holding)
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
						--[[
						subunit.canvas:renderTo(function()
						end)
						--]]
						if cart.draw and type(cart.draw) == 'function' then
							cart:draw()
						end
						love.graphics.draw(
							unit.vram[subunit.page],
							subunit.quad,
							emu.center.x + (unit.x + subunit.x - subunit.w / 2) * emu.scale,
							emu.center.y + (unit.y + subunit.y - subunit.h / 2) * emu.scale,
							0, emu.scale
						)
					elseif subunit.type == 'pixelimage' and subunit.quads then
						local pixel = 0
						local imagedata = unit.vram[0]:newImageData()
						for qi, quad in ipairs(subunit.quads) do
							pixel = vpet:closest_color_index(unit.colors, imagedata:getPixel(qi, 0))
							subunit.quad:setViewport(quad.x, quad.y + pixel * subunit.offset, quad.w, quad.h)
							love.graphics.draw(
								subunit.atlas,
								subunit.quad,
								emu.center.x + (unit.x + subunit.x + quad.x - unit.w / 2) * emu.scale,
								emu.center.y + (unit.y + subunit.y + quad.y - unit.h / 2) * emu.scale,
								0, emu.scale
							)
						end
					end
				end
			end
		end
	end

	---[[ DEBUG DRAW
	love.graphics.draw(
		vpet.hw.output.defaultlcd.vram[0],
		0, 0,
		0, emu.scale
	)
	--]]
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
		if vpet.inputreversemap[key] then
			vpet:setInput(vpet.inputreversemap[key], true)
		end
	end
end

function love.keyreleased(key, scancode, isrepeat)
	if not isrepeat then
		if vpet.inputreversemap[key] then
			vpet:setInput(vpet.inputreversemap[key], false)
		end
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

function vpet:setInput(button, pressed)
	if self.input[button] ~= pressed then
		-- TODO: refactor this to be a check into a table of declared functions
		if cart.event and type(cart.event)=='function' then
			cart:event('button', {button = button, up = not pressed, down = pressed})
		end
		self.input[button] = pressed
	end
end

function vpet:closest_color_index(colors, r, g, b, a)
	if type(r) == 'table' then
		r, g, b, a = unpack(r)
	end
	if type(a) == nil then a = 0 end
	a = a < 128 and 0 or 255
	local distance
	local closest = 0xffffff
	local color
	for i = 0, #colors do
		v = colors[i]
		distance = (v[1] - r) * (v[1] - r) + (v[2] - g) * (v[2] - g) + (v[3] - b) * (v[3] - b)
		if distance < closest then
			closest = distance
			color = i
		end
	end
	return color
end

function vpet:readonlytable(table)
   return setmetatable({}, {
     __index = table,
     __newindex = function(table, key, value)
                    error("Attempt to modify read-only table")
                  end,
     __metatable = false
   });
end

function vpet:initvram(lcd, page, image)
	lcd.vram[page] = love.graphics.newCanvas(lcd.vram.w, lcd.vram.h)
	if image then
		image = self:loadforvram(lcd, page, image)
	end
	lcd.vram[page]:renderTo(function()
		if image then
			love.graphics.draw(image)
		else
			local oldc = {love.graphics.getColor()}
			love.graphics.setColor(lcd.colors[0])
			love.graphics.rectangle('fill', 0, 0, lcd.vram.w, lcd.vram.h)
			love.graphics.setColor(oldc)
		end
	end)
end

function vpet:loadforvram(lcd, page, image)
	local raw
	if type(image) == 'string' then
		image = love.graphics.newImage(image)
		raw = image:getData()
	else
		raw = image:getData()
	end
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
	return love.graphics.newImage(raw)
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
	print('script '..script..' loaded')
	return pcall(f)
end

function vpet:loadhardware(file, dir)
	dir = dir or self.hwenv.hwdir

	local success, hw, error = vpet:loadscript(dir..file, self.hwenv)
	local loaded = {}
	--loaded.dir = dir
	local hw_errors = 0
	local id = dir..file
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
		-- TODO: refactor this function: DRY
		if not names then
			for i, v in ipairs(source) do
				if type(v) == 'string' then
					file = dir..v
					if love.filesystem.exists(file) then
						dest[i] = love.graphics.newImage(file)
					else
						print('hardware '..id..': '..errormessage..' image "'..file..'" not loaded')
						hw_errors = hw_errors + 1
					end
				else
					dest[i] = false
					print('hardware '..id..': '..errormessage..' image: "'..tostring(v)..'" not a string')
				end
			end
		else
			for i, v in ipairs(names) do
				if type(v) == 'string' then
					if source[v] then
						file = dir..source[v]
						if love.filesystem.exists(file) then
							dest[v] = love.graphics.newImage(file)
						else
							print('hardware '..id..': '..errormessage..' image "'..file..'" not loaded')
							hw_errors = hw_errors + 1
						end
					else
						dest[v] = false
						print('hardware '..id..': '..errormessage..' image: "'..tostring(v)..'" not a string')
					end
				end
			end
		end
	end

	if not success then
		hw_errors = -1
		print(hw, error)
		return finish(false, error)
	end

	if type(hw) ~='table' then
		print('hardware descriptor script "'..id..'" returned '..type(hw)..', not table.')
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
		loaded.output.defaultlcd = false
		loaded.output.defaultled = false
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
					if not loaded.output.defaultled then
						loaded.output.defaultled = unit
					end
					load_images(unit, o, {'image_on', 'image_off'}, 'LED'..tostring(i1))
				elseif o.type == 'lcd' then
					if not loaded.output.defaultlcd then
						loaded.output.defaultlcd = unit
					end
					unit.defaultdotmatrix = false
					unit.bgcolor = o.bgcolor
					unit.colors = o.colors
					if o.vram then
						unit.vram = {}
						unit.vram.w = o.vram.w
						unit.vram.h = o.vram.h
						vpet:initvram(unit, 0)
						load_images(unit.vram, o.vram, nil, 'vram')
						for pagenum, image in ipairs(unit.vram) do
							vpet:initvram(unit, pagenum, image)
						end
					end
					local subunit
					for i3, hw_subunit in ipairs(o) do
						subunit = {type = hw_subunit.type}
						if
							subunit.type == 'dotmatrix' or
							subunit.type == 'backlight' or
							subunit.type == 'pixelimage' then
								for key, value in pairs(hw_subunit) do
									subunit[key] = value
								end
						end
						if subunit.type == 'dotmatrix' then
							if not unit.defaultdotmatrix then
								unit.defaultdotmatrix = subunit
							end
							subunit.quad = love.graphics.newQuad(subunit.pagex, subunit.pagey, subunit.w, subunit.h, o.vram.w, o.vram.h)
						elseif subunit.type == 'pixelimage' then
							if subunit.atlas and subunit.quads then
								subunit.atlas = love.graphics.newImage(dir..subunit.atlas)
								local w, h = subunit.atlas:getWidth(), subunit.atlas:getHeight()
								subunit.quad = love.graphics.newQuad(0, 0, w, h, w, h)
								subunit.offset = h / 2
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

function api.blit(srcx, srcy, w, h, destx, desty, src, dest, lcd)
	if type(lcd) == 'number' then
		lcd = vpet.hw.output[lcd]
	elseif type(lcd) ~= 'table' then
		lcd = vpet.hw.output.defaultlcd
	end
	src = src or 2
	dest = dest or 0
	srcx = srcx or 0
	srcy = srcy or 0
	w = w or lcd.vram.w
	h = h or w or lcd.vram.h
	destx = destx or 0
	desty = desty or 0
	lcd.vram.quad:setViewport(srcx, srcy, w, h)
	lcd.vram[dest]:renderTo(function()
		love.graphics.draw(lcd.vram[src], lcd.vram.quad, destx, desty)
	end)
end

function api.pix(x, y, color, dest, lcd)
	color = color or 1
	dest = dest or 0
	if type(lcd) == 'number' then
		lcd = vpet.hw.output[lcd]
	elseif type(lcd) ~= 'table' then
		lcd = vpet.hw.output.defaultlcd
	end
	local oldc = {love.graphics.getColor()}
	love.graphics.setColor(lcd.colors[color])
	lcd.vram[dest]:renderTo(function()
		love.graphics.points(x, y + 1) -- LOVE2D has an off-by-one error to account for here
	end)
	love.graphics.setColor(oldc)
end

function api.rect(x, y, w, h, color, dest, lcd)
	x = x or 0
	y = y or 0
	color = color or 0
	dest = dest or 0
	if type(lcd) == 'number' then
		lcd = vpet.hw.output[lcd]
	elseif type(lcd) ~= 'table' then
		lcd = vpet.hw.output.defaultlcd
	end
	w = w or lcd.vram.w
	h = h or w or lcd.vram.h
	local oldc = {love.graphics.getColor()}
	love.graphics.setColor(lcd.colors[color])
	lcd.vram[dest]:renderTo(function()
		--love.graphics.points(x, y + 1) -- LOVE2D has an off-by-one error to account for here
		love.graphics.rectangle('fill', x, y, w, h)
	end)
	love.graphics.setColor(oldc)
end

function api.led(value)
	local led = vpet.hw.output.defaultled
	if value ~= nil then
		led.on = value and true or false
	end
	return led.on
end

-- deprecated
function api.cls(color, dest, lcd)
	api.rect(0, 0, false, false, color, dest, lcd)
end

function api.drawsprite(sx,sy,x,y)
	api.blit(sx*4, sy*4, 4, 4, x, y)
end
