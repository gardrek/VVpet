local emu = {}
local vpet = {}
emu.center = {}
vpet.env = {}

function love.load()
	-- Love set-up stuff
	io.stdout:setvbuf('no') -- enable normal use of the print() command
	love.graphics.setDefaultFilter('nearest', 'nearest', 0)

	emu.cozy = 2

	-- vpet stuff
	vpet.screen = love.graphics.newCanvas(64,64, 'rgba4', 0)
	vpet.color={
		[0]=
		{255,255,255}, -- {222,238,214,255}, -- white (paper)
		{  0,  0,  0}, -- { 20, 12, 28,255}, -- black (ink)
		{170,  0,170}, -- no change
		{  0,170,170}, -- invert
	}
	vpet.buttons={
		-- system buttons
		-- these buttons are handled differently by the "BIOS"
		[-2] = {'backspace', 'tab'}, -- back
		[-1] = {'escape'}, -- home
		[0] = {'f10'}, -- reset pinhole
		-- acton buttons
		{'1', 'z', 'kp1'}, -- screen button 1, to the left
		{'2', 'x', 'kp2'}, -- screen button 2, in the center
		{'3', 'c', 'kp3'}, -- screen button 3, to the right
		-- direction buttons:
		{'a', 'left', 'kp4'},
		{'d', 'right', 'kp6'},
		{'w', 'up', 'kp8'},
		{'s', 'down', 'kp5'},
	}

	vpet.inputmap = {
		-- system buttons
		-- these buttons are handled differently when an app is run from another app
		back = {'backspace', 'tab'}, -- use to return to a previous screen or cancel something. TODO: hold for x seconds to send home key press, hold for x + y seconds to force-close app
		home = {'escape', 'r'}, -- TODO: pressing home pauses/exits the app, returning to the calling app. long pres force-quits the app. If the app is the top-level app, a force quit will restart the app
		reset = {'f10'}, -- TODO: reset pinhole, clears all user data
		-- screen buttons - numbered left to right
		['1'] = {'1', 'z', 'kp1'}, -- screen button 1, to the left
		['2'] = {'2', 'x', 'kp2'}, -- screen button 2, in the center
		['3'] = {'3', 'c', 'kp3'}, -- screen button 3, to the right
		--['4'] = {'4'}, -- screen button 4, even further to the right on larger units
		-- action buttons are assigned a letter, starting with a for the most-used button
		-- NOTE: The standard vPET does not have action buttons
		a = {'n'},
		b = {'b'},
		-- direction buttons:
		left = {'a', 'left', 'kp4'},
		right = {'d', 'right', 'kp6'},
		up = {'w', 'up', 'kp8'},
		down = {'s', 'down', 'kp5'},
	}

	-- console constants
	vpet.SPRITEW=4
	vpet.SPRITEH=4
	vpet.screenw = 64
	vpet.screenh = 64
	vpet.minw = 80
	vpet.minh = 120
	vpet.scale = 4
	vpet.x, vpet.y = -32, -48
	vpet.screen:renderTo(
		function()
			love.graphics.clear(vpet.color[0])
		end
	)
 
	-- set up cart environment
	local env_globals={
		-- Functions and variables
		--'garbagecollect','dofile','_G','getfenv','load','loadfile','loadstring','setfenv','rawequal','rawget','rawset',
		'assert','error','getmetatable','ipairs','next','pairs','pcall','print','select',
		'tonumber','tostring','type','unpack','_VERSION','xpcall',
		-- Libraries
		'math',
	}
	for i,v in ipairs(env_globals) do
		vpet.env[v]=_G[v]
	end
	vpet.env._G = vpet.env

	-- a list of callback functions for carts. could be handy?
	local cart_returns={
		-- functions
		'update','draw','input',
		-- files
		'bgimage','spritesfile',
	}

	local cartfolder = 'carts/'
	--cartfolder='rom/'
	cartfolder = cartfolder..'tictactoe/'

	-- load the cart script
	local success
	success,cart = vpet:loadscript(cartfolder..'cart.lua')
	if success then
		print('Cart loaded')
	else
		print(cart)
		cart = {}
		success,cart = vpet:loadscript('rom/splash.lua')
		if success then
			print('Using default cart...')
		else
			cart = {}
		end
	end

	---- graphics stuff
	-- Loading the console information (rn just a picture)
	vpet.console = {
		image = love.graphics.newImage('hw/vpet64/base.png'),
	}
	vpet.console.x = -math.floor(vpet.console.image:getWidth()/2)
	vpet.console.y = -math.floor(vpet.console.image:getHeight()/2)

	emu.bg = {}
	emu.bg.image = love.graphics.newImage('bg.jpg')
	emu.bg.x, emu.bg.y = 0, 0

	-- load the game's sprites
	local spritefile
	spritefile = cart.spritefile and cartfolder..cart.spritefile or cartfolder..'/sprites.png'
	if not file_exists(spritefile) then
		spritefile = 'rom/nocart.png'
	end
	if file_exists(spritefile) then
		vpet.sprites = vpet:initsprites(love.graphics.newImage(spritefile))
	else
		vpet.sprites = vpet:initsprites(love.graphics.newImage(love.image.newImageData(64,64)))
	end

	--vpet.sprites = vpet:initsprites(love.graphics.newImage('rom/font.png'))

	vpet.spriteQuad = love.graphics.newQuad(0,0,vpet.SPRITEW,vpet.SPRITEH,vpet.sprites:getWidth(),vpet.sprites:getHeight())

	love.resize()
