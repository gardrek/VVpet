local emu = {}
local vpet = {}
local api = {}
local mouse = {}
local draw = {}

function love.load()
	-- Love set-up stuff
	io.stdout:setvbuf('no') -- enable normal use of the print() command
	love.graphics.setDefaultFilter('nearest', 'nearest', 0) -- Pixel scaling
	vpet.IMAGECOLOR = {0xff, 0xff, 0xff, 0xff}

	mouse.last_x, mouse.last_y = love.mouse.getPosition()
	mouse.x, mouse.y = love.mouse.getPosition()

	emu.cozy = 2
	emu.center = {}
	emu.scale = 4
	emu.bg = {
		x = 0,
		y = 0,
		imagefile = 'bg.jpg',
		--imagefile = 'hw/space/bg.jpg',
	}
	if love.filesystem.exists(emu.bg.imagefile) then
		emu.bg.image = love.graphics.newImage(emu.bg.imagefile)
	else
		local img = love.graphics.newCanvas()
		img:renderTo(function()
			love.graphics.clear(0x33, 0x33, 0x33)
		end)
		emu.bg.image = love.graphics.newImage(img:newImageData())
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
		local scale = math.min(math.floor(w / vpet.hw.base.minw), math.floor(h / vpet.hw.base.minh))
		if scale - self.cozy < 1 then
			self.cozy = scale - 1
		end
		self.scale = math.max(scale - self.cozy, 1)
	end

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
		-- action buttons - NOTE: the vPET line does not have action buttons
		a = {'lctrl', 'rctrl', 'v', 'n'},
		b = {'lshift', 'lshift', 'b'},
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
		-- FIXME: This is actually important, I think, so I should explain why here, but I forgot why
		vpet.input[button] = false
	end

	-- set up sandbox environments
	--vpet.osenv = {} -- The OS would conceivably need access to a different environment
	vpet.env = {} -- this is used when loading apps
	vpet.hwenv = {} -- this is used when loading hardware
	local env_globals = {
		-- Functions and variables
		--'garbagecollect', 'dofile', '_G', 'getfenv', 'load', 'loadfile',
		--'loadstring', 'setfenv', 'rawequal', 'rawget', 'rawset',
		'assert', 'error', 'getmetatable', 'ipairs',
		'next', 'pairs', 'pcall', 'print',
		'select', 'setmetatable', 'tonumber', 'tostring',
		'type', 'unpack', '_VERSION', 'xpcall',
		-- Libraries
		'math', 'table', 'string'
	}
	for i, v in ipairs(env_globals) do
		vpet.env[v] = _G[v]
		vpet.hwenv[v] = _G[v]
	end
	vpet.env.vpet = {}
	for k, v in pairs(api) do
		vpet.env.vpet[k] = v
	end
	vpet.env.draw = {}
	for k, v in pairs(draw) do
		vpet.env.draw[k] = v
	end
	vpet.env._G = vpet.env
	vpet.hwenv._G = vpet.hwenv

	vpet.hwenv.inherithw = function(script)
		local f = vpet:loadscript(script, vpet.hwenv)
		if not f then
			error('Hardware file' .. script .. ' could not be loaded')
		end
		local hw = f()
		if type(hw) ~= 'table' then
			error('Hardware file' .. script .. ' did not return table')
		end
		return hw
	end

	-- hardware uses these variables to load _other_ hardware
	vpet.hwenv.dofile = _G.dofile
	vpet.hwenv.hwdir = 'hw/'

	vpet.env.vpet.btn = vpet:readonlytable(vpet.input) -- This way, apps can't spoof the table

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

	local err
	vpet.hw, err = vpet:loadhardware('vpet64.lua', vpet.hwdir)
	--vpet.hw = vpet:loadhardware('vpet48.lua', vpet.hwdir)
	--vpet.hw = vpet:loadhardware('vpet_supertest.lua', vpet.hwdir)
	--vpet.hw = vpet:loadhardware('vv8.lua', vpet.hwdir)
	--vpet.hw, err = vpet:loadhardware('space.lua', vpet.hwdir)
	--vpet.hw, err = vpet:loadhardware('bigpet.lua', vpet.hwdir)

	if not vpet.hw then
		print('Hardware failed to load with the following error:')
		print(err)
		error('Base hardware failed to load!')
	end

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

	local appname
	--appname = 'fonttest'
	--appname = 'tictactoe'
	--appname = 'applist'
	--appname = 'shooter'
	--appname = 'watercaves'

	--vpet.appdir, appname = 'hw/space/apps/', 'shooter'
	vpet.appdir, appname = 'rom/', 'applist'

	--vpet.appdir = 'rom/' -- FIXME:HAXXXX
	--vpet.appdir = 'hw/space/apps/' -- FIXME:HAXXXX
	vpet.cansub = true
	local ok, err = api.subapp(appname, true)
	if not ok then error(err) end
	vpet.appdir = nil -- FIXME:HAXXXX
