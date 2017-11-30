local emu = {}
local vpet = {}
local api = {}

function love.load()
	-- Love set-up stuff
	io.stdout:setvbuf('no') -- enable normal use of the print() command
	love.graphics.setDefaultFilter('nearest', 'nearest', 0)

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

	-- load hardware
	vpet.hw = vpet:loadhardware('hw/vpet64/')

	-- console constants
	vpet.SPRITEW = 4
	vpet.SPRITEH = 4
	vpet.screenw = 64
	vpet.screenh = 64
	vpet.minw = 80
	vpet.minh = 120
	vpet.x, vpet.y = -32, -48

	-- vpet stuff
	vpet.convertcolors={
		[0] = {0xdd, 0xee, 0xcc},
		[1] = {0x11, 0x11, 0x22},
	}

	vpet.screen = love.graphics.newCanvas(64, 64, 'rgba4', 0)
	vpet.screen:renderTo(
		function()
			api.cls()
		end
	)

	local cartfolder = 'carts/'
	--cartfolder='rom/'
	cartfolder = cartfolder..'tictactoe/'

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

	-- cheap hack to be refactored out
	vpet.cart = cart

	---- graphics stuff
	-- Loading the console information (rn just a picture)
	vpet.console = {
		image = love.graphics.newImage('hw/vpet64/base.png'),
	}
	vpet.console.x = -math.floor(vpet.console.image:getWidth()/2)
	vpet.console.y = -math.floor(vpet.console.image:getHeight()/2)

	emu.cozy = 2
	emu.center = {}
	emu.scale = 4
	emu.bg = {}
	emu.bg.image = love.graphics.newImage('bg.jpg')
	emu.bg.x, emu.bg.y = 0, 0

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
	vpet.screen:renderTo(
		function()
			if cart.draw and type(cart.draw) == 'function' then
				cart:draw()
			end
		end
	)

	-- scenery background image
	love.graphics.draw(
		emu.bg.image,
		emu.bg.x, emu.bg.y,
		0, emu.bg.scale
	)

	-- base console
	love.graphics.draw(
		vpet.console.image,
		emu.center.x + vpet.console.x*emu.scale,
		emu.center.y + vpet.console.y*emu.scale,
		0, emu.scale
	)

	-- lcd background
	love.graphics.rectangle(
		'fill',
		emu.center.x + (vpet.x - 2) * emu.scale,
		emu.center.y + (vpet.y - 2) * emu.scale,
		(vpet.screenw + 4) * emu.scale, (vpet.screenh + 4) * emu.scale
	)

	--[ screen
	love.graphics.draw(
		vpet.screen,
		emu.center.x + vpet.x*emu.scale,
		emu.center.y + vpet.y*emu.scale,
		0, emu.scale
	)
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
	local scale = math.min(math.floor(w / vpet.minw), math.floor(h / vpet.minh))
	emu.scale = math.max(scale - emu.cozy, 1)
end

function vpet.keyevent(key, released)
	local pressed=false
	if cart.event and type(cart.event)=='function' then -- TODO: refactor this to be a check into a table of declared functions
		for k,v in pairs(vpet.inputmap) do
			pressed=false
			for i,bind in ipairs(v) do
				if bind==key then
					pressed=true
				end
			end
			if pressed then
				cart:event('button', {button = k, up = released, down = not released})
			end
		end
	end
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
			if a==0 then
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
	local malformed = false
	local id = 'HARDWARE'
	if success then
		if type(hw) ~='table' then
			print('hardware descriptor script returned '..type(hw)..', not table.')
			return false, hw
		end
		loaded.info = hw.info
		id = tostring(loaded.info.name or dir or 'HARDWARE')
		if hw.base then
			loaded.base = {}
			if not(hw.base.x and hw.base.y and hw.base.w and hw.base.h) then
				print('hardware '..id..' base geometry malformed')
				malformed = true
			end
		end
		return loaded
	else
		print('hardware in '..dir..' failed to load')
		return false
	end
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
