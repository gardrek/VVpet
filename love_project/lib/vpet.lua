local vpet = {}

vpet.const = {}
vpet.const.ghosting = 0x77 / 0xff
vpet.const.imageColor = {1, 1, 1, 1}
vpet.const.debug = false
vpet.const.verbose = false

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

function vpet:terminate()
	if not vpet.running then error('terminate called with no app running') end
	local appstate = vpet.appstack:peek()
	local app = appstate.app
	if #vpet.appstack > 1 then
		-- there's another app on the stack, so return to it
		vpet.appstack:pop()
		vpet.cansub = true
	else
		--[[
		-- there's no more apps on the stack, so restart this one
		local callback = app.callback -- FIXME: ugly hack or pure genius?
		local ok
		ok, appstate.app = pcall(appstate.chunk)
		if not ok then error('woops, app couldn\'t reset??') end
		appstate.app.callback = appstate.app.callback or callback
		appstate.app:callback('init')
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
			app:callback('event', 'button', {button = button, up = not pressed, down = pressed})
		end
		if button == 'home' and pressed then
			if vpet.running then
				api.os.quit()
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

function vpet:loadImage(image, lcd, callback)
	local raw = love.image.newImageData(image)
	if callback then raw:mapPixel(callback) end
	return love.graphics.newImage(raw)
end

function vpet:load1bitImage(image)
	return vpet:loadImage(image, nil,
		function(x, y, r, g, b, a)
			if a < 0.5 or r + g + b <= 1.5 then
				return 0, 0, 0, 0
			else
				return 1, 1, 1, 1
			end
		end
	)
end

function vpet:loadforvram(image, lcd)
	return vpet:loadImage(image, lcd,
		function(x, y, r, g, b, a)
			if a < 0.5 then
				return 0, 0, 0, 0
			else
				r, g, b = unpack(lcd.colors[self:closestColorIndex(lcd.colors, r, g, b, a)])
				return r, g, b, 1
			end
		end
	)
end

--FIXME: DELETEME:
function vpet:load1bitImage_OLD(image)
	local raw
	if type(image) == 'string' then
		raw = love.image.newImageData(image)
		image = love.graphics.newImage(raw)
	end
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

--FIXME: DELETEME:
function vpet:loadforvram_OLD(image, lcd)
	local raw
	if type(image) == 'string' then
		raw = love.image.newImageData(image)
		image = love.graphics.newImage(raw)
	end
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

local function uuid()
	local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	return string.gsub(template, '[xy]', function (c)
		local v = (c == 'x') and love.math.random(0, 0xf) or love.math.random(8, 0xb)
		return string.format('%x', v)
	end)
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

	if vpet.const.verbose then print('Loading Hardware from ' .. id) end

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
		if vpet.const.verbose then print(s) end
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

	if type(hw) ~= 'table' then
		print('hardware descriptor script "' .. id .. '" returned ' .. type(hw) .. ', not table.')
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

	if hw_errors > 0 then return finish(false, hw) end

	if hw.info then
		loaded.info = {}

		if type(hw.info.name) == 'string' then
			loaded.info.name = hw.info.name
		else
			loaded.info.name = uuid()
		end

		if type(hw.info.version) == 'table' then
			loaded.info.version = {}
			for i = 1, 3 do
				loaded.info.version[i] = hw.info.version[i] or 0
			end
		else
			loaded.info.version = {0, 0, 0}
		end

		if type(hw.info.VVpetVersion) == 'table' then
			loaded.info.VVpetVersion = {}
			for i = 1, 3 do
				loaded.info.VVpetVersion[i] = hw.info.VVpetVersion[i] or 0
			end
		else
			loaded.info.VVpetVersion = {0, 0, 0}
		end

		id = loaded.info.name or id
	else
		loaded.info = {
			name = uuid(),
			version = {0, 0, 0},
			VVpetVersion = {0, 0, 0},
		}
	end

	local function loadColor(color)
		if loaded.info.VVpetVersion[1] == 0 then
			return {color[1] / 0xff, color[2] / 0xff, color[3] / 0xff}
		else
			return color
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
					unit.bgcolor = loadColor(o.bgcolor)
					if o.colors then
						unit.colors = {}
						for colorIndex, currentColor in pairs(o.colors) do
							unit.colors[colorIndex] = loadColor(currentColor)
						end
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
						love.graphics.clear{0, 0, 0, 0}
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
			--
		end
	end
	-- END FIXME
	--]]

	return finish(loaded)
end

function vpet:initHW(emu)
	local hw = vpet.hw
	--hw.input.array = {} -- TODO: move vpet.input onto the hardware. not sure what to name it tho...
	for key, obj in pairs(hw.input.buttons) do
		emu.guiButtons['hw_btn_' .. key] = {x1 = -1, y1 = -1, x2 = -1, y2 = -1}
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

function vpet:initHWselector(hwlist)
	--
end

function vpet:stopHWselector()
	local tag = 'hw_selector_'
	for name, btn in pairs(emu.guiButtons) do
		if name:sub(1, #tag) == tag then
			emu.guiButtons[name] = nil
		end
	end
end

--[[
function vpet:select_vram_page(page, lcd)
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
--]]

return vpet