end

function love.update(dt)
	local appstate = vpet.appstack:peek()
	local app = appstate.app
	vpet:updatemousecheap()
	if app.update and type(app.update) == 'function' then
		app:update(dt)
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
		mouse.pressed = false
	elseif was_pressed and not mouse.down and mouse.pressed_key then
		vpet:setInput(mouse.pressed_key, false)
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
	local appstate = vpet.appstack:peek()
	local app = appstate.app
	if app.draw and type(app.draw) == 'function' then
		app:draw()
	end

	love.graphics.setColor(vpet.IMAGECOLOR)

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
					emu.center.x + (v.x - image:getWidth() / 2) * emu.scale,
					emu.center.y + (v.y - image:getHeight() / 2) * emu.scale,
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
					love.graphics.setColor(vpet.IMAGECOLOR)
					love.graphics.draw(
						image,
						emu.center.x + (unit.x - unit.w / 2) * emu.scale,
						emu.center.y + (unit.y - unit.h / 2) * emu.scale,
						0, emu.scale
					)
				end
			elseif unit.type == 'lcd' then
				if unit.bgcolor then
					love.graphics.setColor(unit.bgcolor)
					love.graphics.rectangle(
						'fill',
						emu.center.x + (unit.x - unit.w / 2) * emu.scale,
						emu.center.y + (unit.y - unit.h / 2) * emu.scale,
						unit.w * emu.scale, unit.h * emu.scale
					)
				end
				love.graphics.setColor(vpet.IMAGECOLOR)
				for subindex, subunit in ipairs(unit) do
					if subunit.type == 'dotmatrix' then
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

	if vpet.DEBUG then
		love.graphics.draw(
			vpet.hw.output.defaultlcd.vram[0],
			0, 0,
			0, emu.scale
		)
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
	end
end

function love.keypressed(key, scancode, isrepeat)
	if not isrepeat then
		--if vpet.DEBUG then print(key, 'pressed') end
		if key == 'f7' then
			vpet.DEBUG = not vpet.DEBUG
		elseif key == '-' then
			emu:setcozy(emu.cozy + 1)
		elseif key == '=' then
			emu:setcozy(emu.cozy - 1)
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

function vpet:setInput(button, pressed)
	local appstate = vpet.appstack:peek()
	local app = appstate.app
	if self.input[button] ~= pressed then
		self.input[button] = pressed
		-- TODO: refactor this to be a check into a table of declared functions, maybe?
		if app.event and type(app.event)=='function' then
			app:event('button', {button = button, up = not pressed, down = pressed})
		end
		if button == 'home' and pressed then
			if #vpet.appstack > 0 then
				api.quit()
			end
		end
	end
end

function vpet:closest_color_index(colors, r, g, b, a)
	if type(r) == 'table' then
		r, g, b, a = unpack(r)
	end
	if not a then a = 0 end
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
		__newindex =
			function(table, key, value)
				error('Attempt to modify read-only table')
			end,
		__metatable = false,
	})
end

function vpet:newpage(image, lcd)
	lcd = lcd or self.hw.output.defaultlcd
	local page = love.graphics.newCanvas(lcd.vram.w, lcd.vram.h)
	if image then
		image = self:loadforvram(image, lcd)
	end
	page:renderTo(function()
		if image then
			love.graphics.setColor(vpet.IMAGECOLOR)
			love.graphics.draw(image)
		else
			love.graphics.setColor(lcd:getColorRGB(0))
			love.graphics.rectangle('fill', 0, 0, lcd.vram.w, lcd.vram.h)
		end
	end)
	return page
