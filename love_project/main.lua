--dofile('strict.lua')

local emu = {}
local mouse = {}

local vpet = {}
vpet.const = {}
vpet.const.ghosting = 0x77
vpet.const.imageColor = {0xff, 0xff, 0xff, 0xff}

local api = {}
api.vpet = {}
api.draw = {}
api.hw = {}
api.os = {
	time = os.time,
	date = os.date,
	difftime = os.difftime,
}

local hwapi = {}

--vpet.DEBUG = true

function love.load()
	-- Love set-up stuff
	io.stdout:setvbuf('no') -- enable normal use of the print() command
	love.graphics.setDefaultFilter('linear', 'nearest', 0) -- Pixel scaling

	mouse.last_x, mouse.last_y = love.mouse.getPosition()
	mouse.x, mouse.y = love.mouse.getPosition()

	emu.cozy = 2
	emu.center = {}
	emu.scale = 4
	emu.bg = {
		x = 0,
		y = 0,
		imagefile = 'bg.jpg',
	}
	emu.guiButtons = {}

	if love.filesystem.exists(emu.bg.imagefile) then
		emu.bg.image = love.graphics.newImage(emu.bg.imagefile)
	else
		local img = love.graphics.newCanvas()
		img:renderTo(function()
			love.graphics.clear(0x33, 0x33, 0x33)
		end)
		emu.bg.image = love.graphics.newImage(img:newImageData())
		print('Background image ' .. emu.bg.imagefile .. ' not found.')
	end

	emu.bg.image:setFilter('linear', 'linear')

	-- Load the input. TODO: This should probably be in emu, and of course be loaded from a config file

	vpet.inputmap = {
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
	}

	-- stores a table of which button inputs are down
	vpet.input = {}

	vpet.inputreversemap = {} -- Oh, I'm not like the input at all... Some would say, I'm the Reverse.

	for button, vvv in pairs(vpet.inputmap) do
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
		--'garbagecollect', 'dofile', '_G', 'getfenv', 'load', 'loadfile',
		--'loadstring', 'setfenv', 'rawequal', 'rawget', 'rawset',
		'assert', 'error', 'getmetatable', 'ipairs',
		'next', 'pairs', 'pcall', 'print',
		'select', 'setmetatable', 'tonumber', 'tostring',
		'type', 'unpack', '_VERSION', 'xpcall',
		-- Libraries
		'math', 'table', 'string', 'bit'
	}

	-- Fallback colors, for finding the closest color to common color names
	vpet.fallbackcolors = {
		-- 1-bit RGB
		Black = {0x00, 0x00, 0x00},
		Blue = {0x00, 0x00, 0xff},
		Green = {0x00, 0xff, 0x00},
		Cyan = {0x00, 0xff, 0xff},
		Red = {0xff, 0x00, 0x00},
		Magenta = {0xff, 0x00, 0xff},
		Yellow = {0xff, 0xff, 0x00},
		White = {0xff, 0xff, 0xff},
		-- Extra common colors
		Gray = {0x7f, 0x7f, 0x7f},
		Grey = {0x7f, 0x7f, 0x7f},
		Orange = {0xff, 0x7f, 0x00},
		Pink = {0xff, 0x00, 0x7f},
	}

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
	--vpet.hw, err = vpet:loadHW('space.lua')
	--vpet.hw, err = vpet:loadHW('actionpet.lua')

	DEBUG_PRINT_TABLE(vpet.hw)

	if not vpet.hw then
		print('Hardware failed to load with the following error:')
		print(err)
		error()
	end

	vpet:initHW(emu)
	--]]

	emu.guiButtons['TEST_BUTTON'] = {
		x1 = 300, y1 = 100, x2 = 500, y2 = 200
	}

	-- FIXME: Setting the window mode sometimes clears canvases
	--emu:setMinGeometry(vpet.hw)

	love.resize()

	-- load the software --------

	-- app stack --------
	vpet.appstack = {}

	function vpet.appstack:push(a)
		table.insert(self, a)
	end

	function vpet.appstack:pop()
		return table.remove(self)
	end

	function vpet.appstack:peek(i)
		i = i or 0
		return self[#self - i]
	end

	---[[
	local appname
	--appname = 'fonttest'
	--appname = 'tictactoe'
	--appname = 'applist'
	--appname = 'shooter'
	--appname = 'watercaves'

	--vpet.appdir, appname = 'hw/space/apps/', 'shooter' -- FIXME:HAXXXX
	vpet.appdir, appname = 'rom/', 'applist' -- FIXME:HAXXXX

	vpet.cansub = true
	local ok, err = api.vpet.subapp(appname, true)
	if not ok then error(err) end
	vpet.appdir = nil -- FIXME:HAXXXX

	vpet.running = true
	--]]

	---[[
	local hwnames = {
		'vpet64.lua',
		'actionpet.lua',
		'vv8.lua',
		'space.lua',
		'vpet64icon.lua',
	}
	vpet.hwchoices = {}

	local hw, err
	for i, name in ipairs(hwnames) do
		hw, err = vpet:loadHW(name)
		if hw then
			table.insert(vpet.hwchoices, hw)
		else
			print(err)
		end
	end
	--]]
end

function love.update(dt)
	emu:updatemousecheap()
	if vpet.running then
		local appstate = vpet.appstack:peek()
		local app = appstate.app
		if app.update and type(app.update) == 'function' then
			app:update(dt)
		end
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
				if unit.frametime >= 0.016 then
					unit.frametime = unit.frametime % 0.016
					love.graphics.setColor(vpet.const.imageColor)
					unit.shadowCanvasFront:renderTo(function()
						love.graphics.clear({0, 0, 0, 0})
						love.graphics.draw(unit.screenCanvas)
						love.graphics.draw(unit.shadowCanvasBack)
					end)
					unit.shadowCanvasBack:renderTo(function()
						if unit.ghosting then love.graphics.setColor({0xff, 0xff, 0xff, unit.ghosting or vpet.const.ghosting}) end
						love.graphics.draw(unit.screenCanvas)
					end)
				end
			end
		end
	end
end

function emu:updatemousecheap()
	local x1, y1, x2, y2
	mouse.last_x, mouse.last_y = mouse.x, mouse.y
	mouse.x, mouse.y = love.mouse.getPosition()
	local was_pressed = mouse.down
	mouse.down = love.mouse.isDown(1)

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

	for name, btn in pairs(emu.guiButtons) do
		if not mouse.down then btn.pressed = false end
		if mouse.x <= btn.x2 and mouse.x > btn.x1 and mouse.y <= btn.y2 and mouse.y > btn.y1 then
			if mouse.down and not was_pressed then
				mouse.pressed_key = btn.key
				mouse.pressed = true
				btn.pressed = true
			end
		end
	end

	if mouse.pressed then
		if mouse.pressed_key then
			vpet:setInput(mouse.pressed_key, true)
		end
		mouse.pressed = false
	elseif was_pressed and not mouse.down and mouse.pressed_key then
		if mouse.pressed_key then
			vpet:setInput(mouse.pressed_key, false)
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
	if vpet.running then
		local appstate = vpet.appstack:peek()
		local app = appstate.app
		if app.draw and type(app.draw) == 'function' then
			app:draw()
		end
	end

	love.graphics.setColor(vpet.const.imageColor)

	-- scenery background image
	love.graphics.draw(
		emu.bg.image,
		emu.bg.x, emu.bg.y,
		0, emu.bg.scale
	)

	if vpet.hw then
		vpet:drawHW(vpet.hw, emu.center.x, emu.center.y, emu.scale, vpet.input)
	else
		local x, y, scale
		local offset = -love.graphics.getWidth() / 3
		for i, hw in ipairs(vpet.hwchoices) do
			x, y = emu.center.x + offset, emu.center.y
			scale = love.graphics.getHeight() / hw.base.h / 3
			love.graphics.setColor(vpet.fallbackcolors['Orange'])
			love.graphics.rectangle('line',
				x + hw.base.x * scale,
				y + hw.base.y * scale,
				hw.base.w * scale,
				hw.base.h * scale
			)
			love.graphics.setColor(vpet.const.imageColor)
			vpet:drawHW(hw, x, y, scale / hw.base.image_scale / hw.base.scale)
			offset = offset + scale * 150 -- (-hw.base.x + (hw.base.w * hw.base.w) / hw.base.h) * (scale / hw.base.image_scale / hw.base.scale)
			--(hw.base.w + hw.base.x) * (scale) * 2
		end
	end

	if vpet.DEBUG then
		if vpet.hw and vpet.hw.output and vpet.hw.output.defaultlcd then
			love.graphics.setColor(vpet.const.imageColor)
			love.graphics.draw(
				--vpet.hw.output.defaultlcd.vram[0],
				vpet.hw.output.defaultlcd.screenCanvas,
				0, 0,
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
			else
				love.graphics.setColor(vpet.fallbackcolors['Cyan'])
			end
			love.graphics.rectangle('line', v.x1, v.y1, v.x2 - v.x1, v.y2 - v.y1)
			--love.graphics.setColor(vpet.const.imageColor)
			love.graphics.print(name, v.x1 + 2, v.y1 + 2)
		end

		--[[
		local x, y, w, h, index
		h = love.graphics.getHeight() / 20
		w = h
		x = love.graphics.getWidth() - w
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

function vpet:drawHW(hw, x, y, scale, input)
		-- Draw the hardware base/background/shell
	if hw.base.image then
		love.graphics.draw(
			hw.base.image,
			x + hw.base.x * scale * hw.base.scale * hw.base.image_scale,
			y + hw.base.y * scale * hw.base.scale * hw.base.image_scale,
			0, scale * hw.base.scale * hw.base.image_scale
		)
	end

	-- draw buttons
	if hw.input and hw.input.buttons then
		local image
		for k,v in pairs(hw.input.buttons) do
			if input then
				image = input[k] and v.image_down or v.image_up or v.image
			else
				image = v.image_up or v.image
			end
			if image then
				love.graphics.draw(
					image,
					x + (v.x * hw.base.scale - image:getWidth() / 2 * v.scale) * scale,
					y + (v.y * hw.base.scale - image:getHeight() / 2 * v.scale) * scale,
					0, scale * v.scale
				)
			end
		end
	end

	---[=======[draw outputs
	if hw.output then
		local image
		for index, unit in ipairs(hw.output) do
			if unit.type == 'led' then
				image = unit.on and unit.image_on or unit.image_off
				if image then
					love.graphics.setColor(self.const.imageColor)
					love.graphics.draw(
						image,
						x + (unit.x * hw.base.scale - unit.w / 2 * unit.scale) * scale,
						y + (unit.y * hw.base.scale - unit.h / 2 * unit.scale) * scale,
						0, scale * unit.scale
					)
				end
			elseif unit.type == 'lcd' then
				---[[
				love.graphics.setColor(self.const.imageColor)
				unit.screenCanvas:renderTo(function()
					for subindex, subunit in ipairs(unit) do
						if subunit.type == 'dotmatrix' then
							love.graphics.draw(
								unit.vram[subunit.page],
								subunit.quad,
								unit.w / 2 + subunit.x - subunit.w / 2 * subunit.scalex,
								unit.h / 2 + subunit.y - subunit.h / 2 * subunit.scaley,
								0, subunit.scalex, subunit.scaley
							)
						elseif subunit.type == 'pixelimage' and subunit.quads then
							local pixel = 0
							local imagedata = unit.vram[0]:newImageData()
							for qi, quad in ipairs(subunit.quads) do
								pixel = self:closestColorIndex(unit.colors, imagedata:getPixel(qi, 0))
								subunit.quad:setViewport(quad.x, quad.y + pixel * subunit.offset, quad.w, quad.h)
								love.graphics.draw(
									subunit.atlas,
									subunit.quad,
									unit.w / 2 + subunit.x + quad.x - unit.w / 2 * subunit.scalex,
									unit.h / 2 + subunit.y + quad.y - unit.h / 2 * subunit.scaley,
									0, 1
								)
							end
						end
					end
				end)
				love.graphics.setColor(self.const.imageColor)
				love.graphics.draw(
					unit.shadowCanvasFront,
					x + (unit.x * hw.base.scale - unit.w / 2 * unit.scale) * scale,
					y + (unit.y * hw.base.scale - unit.h / 2 * unit.scale) * scale,
					0, scale * unit.scale
				)
			end
		end
	end
	--]=======]
end

function love.keypressed(key, scancode, isrepeat)
	if not isrepeat then
		if key == 'f7' then
			vpet.DEBUG = not vpet.DEBUG
		elseif key == '-' then
			emu:setcozy(emu.cozy + 1)
		elseif key == '=' then
			emu:setcozy(emu.cozy - 1)
		elseif key == '9' then
			vpet.const.ghosting = vpet.const.ghosting - 0x11
		elseif key == '0' then
			vpet.const.ghosting = vpet.const.ghosting + 0x11
		elseif key == '7' then
			vpet.const.ghosting = vpet.const.ghosting - 0x1
		elseif key == '8' then
			vpet.const.ghosting = vpet.const.ghosting + 0x1
		end
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

function vpet:setInput(button, pressed)
	local appstate, app
	if vpet.running then
		appstate = vpet.appstack:peek()
		app = appstate.app
	end
	if self.input[button] ~= pressed then
		self.input[button] = pressed
		-- TODO: refactor this to be a check into a table of declared functions, maybe?
		if app and type(app.event) == 'function' then
			app:event('button', {button = button, up = not pressed, down = pressed})
		end
		if button == 'home' and pressed then
			if vpet.running then
				api.vpet.quit()
			end
		end
	end
end

function vpet:closestColorIndex(colors, r, g, b, a)
	if type(r) == 'table' then
		r, g, b, a = unpack(r)
	end
	if not a then a = 0 end
	a = a < 128 and 0 or 255
	local distance
	local closest = 0xffffff
	local color
	local v
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

function vpet:newEnv(api_tables, global_names)
	local env = {}
	local g, t

	global_names = global_names or vpet.global_names

	if type(global_names) ~= 'table' or type(api_tables) ~= 'table' then
		error('Arguments should be tables', 2)
	end

	for i, name in ipairs(global_names) do
		g = _G[name]
		t = type(g)
		if g == nil then
			print('Warning: attempted to add nil ' .. tostring(name) .. ' to environment')
		elseif t == 'string' or t == 'number' or t == 'function' or t == 'boolean' then
			env[name] = _G[name]
		elseif t == 'table' then
			env[name] = {}
			for funcname, func in pairs(g) do
				if type(func) == 'table' or type(func) == 'userdata' or type(func) == 'thread' then
					print('Warning: ' .. type(func) .. ' ' .. tostring(funcname) .. ' in library ' .. tostring(name) .. '. not added.')
				else
					env[name][funcname] = func
				end
			end
		else
			print('Warning: attempted to add ' .. t .. ' ' .. name .. ' to environment')
		end
	end

	for apiname, subapi in pairs(api_tables) do
		t = type(subapi)
		if t == 'nil' then
			print('Warning: attempted to add nil ' .. tostring(apiname) .. ' to environment')
		elseif t == 'string' or t == 'number' or t == 'function' or t == 'boolean' then
			env[apiname] = subapi
		elseif type(subapi) == 'table' then
			if env[apiname] and type(env[apiname]) ~= 'table' then
				print('warning: newEnv overwriting ' .. tostring(apiname) .. ' with table')
				env[apiname] = {}
			elseif not env[apiname] then
				env[apiname] = {}
			else
				print('appending to api ' .. tostring(apiname))
			end
			for funcname, func in pairs(subapi) do
				if type(func) == 'table' or type(func) == 'userdata' or type(func) == 'thread' then
					print('Warning: ' .. type(func) .. ' ' .. tostring(funcname) .. ' in api ' .. tostring(apiname) .. '. not added.')
				else
					env[apiname][funcname] = func
				end
			end
		end
	end

	-- The following functions overwrite Lua built-ins --------
	-- These keep containment in the sandbox --------

	if env.math and env.math.randomseed then
		local prng = love.math.newRandomGenerator(os.time())

		function env.math.random(...)
			return prng:random(...)
		end

		function env.math.randomseed(seed)
			prng:setSeed(seed)
		end
	end

	if env.getmetatable then
		function env.getmetatable(t)
			if type(t) ~= 'table' then
				error('Attempt to call getmetatable on non-table value', 2)
			else
				return getmetatable(t)
			end
		end
	end

	if env.setmetatable then
		function env.setmetatable(t, mt)
			if type(t) ~= 'table' then
				error('Attempt to call setmetatable on non-table value', 2)
			else
				return setmetatable(t, mt)
			end
		end
	end

	env._G = env

	return env
end

function vpet:newpage(image, lcd)
	lcd = lcd or self.hw.output.defaultlcd
	local page = love.graphics.newCanvas(lcd.vram.w, lcd.vram.h)
	if image then
		image = self:loadforvram(image, lcd)
	end
	page:renderTo(function()
		if image then
			love.graphics.setColor(vpet.const.imageColor)
			love.graphics.draw(image)
		else
			love.graphics.setColor(lcd:getColorRGB(0))
			love.graphics.rectangle('fill', 0, 0, lcd.vram.w, lcd.vram.h)
		end
	end)
	return page
end

function vpet:load1bitImage(image)
	if type(image) == 'string' then
		image = love.graphics.newImage(image)
	end
	local raw = image:getData()
	raw:mapPixel(
		function(x, y, r, g, b, a)
			if a < 128 or r + g + b <= 382 then
				return 0, 0, 0, 0
			else
				return 255, 255, 255, 255
			end
		end
	)
	return love.graphics.newImage(raw)
end

function vpet:loadforvram(image, lcd)
	if type(image) == 'string' then
		image = love.graphics.newImage(image)
	end
	local raw = image:getData()
	raw:mapPixel(
		function(x, y, r, g, b, a)
			if a < 128 then
				return 0, 0, 0, 0
			else
				r, g, b = unpack(lcd.colors[self:closestColorIndex(lcd.colors, r, g, b, a)])
				return r, g, b, 255
			end
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
	if not ok then
		print('script '..script..' failed to load')
		return false, f
	end
	setfenv(f, env or self:newEnv(api))
	--print('script '..script..' loaded')
	return f
end

function vpet:loadapp(appname, dir)
	if type(appname) ~= 'string' then
		print(appname, ' (name) not a string')
	end
	dir = dir or 'apps/'
	if type(dir) ~= 'string' then
		print(dir, ' (dir) not a string')
	end
	local list = self:listapps(dir)
	local appinfo
	for index, info in ipairs(list) do
		if info.name == appname then
			appinfo = info
			break
		end
	end
	if appinfo then
		local app, err = self:loadscript(appinfo.file)
		if not app then return false, err end
		return app, appinfo.dir
	else
		print('App '..appname..' not found in '..dir)
	end
end

function vpet:appinfo(file)
	if not love.filesystem.exists(file) then return false end
	-- this match gives the directory, the filename, and the ext if it exists, or the filename again if not
	local dir, filename, ext = file:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
	local appname
	if filename == ext then
		ext = ''
		appname = filename
	else
		appname = filename:sub(1, -#ext - 2)
	end
	-- now, appname is the name, without any extension, ext is empty if there is no extension
	local isapp
	local appfile, datadir
	if love.filesystem.exists(file) then
		if ext == '' then
			if love.filesystem.isDirectory(file) then
				datadir = dir..filename..'/'
				appfile = datadir..filename..'.lua'
				if not love.filesystem.isFile(appfile) then
					appfile = datadir..'app.lua'
					if not love.filesystem.isFile(appfile) then
						appfile = nil
					end
				end
				if appfile then
					isapp = true
				end
			end
		elseif ext:lower() == 'lua' then
			if love.filesystem.isFile(file) then
				datadir = dir
				appfile = file
				isapp = true
			end
		end
	end
	--print(isapp, dir, appname, ext, appfile, datadir)
	if isapp then
		return {file = appfile, dir = datadir, name = appname}
	else
		return false
	end
end

function vpet:listapps(dir)
	local files = love.filesystem.getDirectoryItems(dir)
	local list = {}
	local info
	for fileindex, file in ipairs(files) do
		info = vpet:appinfo(dir..file)
		if info then
			table.insert(list, info)
		end
	end
	return list
end

function vpet:loadHW(file, dir)
	dir = dir or hwapi.getDir()

	local success, hw = pcall(vpet:loadscript(dir..file, self:newEnv(hwapi)))

	local loaded = {}
	--loaded.dir = dir
	local hw_errors = 0
	local hw_warnings = 0
	local id = dir .. file
	local file

	print('Loading Hardware from ' .. id)

	local function finish(...)
		local s = 'Hardware ' .. id
		if hw_errors == 0 then
			s = s .. ' loaded with no errors'
		elseif hw_errors == -1 then
			s = s .. ' failed to load'
		elseif hw_errors < 0 then
			s = s .. ' loaded with negative zero errors. :P'
		else
			s = s .. ' loaded with '..hw_errors..' errors'
		end
		if hw_warnings > 0 then
			s = s .. ' ('..hw_warnings..' warnings)'
		end
		print(s)
		return ...
	end

	if not success then
		hw_errors = -1
		print(hw)
		return finish(false, hw)
	end

	local function load_images(dest, source, names, errormessage)
		-- If given an array of keys (names), checks (source) for each key,
		-- and if found, attempts to load that keys value as an image, then
		-- stores the image in the same key in (dest)
		-- If (names) is _not_ given, it treats (source) as an array, and
		-- stores in (dest) as an array
		local file
		if not names then
			for i, v in ipairs(source) do
				if type(v) == 'string' then
					file = dir..v
					if love.filesystem.isFile(file) then
						dest[i] = love.graphics.newImage(file)
					else
						print('hardware '..id..': '..errormessage..' image "'..file..'" not a file')
						hw_errors = hw_errors + 1
					end
				elseif v then
					dest[i] = false
					print('hardware '..id..': '..errormessage..' image: "'..tostring(v)..'" not a string')
					hw_warnings = hw_warnings + 1
				end
			end
		else
			for i, v in ipairs(names) do
				if type(v) == 'string' then
					if source[v] then
						file = dir..source[v]
						if love.filesystem.isFile(file) then
							dest[v] = love.graphics.newImage(file)
						else
							print('hardware '..id..': '..errormessage..' image "'..file..'" not a file')
							hw_errors = hw_errors + 1
						end
					elseif v then
						--[[
						dest[v] = false
						print('hardware '..id..': '..errormessage..' image: "'..tostring(v)..'" not a string ')
						hw_warnings = hw_warnings + 1
						--]]
					end
				end
			end
		end
	end

	if type(hw) ~='table' then
		print('hardware descriptor script "'..id..'" returned '..type(hw)..', not table.')
		hw_errors = -1
		return finish(false, hw)
	end

	local categories = {'info', 'base', 'output', 'input'}
	for i,v in ipairs(categories) do
		if type(hw[v]) ~= 'table' and type(hw[v]) ~= 'nil' then
			--hw[v] = nil
			print('hardware error: key "'..tostring(v)..'" must be table if it exists')
			hw_errors = hw_errors + 1
		end
	end

	if hw_errors > 0 then return finish({}) end

	if hw.info then
		id = hw.info.name or dir
		loaded.info = {}
		for key, val in pairs(hw.info) do
			loaded.info[key] = val
		end
	end

	if hw.base then
		loaded.base = {}
		loaded.base.defaultscale = hw.base.defaultscale or 1
		loaded.base.scale = hw.base.scale or loaded.base.defaultscale

		local malformed = false
		for i, v in ipairs{'x', 'y', 'w', 'h', 'minw', 'minh'} do
			if hw.base[v] then
				loaded.base[v] = hw.base[v]
			else
				hw_errors = hw_errors + 1
				malformed = true
			end
		end
		loaded.base.x = loaded.base.x or 0
		loaded.base.y = loaded.base.y or loaded.base.x or 0
		loaded.base.w = loaded.base.w or 64
		loaded.base.h = loaded.base.h or loaded.base.w or 64
		loaded.base.minw = loaded.base.minw or loaded.base.w
		loaded.base.minh = loaded.base.minh or loaded.base.h

		file = dir .. hw.base.image
		if love.filesystem.isFile(file) then
			loaded.base.image = love.graphics.newImage(file)
			if hw.base.image_linear_filter then
				loaded.base.image_linear_filter = true
				loaded.base.image:setFilter('linear', 'linear')
			end
			loaded.base.image_scale = hw.base.image_scale or 1
		else
			print('hardware ' .. id .. ': base image "' .. file .. '" not loaded')
			hw_errors = hw_errors + 1
		end
		if malformed then
			print('hardware ' .. id .. ': base geometry malformed')
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
						unit.scale = o.scale or loaded.base.defaultscale
					end
				end
				if o.type == 'led' then
					if not loaded.output.defaultled then
						loaded.output.defaultled = unit
					end
					load_images(unit, o, {'image_on', 'image_off'}, 'LED' .. tostring(i1))
				elseif o.type == 'lcd' then
					if o.default or not loaded.output.defaultlcd then
						loaded.output.defaultlcd = unit
						unit.default = true
					end
					unit.defaultdotmatrix = false
					unit.bgcolor = o.bgcolor
					unit.colors = o.colors
					if unit.colors then
						unit.colornames = o.colornames or {}
						function unit:getColorRGB(index)
							local color = self.colors[index] or self.colors[self.colornames[index]]
							if color then
								return color
							else
								if vpet.fallbackcolors[index] then
									vpet.usedfallbackcolor(index)
									return self.colors[vpet:closestColorIndex(self.colors, vpet.fallbackcolors[index])]
								else
									error('color ' .. tostring(index) .. ' does not exist', 2)
								end
							end
						end
					end
					if o.vram then
						unit.vram = {}
						unit.vram.w = o.vram.w
						unit.vram.h = o.vram.h
						unit.vram.quad = love.graphics.newQuad(0, 0, unit.vram.w, unit.vram.h, unit.vram.w, unit.vram.h)
						unit.vram[0] = vpet:newpage(nil, unit)
						load_images(unit.vram, o.vram, nil, 'vram')
						for pagenum, image in ipairs(unit.vram) do
							unit.vram[pagenum] = vpet:newpage(image, unit)
						end
						unit.vram.defaultpage = unit.vram[#unit.vram]
					end
					unit.vram.font = love.graphics.newCanvas(unit.vram.w, unit.vram.h)
					if type(o.vram.font) == 'string' and love.filesystem.exists(dir .. o.vram.font) then
						local image = vpet:load1bitImage(dir .. o.vram.font)
						love.graphics.setColor(vpet.const.imageColor)
						unit.vram.font:renderTo(function()
							love.graphics.draw(image)
						end)
					else
						print(id .. ' font was not loaded')
						hw_warnings = hw_warnings + 1
					end
					unit.ghosting = o.ghosting
					unit.screenCanvas = love.graphics.newCanvas(unit.w, unit.h)
					unit.shadowCanvasFront = love.graphics.newCanvas(unit.w, unit.h)
					unit.shadowCanvasBack = love.graphics.newCanvas(unit.w, unit.h)
					unit.shadowCanvasBack:renderTo(function()
						love.graphics.setColor(unit.bgcolor)
						love.graphics.rectangle('fill', 0, 0, unit.w, unit.h)
					end)
					unit.shadowCanvasFront:renderTo(function()
						love.graphics.clear({0, 0, 0, 0})
						love.graphics.draw(unit.screenCanvas)
						love.graphics.draw(unit.shadowCanvasBack)
					end)
					unit.frametime = 0
					-- TODO: Handle backlight here
					local subunit
					for i3, hw_subunit in ipairs(o) do
						subunit = {type = hw_subunit.type}
						subunit.scale = hw_subunit.scale or 1
							-- so, with the two lines below, the subunit's scalex and scaley are made relative to the unit's scale
							-- scalex, scaley, and/or scale are defined in hw files as absolute scale
							-- additionally, is scale is defined and so is either scalex or scaley, then scale is multiplied by the others
						subunit.scalex = hw_subunit.scalex and (hw_subunit.scalex / unit.scale) * subunit.scale or subunit.scale / unit.scale
						subunit.scaley = hw_subunit.scaley and (hw_subunit.scaley / unit.scale) * subunit.scale or subunit.scale / unit.scale
						if -- FIXME: this should not import all keys
							subunit.type == 'dotmatrix' or
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
			elseif type(o.type) == 'string' then
				print('unknown output of type ' .. o.type .. ' not loaded')
			else
				print('output type ' .. tostring(o.type) .. ' not a string; output not loaded')
			end
		end
	end

	if hw.input then
		loaded.input = {}
		if hw.input.buttons then
			loaded.input.buttons = {}
			for button, t in pairs(hw.input.buttons) do
				loaded.input.buttons[button] = {
					x = t.x,
					y = t.y,
					h = t.h,
					w = t.w,
					scale = t.scale or loaded.base.defaultscale,
				}
				load_images(loaded.input.buttons[button], t, {'image', 'image_up', 'image_down'}, 'Button')
			end
		end
	end

	--[[FIXME: remove or use this code
	local geometry_default = {
		--x = 0, y = 0,
		--w = 8, h = 8,
		scale = 1,
	}

	local function set_defaults(unit, default)
		default = default or geometry_default
		for k, v in pairs(default) do
			if not (unit[k] and type(unit[k]) == 'number') then
				unit[k] = v
				hw_warnings = hw_warnings + 1
			end
		end
	end

	for index, unit in ipairs(loaded.output) do
		if unit.type == 'led' then
			
		end
	end
	--END FIXME
	--]]

	return finish(loaded)
end

function vpet:initHW(emu)
	local hw = vpet.hw
	--hw.input.array = {} -- TODO: move vpet.input onto the hardware. not sure what to name it tho...
	for key, obj in pairs(hw.input.buttons) do
		emu.guiButtons['hw_btn_' .. key] = {}
		hw.input[key] = false
	end
end

function vpet:stopHW(emu)
	local hw = vpet.hw
	vpet.hw = nil
	--hw.input.array = nil -- TODO: move vpet.input onto the hardware. not sure what to name it tho...
	for key, obj in pairs(hw.input.buttons) do
		emu.guiButtons['hw_btn_' .. key] = nil
	end
	return hw
end

function select_vram_page(page, lcd)
	local lcd_raw = lcd
	if type(lcd) == 'number' then
		lcd = vpet.hw.output[lcd]
	elseif type(lcd) ~= 'table' then
		lcd = vpet.hw.output.defaultlcd
	end
	if not lcd then error('No such LCD '..tostring(lcd_raw), 2) end
	if not lcd.vram then error('LCD '..tostring(lcd)..' has no vram', 2) end
	if type(page) == 'number' then
		page = lcd.vram[page]
	elseif type(page) ~= 'userdata' then -- check for passing an actual page
		page = lcd.vram[0]
	end
	if not page then
		page = lcd.vram.defaultpage
		--error('LCD has no vram page '..tostring(page), 2)
	end
	return page, lcd
end

-- These functions are used within hardware description files

function hwapi.getDir()
	return 'hw/'
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

function DEBUG_PRINT_TABLE(enum)
	for k0, v0 in pairs(enum) do
		print(k0, v0)
		if type(v0) == 'table' then
			for k1, v1 in pairs(v0) do
				print(' ', k1, v1)
				if type(v1) == 'table' then
					for k2, v2 in pairs(v1) do
						print(' ', ' ', k2, v2)
						if type(v2) == 'table' then
							for k3, v3 in pairs(v2) do
								print(' ', ' ', ' ', k3, v3)
							end
						end
					end
				end
			end
		end
	end
end

-- Old hardware commands, to be deprecated

-- TODO: Deprecate
function api.vpet.btn(button)
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

-- TODO: Deprecate
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

function api.vpet.subapp(appname, cansub)
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

function api.vpet.quit()
	if not vpet.running then error'' end -- Should not be necessary; running api.* functions should be disallowed whenan app is not running
	local appstate = vpet.appstack:peek()
	local app = appstate.app
	if app then
		if type(app.event) == 'function' then
			app:event('quit', {})
		end
		if type(app.quit) == 'function' then
			app.quit()
		end
	end
	if #vpet.appstack > 1 then
		-- there's another app on the stack, so return to it
		vpet.appstack:pop()
		vpet.cansub = true
	else
		-- there's no more apps on the stack, so restart this one
		local ok
		ok, appstate.app = pcall(appstate.chunk)
		if not ok then error('woops, app couldn\'t reset??') end
	end
end

function api.vpet.listapps()
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
