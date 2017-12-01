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

	if vpet.hw.output then
		for i1, unit in ipairs(vpet.hw.output) do
			if unit.type == 'lcd' then
				print('LCD unit '..i1..' loaded')
				for i2, subunit in ipairs(unit) do
					if subunit.type == 'dotmatrix' then
						subunit.canvas = love.graphics.newCanvas(subunit.w, subunit.h, 'normal', 0)
						subunit.canvas:renderTo(
							function()
								love.graphics.clear(unit.colors[0])
							end
						)
					end
					print('Subunit '..i2..', type '..subunit.type..', of LCD '..i1..' loaded')
				end
			end
		end
	end

	if vpet.hw.base then
		vpet.hw.base.minw = vpet.hw.base.minw or vpet.hw.base.w
		vpet.hw.base.minh = vpet.hw.base.minh or vpet.hw.base.h
	end

	-- console constants
	vpet.SPRITEW = 4
	vpet.SPRITEH = 4

	-- vpet stuff
	vpet.convertcolors={
		[0] = {0xdd, 0xee, 0xcc},
		[1] = {0x11, 0x11, 0x22},
	}

	local cartfolder = 'carts/'
	cartfolder='rom/'
	--cartfolder = cartfolder..'tictactoe/'

	-- load the cart script
	local success
	success, cart = vpet:loadscript(cartfolder..'cart.lua')
	if success then
		print('Cart loaded')
	else
		print(cart)
		cart = {}
		success, cart = vpet:loadscript('rom/splash.lua')
		if success then
			print('Using default cart...')
		else
			cart = {}
		end
	end

	-- load the game's sprites
	local spritefile
	spritefile = cart.spritefile and cartfolder..cart.spritefile or cartfolder..'/sprites.png'
	if not love.filesystem.exists(spritefile) then
		spritefile = 'rom/nocart.png'
	end
	if love.filesystem.exists(spritefile) then
		vpet.sprites = vpet:initsprites(love.graphics.newImage(spritefile))
	else
		vpet.sprites = vpet:initsprites(love.graphics.newImage(love.image.newImageData(64, 64)))
	end

	--vpet.sprites = vpet:initsprites(love.graphics.newImage('rom/font.png'))

	vpet.sprites = vpet:loadvrom(vpet.hw.output[1], nil, 'rom/font.png')

	vpet.spriteQuad = love.graphics.newQuad(0, 0, vpet.SPRITEW, vpet.SPRITEH, vpet.sprites:getWidth(), vpet.sprites:getHeight())

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

function vpet:loadvrom(lcd,type,file)
	local image, raw
	if file then
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
	return love.graphics.newImage(raw)
end

function vpet:initsprites(sprites)
	local raw = sprites:getData()
	local colors = {
		[0]=
		{0xff, 0xff, 0xff}, -- white (paper)
		{0x00, 0x00, 0x00}, -- black (ink)
		--{0xff, 0x00, 0xff}, -- [PLANNED] violet, no change (transparent)
		--{0x00, 0xff, 0x00}, -- [PLANNED] green, invert
	}
	local hadInvalidPixels=false
	raw:mapPixel(
		function(x, y, r, g, b, a)
			-- Currently makes the image have only three colors: white, black, and zero-alpha black
			local valid=false
			local pix
			if a == 0 then
				r,g,b = 0, 0, 0
			else
				r = r > 127 and 255 or 0
				g = g > 127 and 255 or 0
				b = b > 127 and 255 or 0
			end
			for i,v in pairs(colors) do
				if v[1] == r and v[2] == g and v[3] == b then
					valid = true
					pix = self.convertcolors[i] or {r, g, b}
					break
				end
			end
			if not valid then
				hadInvalidPixels=true
				local pix=(r+g+b)/3
				if pix<128 then
					r,g,b = 0,0,0
				else
					r,g,b = 255,255,255
				end
			else
				r,g,b = unpack(pix)
			end
			return r, g, b, a
		end
	)
	if hadInvalidPixels then print('spritesheet had invalid colors!') end
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
					local subunit
					for i3, hw_subunit in ipairs(o) do
						subunit = {type = hw_subunit.type}
						if hw_subunit.type == 'dotmatrix' or hw_subunit.type == 'backlight' then
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
-- TODO: make these be api.* and have the love.load function import them to env under their own table (e.g: vpet)
-- TODO: also, make them better

-- TODO: Make this use stencils for fourthcolor
function api.drawsprite(sx,sy,x,y)
	vpet.spriteQuad:setViewport(sx*vpet.SPRITEW,sy*vpet.SPRITEH,vpet.SPRITEW,vpet.SPRITEH)
	love.graphics.draw(vpet.sprites,vpet.spriteQuad,x,y)
end

function api.pix(x,y,c)
	local oldc = {love.graphics.getColor()}
	if c then
		c = math.floor(c) % 2
	end
	love.graphics.setColor(c)
	--love.graphics.
	love.graphics.setColor(oldc)
end

function api.cls(c)
	c=c or 0
	c=math.floor(c)%2
	love.graphics.clear(vpet.convertcolors[c])
end

-- useful functions

function file_chain(files, fail)
	-- files is an array of file names
	-- fail is an optional callback function in the form of fail(index, filename) which is called when the file doesn't exist
	if type(files) ~= 'table' then print('first argument to file_chain must be a table') return false end
	for i,v in ipairs(files) do
		if love.filesystem.exists(v) then
			return v
		elseif type(fail) ~= 'function' then
			fail(i,v)
		end
	end
	return false
end