end

function vpet:loadforvram(image, lcd)
	local raw
	if type(image) == 'string' then
		image = love.graphics.newImage(image)
	end
	raw = image:getData()
	raw:mapPixel(
		function(x, y, r, g, b, a)
			---[[
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
			--]]return unpack(vpet:closest_color_index(lcd.colors, r, g, b, a))
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
	setfenv(f, env or self.env)
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

function vpet:loadhardware(file, dir)
	dir = dir or self.hwenv.hwdir

	local success, hw = pcall(vpet:loadscript(dir..file, self.hwenv))

	local loaded = {}
	--loaded.dir = dir
	local hw_errors = 0
	local hw_warnings = 0
	local id = dir..file
	local file

	function finish(...)
		local s = 'Hardware '..id
		if hw_errors == 0 then
			s = s..' loaded with no errors'
		elseif hw_errors == -1 then
			s = s..' failed to load'
		elseif hw_errors < 0 then
			s = s..' loaded with negative zero errors. :P'
		else
			s = s..' loaded with '..hw_errors..' errors'
		end
		if hw_warnings > 0 then
			s = s..' ('..hw_warnings..' warnings)'
		end
		print(s)
		return ...
	end

	if not success then
		hw_errors = -1
		print(hw)
		return finish(false, hw)
	end

	function load_images(dest, source, names, errormessage)
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
					if love.filesystem.exists(file) then
						dest[i] = love.graphics.newImage(file)
					else
						print('hardware '..id..': '..errormessage..' image "'..file..'" not loaded')
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
						if love.filesystem.exists(file) then
							dest[v] = love.graphics.newImage(file)
						else
							print('hardware '..id..': '..errormessage..' image "'..file..'" not loaded')
							hw_errors = hw_errors + 1
						end
					elseif v then
						dest[v] = false
						--print('hardware '..id..': '..errormessage..' image: "'..tostring(v)..'" not a string')
						hw_warnings = hw_warnings + 1
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
		loaded.base.scale = hw.base.scale or 1
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
					if unit.colors then
						unit.colornames = o.colornames or {}
						function unit:getColorRGB(index)
							local color = self.colors[index] or self.colors[self.colornames[index]]
							if color then
								return color
							else
								if vpet.fallbackcolors[index] then
									vpet.usedfallbackcolor(index)
									return self.colors[vpet:closest_color_index(self.colors, vpet.fallbackcolors[index])]
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
					if type(o.vram.font) == 'string' and love.filesystem.exists(dir..o.vram.font) then
						local image = love.graphics.newImage(dir..o.vram.font)
						local oldc = {love.graphics.getColor()}
						love.graphics.setColor(vpet.IMAGECOLOR)
						unit.vram.font:renderTo(function()
							love.graphics.draw(image)
						end)
						love.graphics.setColor(oldc)
					else
						print(id..' font was not loaded')
						hw_warnings = hw_warnings + 1
					end
					-- TODO: Handle backlight here
					local subunit
					for i3, hw_subunit in ipairs(o) do
						subunit = {type = hw_subunit.type}
						if
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

	local geometry_default = {
		x = 0, y = 0,
		w = 8, h = 8,
		scale = 1,
	}

	function set_defaults(unit, default)
		default = default or geometry_default
		for k, v in pairs(default) do
			if not unit[k] then
				unit[k] = v
				hw_warnings = hw_warnings + 1
			end
		end
	end

	for index, unit in ipairs(loaded.output) do
		if unit.type == 'led' then
			
		end
	end

	return finish(loaded)
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

-- Following are the functions and variables which can be accessed from within the script

-- Other hardware commands

function api.led(value, led)
	led = led or vpet.hw.output.defaultled
	if value ~= nil then
		led.on = value and true or false
	end
	return led.on
end

function api.loadpage(file, page, lcd)
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

function api.subapp(appname, cansub)
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
		draw.setColor(1, 0)
		draw.setDest(0, 'screen')
		draw.setSrc(0, 'screen')
		local ok
		ok, appstate.app = pcall(appstate.chunk)
		if not ok then
			vpet.appstack:pop(appstate)
			print('app failed to load')
			return false, appstate.app
		end
		if type(appstate.app) ~= 'table' then
			vpet.appstack:pop(appstate)
			return false, 'app returned ' .. type(appstate.app) .. ' instead of table'
		else
			if not appstate.vram[1] then
				appstate.vram[1] = vpet:newpage()
			end
			draw.setSrc(1, 'app')
		--if cansub then appstate.app.applist = vpet:listapps('apps/') end
			vpet.cansub = cansub
			return true
		end
	else
		return false, appdir
	end
end

function api.quit()
	if #vpet.appstack > 1 then
		-- there's another app on the stack, so return to it
		vpet.appstack:pop()
		vpet.cansub = true
	else
		-- there's no more apps on the stack, so restart this one
		local appstate = vpet.appstack:peek()
		local ok
		ok, appstate.app = pcall(appstate.chunk)
		if not ok then error('woops, app couldn\'t reset??') end
	end
end

function api.listapps()
	if vpet.cansub then return vpet:listapps('apps/') else error() end
end

-- These are the new draw functions --------

function draw.setColor(color, bgcolor)
	local appstate = vpet.appstack:peek()
	local drawstate = appstate.vram.draw
	drawstate.color = color or drawstate.color
	drawstate.bgcolor = bgcolor or drawstate.bgcolor
	love.graphics.setColor(appstate.desthw:getColorRGB(drawstate.color))
end

function draw.getColor()
	local appstate = vpet.appstack:peek()
	return appstate.vram.draw.color, appstate.vram.draw.bgcolor
end

function draw.setDest(page, hw)
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

function draw.setSrc(page, hw)
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

function draw.cls(color)
	local vram = vpet.appstack:peek().vram
	local oldc, bgc = draw.getColor()
	draw.setColor(color or bgc)
	draw.rect()
	draw.setColor(oldc)
end

function draw.rect(x, y, w, h)
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

function draw.pix(x, y)
	x = math.floor(x)
	y = math.floor(y)
	vpet.appstack:peek().dest:renderTo(function()
		love.graphics.points(x, y + 1) -- UPSTREAM: LOVE2D has an off-by-one error to account for here
	end)
end

function draw.blit(srcx, srcy, w, h, destx, desty)
	local appstate = vpet.appstack:peek()
	srcx = srcx or 0
	srcy = srcy or 0
	w = w or appstate.dest:getWidth()
	h = h or appstate.dest:getHeight()
	destx = destx or 0
	desty = desty or 0
	local quad = vpet.hw.output.defaultlcd.vram.quad
	quad:setViewport(srcx, srcy, w, h)
	love.graphics.setColor(vpet.IMAGECOLOR)
	appstate.dest:renderTo(function()
		love.graphics.draw(appstate.src, quad, destx, desty)
	end)
	draw.setColor()
end

function draw.text(str, x, y, align, rect)
	local appstate = vpet.appstack:peek()
	str = tostring(str)
	x = x or 0
	y = y or 0
	align = align or 1
	-- TODO: currently, text uses a special src page that can be colorized. I'd like to generalize this eventually
	local oldc, bgc = draw.getColor()
	local oldsrc = appstate.src
	appstate.src = vpet.hw.output.defaultlcd.vram.font
	local ch, srcx, srcy, xi, yi, width
	width = #str * 4
	xi = ((align - 1) * width) / 2
	yi = 0
	if rect then
		draw.setColor(type(rect) == 'number' and rect or bgc)
		draw.rect(x + xi - 1, y + yi, width + 1, 8)
	end
	-- FIXME: HAAAAXXXX
	local oldIMAGECOLOR = vpet.IMAGECOLOR
	vpet.IMAGECOLOR = appstate.desthw:getColorRGB(oldc)
	for i = 1, #str do
		ch = str:byte(i)
		srcx = (ch % 16) * 4
		srcy = math.floor(ch / 16) * 8
		draw.blit(srcx, srcy, 4, 8, x + (i - 1) * 4 + xi, y + yi)
	end
	vpet.IMAGECOLOR = oldIMAGECOLOR
	draw.setColor(oldc, bgc)
	appstate.src = oldsrc
end

function draw.line(x0, y0, x1, y1)
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
		draw.pix(x0, y0)
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
