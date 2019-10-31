--dofile('lib/strict.lua')

-- Global declarations
emu = {}
emu.mouse = {}
vpet = require('lib/vpet')
api = require('lib/api')
hwapi = {}

-- this stops you from (accidentally) assigning new globals after this point
-- you can still use rawset, tho
--dofile('lib/noglobals.lua')
-- TODO: should it also cause an error on _access_ of unassigned globals?

-- this global can turn the effects of noglobals off
--rawset(_G, '_ALLOWGLOBALS', true)

function love.run()
	local TICKRATE = 1 / 60

	if love.math then
		love.math.setRandomSeed(os.time())
	end

	if love.load then love.load(arg) end

	local previous = love.timer.getTime()
	local lag = 0.0
	while true do
		local current = love.timer.getTime()
		local elapsed = current - previous
		previous = current
		lag = lag + elapsed

		if love.event then
			love.event.pump()
			for name, a, b, c, d, e, f in love.event.poll() do
				if name == 'quit' then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a, b, c, d, e, f)
			end
		end

		while lag >= TICKRATE do
			if love.update then love.update(TICKRATE) end
			lag = lag - TICKRATE
		end

		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			-- The new argument to love.draw is the percentage of the last tick that is left over
			-- Not sure what to use it for, but the app draw functions don't even use love.draw, so it doesn't much matter
			if love.draw then love.draw(lag / TICKRATE) end
			love.graphics.present()
		end
	end
end