end

function love.update(dt)
	if cart.update and type(cart.update)=='function' then
		cart:update(dt)
	end
end

function love.draw()
	love.graphics.setColor(255,255,255,255)
	vpet.screen:renderTo(
		function()
			if cart.draw and type(cart.draw)=='function' then
				cart:draw()
			end
		end
	)
	--love.graphics.clear(119,119,119)
	love.graphics.draw(emu.bg.image, emu.bg.x, emu.bg.y, 0, emu.bg.scale, emu.bg.scale)
	love.graphics.draw(vpet.console.image, emu.center.x + vpet.console.x*vpet.scale, emu.center.y + vpet.console.y*vpet.scale, 0, vpet.scale)
	--love.graphics.setColor(0xdd,0xee,0xcc)
	love.graphics.draw(vpet.screen, emu.center.x + vpet.x*vpet.scale, emu.center.y + vpet.y*vpet.scale, 0, vpet.scale)
	love.graphics.setColor(255,255,255,255)
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
			if emu.cozy > 8 then
				emu.cozy = 8
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
	vpet.scale = math.max(scale - emu.cozy, 1)
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
	local validColors={
		{0,0,0},
		{255,255,255},
	}
	local hadInvalidPixels=false
	raw:mapPixel(
		function(x, y, r, g, b, a)
			-- Currently makes the image have only three colors: white, black, and zero-alpha
			local valid=false
			local pix
			if a==0 then
				r,g,b = 0,0,0
			else
				r=r>127 and 255 or 0
				g=g>127 and 255 or 0
				b=b>127 and 255 or 0
			end
			for i,v in pairs(validColors) do
				if v[1]==r and v[2]==b and v[3]==g then
					valid=true
					break
				end
			end
			if not valid then
				hadInvalidPixels=true
				local pix=(r+g+b)/255
				if pix<128 then
					r,g,b = 0,0,0
				else
					r,g,b = 255,255,255
				end
			end
			return r, g, b, a
		end
	)
	if hadInvalidPixels then print('spritesheet had invalid colors!') end
	return love.graphics.newImage(raw)
end

function vpet:loadscript(script)
	local _LuaBCHeader = string.char(0x1B).."LJ"
	local file = io.open(script,'r')
	if file then
		if file:read(3)==_LuaBCHeader then
			print('Bytecode is not allowed.')
			return false
		end
		file:close()
	else
		print('script '..script..' failed to load: file notr opened')
		return false
	end
	local f,error = loadfile(script)
	if not f then print('script '..script..' failed to load: script error') return false,error end
	setfenv(f, self.env)
	return pcall(f)
end

function vpet:loadcart(cart)
	--
end

-- Following are the functions which can be called from within the script

-- TODO: Make this use stencils for fourthcolor
function vpet.env.drawsprite(sx,sy,x,y)
	vpet.spriteQuad:setViewport(sx*vpet.SPRITEW,sy*vpet.SPRITEH,vpet.SPRITEW,vpet.SPRITEH)
	love.graphics.draw(vpet.sprites,vpet.spriteQuad,x,y)
end

function vpet.env.cls(c)
	c=c or 0
	c=math.floor(c)%2
	love.graphics.clear(vpet.color[c])
end

vpet.env.os={
	time=function()
		
	end
}

-- useful functions

function file_exists(name)
	local f=io.open(name,'r')
	if f~=nil then io.close(f) return true else return false end
end