function love.load(arg)
	--[[
	for i = -1, #arg do
		print(i, arg[i])
	end
	--]]

	-- Love set-up stuff
	io.stdout:setvbuf('no') -- enable normal use of the print() command
	love.graphics.setDefaultFilter('nearest', 'nearest') -- Pixel scaling

	local config = vpet:loadscript('vpet-config.lua', {})
	if config then config = config() else error'Config file not found. You may need to reinstall...' end

	emu.mouse.last_x, emu.mouse.last_y = love.mouse.getPosition()
	emu.mouse.x, emu.mouse.y = love.mouse.getPosition()
	emu.mouse.cursor_arrow = love.mouse.getSystemCursor('arrow')
	emu.mouse.cursor_hand = love.mouse.getSystemCursor('hand')

	emu.cozy = 2
	emu.center = {}
	emu.scale = 4
	emu.bg = {
		x = 0,
		y = 0,
		imagefile = 'bg.jpg',
	}
	emu.guiButtons = {}

	if love.filesystem.getInfo(emu.bg.imagefile) ~= nil then
		emu.bg.image = love.graphics.newImage(emu.bg.imagefile)
	else
		local img = love.graphics.newCanvas()
		img:renderTo(function()
			local grey = 0x33 / 0xff
			love.graphics.clear{grey, grey, grey}
		end)
		emu.bg.image = love.graphics.newImage(img:newImageData())
		print('Background image ' .. emu.bg.imagefile .. ' not found.')
	end

	emu.bg.image:setFilter('linear', 'linear')

	-- Load the input. TODO: This should probably be in emu, and of course be loaded from a config file

	emu.inputmap = config.inputmap --[[or {
		-- system buttons - these buttons are handled differently when an app is run from inside another app
		-- TODO: implement apps calling other apps
		back = {'backspace'}, -- use to return to a previous screen or cancel something.
		home = {'escape'}, -- TODO: Use to return to the app which started the app you'e in
		reset = {'f10'}, -- TODO: reset pinhole, clears all user data
		-- screen buttons - numbered left to right
		['1'] = {'1', 'z'},
		['2'] = {'2', 'x'},
		['3'] = {'3', 'c'},
		-- action buttons - NOTE: some vPET consoles do not have action buttons
		a = {'lctrl', 'rctrl', 'v', 'n'},
		b = {'lshift', 'rshift', 'b'},
		-- direction buttons:
		left = {'a', 'left'},
		right = {'d', 'right'},
		up = {'w', 'up'},
		down = {'s', 'down'},
	}]]

	-- stores a table of which button inputs are down
	vpet.input = {}

	vpet.inputreversemap = {} -- Oh, I'm not like the input at all... Some would say, I'm the Reverse.

	for button, vvv in pairs(emu.inputmap) do
		for iii, emukey in ipairs(vvv) do
			-- Put in a keyboard key and it gives you the button that key is assigned to
			vpet.inputreversemap[emukey] = button
		end
		-- This way, if a button just doesn't exist, you get nil, but if it does,
		-- you get false when it's not pushed and true when it is
		-- TODO: Maybe make it return the number of frames or something useful
		-- instead of just true?
		vpet.input[button] = false
	end

	-- set up sandbox environments

	hwapi.hwdir = hwapi.getDir() -- TODO: deprecate

	vpet.global_names = {
		-- Functions and variables
		--'collectgarbage', 'dofile', '_G', 'getfenv', 'load', 'loadfile',
		--'loadstring', 'setfenv', 'rawequal', 'rawget', 'rawset',
		'assert', 'error', 'pcall', 'xpcall', 'getmetatable', 'setmetatable',
		'next', 'pairs', 'ipairs', 'print', '_VERSION',
		'select', 'unpack', 'type', 'tonumber', 'tostring',
		-- Libraries
		'math', 'table', 'string', 'bit'
	}

	-- Fallback colors, for finding the closest color to common color names
	vpet.fallbackcolors = {
		-- 1-bit RGB
		Black    = {0x00, 0x00, 0x00},
		Blue     = {0x00, 0x00, 0xff},
		Green    = {0x00, 0xff, 0x00},
		Cyan     = {0x00, 0xff, 0xff},
		Red      = {0xff, 0x00, 0x00},
		Magenta  = {0xff, 0x00, 0xff},
		Yellow   = {0xff, 0xff, 0x00},
		White    = {0xff, 0xff, 0xff},
		-- Extra common colors
		Gray     = {0x7f, 0x7f, 0x7f},
		Grey     = {0x7f, 0x7f, 0x7f},
		Orange   = {0xff, 0x7f, 0x00},
		Pink     = {0xff, 0x00, 0x7f},
	}

	for index, color in pairs(vpet.fallbackcolors) do
		if type(color) == 'table' then
			--vpet.fallbackcolors[index] = color:dup() / 0xff
			for i = 1, 3 do
				vpet.fallbackcolors[index][i] = vpet.fallbackcolors[index][i] / 0xff
			end
		end
	end


	local _usedfallbackcolor = {}
	vpet.usedfallbackcolor = function(index)
		if not _usedfallbackcolor[index] then
			print('Using fallback color "' .. index .. '".')
			_usedfallbackcolor[index] = true
		end
	end

	-- load hardware --------

	---[[
	local err
	--vpet.hw, err = vpet:loadHW('bad.lua')
	vpet.hw, err = vpet:loadHW('vpet64.lua')
	--vpet.hw, err = vpet:loadHW('vpet64icon.lua')
	--vpet.hw, err = vpet:loadHW('vv8.lua')
	--vpet.hw, err = vpet:loadHW('vv16.lua')
	--vpet.hw, err = vpet:loadHW('grey8.lua')
	--vpet.hw, err = vpet:loadHW('space.lua')
	--vpet.hw, err = vpet:loadHW('actionpet.lua')

	--DEBUG_PRINT_TABLE(vpet.hw)

	if not vpet.hw then
		print('Hardware failed to load with the following error:')
		print(err)
		error()
	end

	vpet:initHW(emu)
	--]]

	-- FIXME: Setting the window mode sometimes clears canvases
	--emu:setMinGeometry(vpet.hw)

	love.resize()

	-- load the software --------

	---[[
	local appname
	--appname = 'fonttest'
	--appname = 'tictactoe'
	--appname = 'applist'
	--appname = 'shooter'
	--appname = 'watercaves'

	--vpet.appdir, appname = 'hw/space/apps/', 'shooter' -- FIXME:HAXXXX
	vpet.appdir, appname = 'rom/', 'applist' -- FIXME:HAXXXX
	--appname = 'bigfont'
	--appname = 'raycast'

	vpet.cansub = true
	local ok, err = api.os.subapp(appname, true)
	if not ok then error(err) end
	vpet.appdir = nil -- FIXME:HAXXXX

	vpet.running = true
	--]]

	---[[
	local hwnames = {
		'vpet64.lua',
		'actionpet.lua',
		'vv8.lua',
		'quadlu.lua',
		'tall.lua',
		'space.lua',
		'vpet64icon.lua',
	}

	vpet.hwchoices = {}

	local hw, err
	for i, name in ipairs(hwnames) do
		hw, err = vpet:loadHW(name)
		if hw then
			table.insert(vpet.hwchoices, {hw = hw})
			---[[
			emu.guiButtons['hw_selector_' .. hw.info.name] = {
				x1 = -1, x2 = -1, y1 = -1, y2 = -1,
				action = function(self)
					vpet:stopHWselector()
					vpet.hw = self.hw
					vpet:initHW(emu)
					emu:setcozy()
				end,
				hw = hw,
			}
			--]]
		else
			print(err)
		end
	end

	local canvas, scale
	for i, v in ipairs(vpet.hwchoices) do
		scale = v.hw.base.scale
		canvas = love.graphics.newCanvas(v.hw.base.w * scale, v.hw.base.h * scale)
		canvas:renderTo(function()
			vpet:drawHW(v.hw, math.floor(v.hw.base.w / 2) * scale, math.floor(v.hw.base.h / 2) * scale, 1)
		end)
		v.image = love.graphics.newImage(canvas:newImageData())
		v.image:setFilter('linear', 'linear')
	end
	--]]
end

function love.update(dt)
	emu:updatemousecheap()
	if vpet.running then
		local appstate = vpet.appstack:peek()
		local app = appstate.app
		app:callback('tick')
		app:callback('update', dt)
		app:callback('draw')
	end
	-- Simulate LCD ghosting.
	--[[ Process:
	Clear SF to alpha
	Draw D to SF normally
	Draw SB to SF normally
	Draw D to SB translucently
	Draw SF to screen normally (in love.draw)
	]]
	if vpet.hw and vpet.hw.output then
		for index, unit in ipairs(vpet.hw.output) do
			if unit.type == 'lcd' then
				unit.frametime = unit.frametime + dt
				--if unit.frametime >= 0.016 then
					unit.frametime = unit.frametime % 0.016
					love.graphics.setColor(vpet.const.imageColor)
					unit.shadowCanvasFront:renderTo(function()
						love.graphics.clear{0, 0, 0, 0}
						love.graphics.draw(unit.screenCanvas)
						love.graphics.draw(unit.shadowCanvasBack)
					end)
					unit.shadowCanvasBack:renderTo(function()
						--if unit.ghosting then love.graphics.setColor({0xff, 0xff, 0xff, unit.ghosting}) end
						love.graphics.setColor{1, 1, 1, vpet.const.ghosting}
						love.graphics.draw(unit.screenCanvas)
					end)
				--end
			end
		end
	end
end

function emu:updatemousecheap()
	local x1, y1, x2, y2
	self.mouse.last_x, self.mouse.last_y = self.mouse.x, self.mouse.y
	self.mouse.x, self.mouse.y = love.mouse.getPosition()
	local was_pressed = self.mouse.down
	self.mouse.down = love.mouse.isDown(1)

	if vpet.hw then
		for key, obj in pairs(vpet.hw.input.buttons) do
			x1, y1, x2, y2 =
				self.center.x + (obj.x * vpet.hw.base.scale - obj.w / 2 * obj.scale) * self.scale,
				self.center.y + (obj.y * vpet.hw.base.scale - obj.h / 2 * obj.scale) * self.scale,
				self.center.x + (obj.x * vpet.hw.base.scale + obj.w / 2 * obj.scale) * self.scale,
				self.center.y + (obj.y * vpet.hw.base.scale + obj.h / 2 * obj.scale) * self.scale
			local b = emu.guiButtons['hw_btn_' .. key]
			b.x1, b.y1, b.x2, b.y2 = x1, y1, x2, y2
			b.key = key -- TODO: fix this hackiness
		end
	end

	local action = false
	self.mouse.hover = false
	for name, btn in pairs(emu.guiButtons) do
		if not self.mouse.down then btn.pressed = false end
		if self.mouse.x <= btn.x2 and self.mouse.x > btn.x1 and self.mouse.y <= btn.y2 and self.mouse.y > btn.y1 then
			if self.mouse.down and not was_pressed then
				self.mouse.pressed_key = btn.key
				self.mouse.pressed = true
				btn.pressed = true
				if btn.action then action = btn end
			end
			btn.hover = true
			self.mouse.hover = true
		else
			btn.hover = false
		end
	end
	if action then action:action() end

	if self.mouse.hover then
		love.mouse.setCursor(self.mouse.cursor_hand)
	else
		love.mouse.setCursor(self.mouse.cursor_arrow)
	end

	if self.mouse.pressed then
		if self.mouse.pressed_key then
			vpet:setInput(self.mouse.pressed_key, true)
		end
		self.mouse.pressed = false
	elseif was_pressed and not self.mouse.down and self.mouse.pressed_key then
		if self.mouse.pressed_key then
			vpet:setInput(self.mouse.pressed_key, false)
		end
	end
end

--[[
function updatemouse()
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
--]]

function love.draw()
	-- scenery background image
	love.graphics.setColor(vpet.const.imageColor)
	love.graphics.draw(
		emu.bg.image,
		emu.bg.x, emu.bg.y,
		0, emu.bg.scale
	)

	if vpet.hw then
		vpet:drawHW(vpet.hw, emu.center.x, emu.center.y, emu.scale, vpet.input)
	else
		local line_h = love.graphics.getHeight() / 5
		local x, y, scale, hwscale
		local spacing = love.graphics.getHeight() / 50
		local offset = -love.graphics.getHeight() / 3 * 2
			- love.graphics.getHeight() / 3 * (vpet.input['left'] and 1 or 0)
			+ love.graphics.getHeight() / 3 * (vpet.input['right'] and 1 or 0)
		local hw
		for i, hwchoice in ipairs(vpet.hwchoices) do
			hw = hwchoice.hw
			x, y = emu.center.x + offset, emu.center.y - line_h / 2
			scale = line_h / hw.base.h
			hwscale = scale / hw.base.image_scale / hw.base.scale
			love.graphics.setColor(vpet.const.imageColor)
			--vpet:drawHW(hw, x + hw.base.w / 2 * scale, y, hwscale)
			love.graphics.draw(hwchoice.image, x, y, 0, hwscale)
			emu.guiButtons['hw_selector_' .. hw.info.name].x1 = x
			emu.guiButtons['hw_selector_' .. hw.info.name].y1 = y
			emu.guiButtons['hw_selector_' .. hw.info.name].x2 = x + hw.base.w * scale
			emu.guiButtons['hw_selector_' .. hw.info.name].y2 = y + line_h --hw.base.h * scale
			offset = offset + hw.base.w * scale + spacing
		end
	end

	if vpet.const.debug then
		if vpet.hw and vpet.hw.output and vpet.hw.output.defaultlcd then
			love.graphics.setColor(vpet.const.imageColor)
			love.graphics.draw(
				--vpet.hw.output.defaultlcd.vram[0],
				vpet.hw.output.defaultlcd.screenCanvas,
				0, 0,
				0, emu.scale
			)

			love.graphics.draw(
				vpet.hw.output.defaultlcd.vram[0],
				0, love.graphics.getHeight() - vpet.hw.output.defaultlcd.vram[0]:getHeight() * emu.scale,
				0, emu.scale
			)

			love.graphics.setColor(vpet.fallbackcolors['Orange'])
			love.graphics.rectangle('line',
				emu.center.x + vpet.hw.base.x * emu.scale * vpet.hw.base.scale * vpet.hw.base.image_scale,
				emu.center.y + vpet.hw.base.y * emu.scale * vpet.hw.base.scale * vpet.hw.base.image_scale,
				vpet.hw.base.w * emu.scale * vpet.hw.base.scale * vpet.hw.base.image_scale,
				vpet.hw.base.h * emu.scale * vpet.hw.base.scale * vpet.hw.base.image_scale
			)
		end

		for name, v in pairs(emu.guiButtons) do
			if v.pressed then
				love.graphics.setColor(vpet.fallbackcolors['Pink'])
			elseif v.hover then
				love.graphics.setColor(vpet.fallbackcolors['Orange'])
			else
				love.graphics.setColor(vpet.fallbackcolors['Cyan'])
			end
			love.graphics.rectangle('line', v.x1, v.y1, v.x2 - v.x1, v.y2 - v.y1)
			--love.graphics.setColor(vpet.const.imageColor)
			love.graphics.print(name, v.x1 + 2, v.y1 + 2)
		end

		---[[
		local x, y, w, h, index, t
		h = love.graphics.getHeight() / 20
		w = h
		x = love.graphics.getWidth() - w
		if vpet.hw then
			t = vpet.hw.output.defaultlcd.colors
			for index = 0, #t do
				color = t[index]
				love.graphics.setColor(color)
				y = index * h
				love.graphics.rectangle('fill', x, y, w, h)
			end
		end
		--]]

		--[[
		local x, y, w, h, index
		h = love.graphics.getHeight() / 20
		w = h
		x = love.graphics.getWidth() - w * 2
		index = 1
		for name, color in pairs(vpet.fallbackcolors) do
			love.graphics.setColor(color)
			y = (index - 1) * h
			love.graphics.rectangle('fill', x, y, w, h)
			index = index + 1
		end
		--]]
	end
end

function love.keypressed(key, scancode, isrepeat)
	if not isrepeat then
		if key == 'f7' then
			vpet.const.debug = not vpet.const.debug
		elseif key == 'f2' then
			local appname = 'applist'
			vpet.appdir = 'rom/' -- FIXME:HAXXXX
			vpet.cansub = true
			local ok, err = api.os.subapp(appname, true)
			if not ok then error(err) end
			vpet.appdir = nil -- FIXME:HAXXXX
			vpet.running = true
		elseif key == 'f3' then
			local appname = 'app'
			vpet.appdir = 'hw/quadlu/' -- FIXME:HAXXXX
			vpet.cansub = true
			local ok, err = api.os.subapp(appname, true)
			if not ok then error(err) end
			vpet.appdir = nil -- FIXME:HAXXXX
			vpet.running = true
		elseif key == '-' then
			emu:setcozy(emu.cozy + 1)
		elseif key == '=' then
			emu:setcozy(emu.cozy - 1)
		elseif key == '9' then
			vpet.const.ghosting = vpet.const.ghosting - 0x11
		elseif key == '0' then
			vpet.const.ghosting = vpet.const.ghosting + 0x11
		elseif key == '7' then
			vpet.const.ghosting = vpet.const.ghosting - 0x01
		elseif key == '8' then
			vpet.const.ghosting = vpet.const.ghosting + 0x01
		end
		if vpet.const.ghosting < 0x00 then vpet.const.ghosting = 0x00 end
		if vpet.const.ghosting > 0xff then vpet.const.ghosting = 0xff end
		if vpet.inputreversemap[key] then
			vpet:setInput(vpet.inputreversemap[key], true)
		end
	end
end

function love.keyreleased(key, scancode)
	if vpet.inputreversemap[key] then
		vpet:setInput(vpet.inputreversemap[key], false)
	end
end

function love.resize(w, h)
	w = w or love.graphics.getWidth()
	h = h or love.graphics.getHeight()
	emu.center.x = math.floor(w/2)
	emu.center.y = math.floor(h/2)
	emu.bg.scale = math.max(w / emu.bg.image:getWidth(), h / emu.bg.image:getHeight())
	emu.bg.x = emu.center.x - (emu.bg.image:getWidth()/2 * emu.bg.scale)
	emu.bg.y = emu.center.y - (emu.bg.image:getHeight()/2 * emu.bg.scale)
	emu:setcozy()
end

function emu:setcozy(newcozy)
	if newcozy then
		self.cozy = newcozy
	end
	if self.cozy < 0 then
		self.cozy = 0
	end
	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()
	if not vpet.hw then return end
	local scale = math.min(
		math.floor(w / (vpet.hw.base.minw * vpet.hw.base.scale)),
		math.floor(h / (vpet.hw.base.minh * vpet.hw.base.scale))
	)
	if scale - self.cozy < 1 then
		self.cozy = scale - 1
	end
	self.scale = math.max(scale - self.cozy, 1)
end

function emu:setMinGeometry(hw)
	local w, h, flags = love.window.getMode()
	local minw, minh = hw.base.minw * hw.base.scale, hw.base.minh * hw.base.scale
	if flags.minwidth ~= minw or flags.minheight ~= minh then
		flags.minwidth = minw
		flags.minheight = minh
		love.window.setMode(w, h, flags)
	end
end

-- These functions are used within hardware description files

function hwapi.getDir()
	return 'hw/' -- FIXME: idek what this is. need to do documentation, and clean
end

function hwapi.inherithw(script)
	local f, err = vpet:loadscript(script, vpet:newEnv(hwapi))
	if not f then
		print(err)
		error('Hardware file ' .. script .. ' could not be loaded')
	end
	local hw = f()
	if type(hw) ~= 'table' then
		error('Hardware file ' .. script .. ' did not return table')
	end
	return hw
end

--[[
function DEBUG_PRINT_TABLE(enum)
	for k0, v0 in pairs(enum) do
		print(k0, v0)
		if type(v0) == 'table' then
			for k1, v1 in pairs(v0) do
				print('', k1, v1)
				if type(v1) == 'table' then
					for k2, v2 in pairs(v1) do
						print('', '', k2, v2)
						if type(v2) == 'table' then
							for k3, v3 in pairs(v2) do
								print('', '', '', k3, v3)
							end
						end
					end
				end
			end
		end
	end
end
--]]
