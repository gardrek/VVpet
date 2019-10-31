local game = {}

-- Vector class
vec2 = {}
vec2.__index = vec2

function vec2:new(x, y)
	local obj = {}
	if type(x) == 'number' and type(y) == 'number' then
		obj.x, obj.y = x, y
	else
		error('attempt to create vector with non-number values', 2)
	end
	setmetatable(obj, self)
	return obj
end

function vec2:mag()
	return math.sqrt(self.x * self.x + self.y * self.y)
end
vec2.__len = vec2.mag

function vec2:magsqr()
	return self.x * self.x + self.y * self.y
end

function vec2:rotate(angle)
	local cs, sn, px, py
	cs, sn = math.cos(angle), math.sin(angle)
	nx = self.x * cs - self.y * sn
	ny = self.x * sn + self.y * cs
	return vec2:new(nx, ny)
end

function vec2:__add(other)
	if type(other) == 'number' then
		return vec2:new(self.x + other, self.y + other)
	end
	if type(self) == 'number' then
		return vec2:new(self + other.x, self + other.y)
	end
	return vec2:new(self.x + other.x, self.y + other.y)
end

function vec2:__sub(other)
	if type(other) == 'number' then
		return vec2:new(self.x - other, self.y - other)
	end
	if type(self) == 'number' then
		return vec2:new(self - other.x, self - other.y)
	end
	return vec2:new(self.x - other.x, self.y - other.y)
end

function vec2:__mul(other)
	if type(other) == 'number' then
		return vec2:new(self.x * other, self.y * other)
	end
	if type(self) == 'number' then
		return vec2:new(self * other.x, self * other.y)
	end
	return vec2:new(self.x * other.x, self.y * other.y)
end

function vec2:__div(other)
	if type(other) == 'number' then
		return vec2:new(self.x / other, self.y / other)
	end
	if type(self) == 'number' then
		return vec2:new(self / other.x, self / other.y)
	end
	return vec2:new(self.x / other.x, self.y / other.y)
end

function vec2:__unm()
	return vec2:new(-self.x, -self.y)
end

function vec2:norm()
	return self / self:mag()
end

function vec2:__tostring()
	return '(' .. tostring(self.x) .. ', ' .. tostring(self.y) .. ')'
end

function vec2:draw(x, y, arrow)
	if arrow then
		local a, b
		local m = self:mag() / 4
		a = self:rotate(math.pi / 6):norm() * -m
		b = self:rotate(math.pi / -6):norm() * -m
		draw.line(self.x + x, self.y + y, self.x + x + a.x, self.y + y + a.y)
		draw.line(self.x + x, self.y + y, self.x + x + b.x, self.y + y + b.y)
	end
	draw.line(x, y, self.x + x, self.y + y)
end

map = {}

function map:init(w, h, wall, empty)
	self.w = w or self.w
	self.h = h or self.h
	wall = wall or 1
	empty =  empty or 0
	for yi = 1, self.h do
		local layer = {}
		for xi = 1, self.w do
			if xi == 1 or xi == self.w or yi == 1 or yi == self.h then
				layer[xi] = wall
			else
				layer[xi] = empty
			end
		end
		self[yi] = layer
	end
end

--map:init(256, 256)

---[[
map = {
	w = 24, h = 24,
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,0,0,0,0,4,0,0,0,8,0,7,0,6,0,5,0,0,0,0,1},
	{1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,0,0,0,0,4,0,0,0,4,0,3,0,2,0,1,0,0,0,0,1},
	{1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}--]]

function map:drawMini(x, y, scale)
	scale = scale or 1
	for yi = 1, self.h do
		for xi = 1, self.w do
			if self[yi][xi] > 0 then
				--draw.pix(x + xi - 1, y + yi - 1)
				draw.rect((x + xi - 1) * scale, (y + yi - 1) * scale, scale, scale)
			end
		end
	end
end

player = {
	pos = vec2:new(2.5, 2.5),
	dir = vec2:new(-1, 0),
	plane = vec2:new(0, 0.66),
}

function player:turn(angle)
	self.dir = self.dir:rotate(angle)
	self.plane = self.plane:rotate(angle)
end

player:turn(math.pi * -3 / 4)

screen = {}

function get_size()
	-- Find all output devices,
	for _, output in ipairs(hw.getInfo()['output']) do
		if output.type == 'lcd' then
			for _, device in ipairs(output) do
				if device.type == 'dotmatrix' then
					return device.w, device.h
				end
			end
		end
	end
end

screen.w, screen.h = get_size()

--[[if not (screen.w and screen.h) then
	screen.w = 64
	screen.h = 64
end]]

camera = {
	x = 0,
}

function drawvline(x, y1, y2)
	draw.rect(x, y1, 1, y2 - y1 + 1)
	--[[
	local step = (y2 - y1) / 4
	local c = draw.getColor()
	local qqq = 0
	for yi = y1, y2, step do
		--draw.setColor(math.floor((yi + c) % 6) + 2)
		draw.setColor((qqq + c)%16)
		draw.rect(x, yi, 1, step)
		qqq = 1 - qqq
	end
	draw.setColor(c)
	--]]
	--draw.rect(x, y1, 1, 1)
	--draw.rect(x, y2, 1, 1)
end

function game:init()
	-- let's run thru some basic vector math to make sure everything is up to snuff
	local a, b, c, d
	a = vec2:new(4, 3)
	b = a:norm()
	c = -a
	print(a, a:mag(), a:magsqr(), a * 2)
	print(b, b:mag(), b:magsqr(), b * 2)
	print(a * b)
	print(c, c:mag())
end

function game:tick()
	draw.cls()
	--map:drawMini(32 - map.w / 2, 32 - map.h / 2)
	--map:drawMini(0, 0, 2)
	draw.setColor(0)
	draw.rect(0, 0, screen.w, screen.h / 2)
	draw.setColor(1)
	draw.rect(0, screen.h / 2, screen.w, screen.h / 2)
	for xi = 0, screen.w - 1 do
		-- calculate ray position and direction
		camera.x = 2 * xi / screen.w - 1 -- x-coordinate in camera space
		local ray = vec2:new(player.pos.x, player.pos.y)
		rayDir = vec2:new(
			player.dir.x + player.plane.x * camera.x,
			player.dir.y + player.plane.y * camera.x
		) -- note that it is camera.x in both components here

		-- which box of the map we're in
		tile = vec2:new(
			math.floor(player.pos.x),
			math.floor(player.pos.y)
		)

		-- length of ray from current position to next x or y-side
		local sideDistX
		local sideDistY

		-- length of ray from one x or y-side to next x or y-side
		local deltaDistX = math.abs(1 / rayDir.x)
		local deltaDistY = math.abs(1 / rayDir.y)

		-- what direction to step in x or y-direction (either +1 or -1)
		local stepX
		local stepY

		--calculate step and initial sideDist
		if rayDir.x < 0 then
			stepX = -1
			sideDistX = (player.pos.x - tile.x) * deltaDistX
		else
			stepX = 1
			sideDistX = (tile.x + 1.0 - player.pos.x) * deltaDistX
		end
		if rayDir.y < 0 then
			stepY = -1
			sideDistY = (player.pos.y - tile.y) * deltaDistY
		else
			stepY = 1
			sideDistY = (tile.y + 1.0 - player.pos.y) * deltaDistY
		end

		local hit = 0 -- was there a wall hit?
		local side -- was a NS or a EW wall hit?

		local debug_breakout = 1000
		-- perform DDA
		while hit == 0 and debug_breakout > 0 do
			debug_breakout = debug_breakout - 1
			-- jump to next map square, OR in x-direction, OR in y-direction
			if sideDistX < sideDistY then
				sideDistX = sideDistX + deltaDistX
				tile.x = tile.x + stepX
				side = 0
			else
				sideDistY = sideDistY + deltaDistY
				tile.y = tile.y + stepY
				side = 1
			end
			-- Check if ray has hit a wall
			if map[tile.y][tile.x] > 0 then hit = 1 end
		end

		-- Calculate distance projected on camera direction
		-- Euclidean distance would give fisheye effect
		local perpWallDist
		if side == 0 then
			perpWallDist = (tile.x - player.pos.x + (1 - stepX) / 2) / rayDir.x
		else
			perpWallDist = (tile.y - player.pos.y + (1 - stepY) / 2) / rayDir.y
		end

		-- Calculate height of line to draw on screen
		local lineHeight = math.floor(screen.h / perpWallDist)

		-- calculate lowest and highest pixel to fill in current stripe
		local drawStart = -lineHeight / 2 + screen.h / 2
		if drawStart < 0 then drawStart = 0 end
		local drawEnd = lineHeight / 2 + screen.h / 2
		if drawEnd >= screen.h then drawEnd = screen.h - 1 end

		--[[
		//choose wall color
		ColorRGB color;
		switch(worldMap[mapX][mapY])
		{
			case 1:  color = RGB_Red;  break; //red
			case 2:  color = RGB_Green;  break; //green
			case 3:  color = RGB_Blue;   break; //blue
			case 4:  color = RGB_White;  break; //white
			default: color = RGB_Yellow; break; //yellow
		}

		//give x and y sides different brightness
		if (side == 1) {color = color / 2;}
		]]

		local color = map[tile.y][tile.x] - 1
		draw.setColor(1) --(color + side * 8)
		--draw.setColor(math.random(0,15))

		--[[
		if side == 1 then
			draw.setColor(3)
		else
			draw.setColor(2)
		end
		--]]

		-- draw the pixels of the stripe as a vertical line
		--drawvline(xi, 0, 63)
		drawvline(xi, drawStart, drawEnd)
		--drawvline(xi, 0, drawStart)
		--draw.pix(xi, drawStart)
		--drawvline(xi, drawEnd, screen.h - 1)
		--draw.pix(xi, drawEnd)
	end
	if hw.btn('left') then
		player:turn(0.035)
	elseif hw.btn('right') then
		player:turn(-0.035)
	end
	local new_pos = player.pos
	if hw.btn('up') then
		new_pos = player.pos + player.dir * 0.05
	elseif hw.btn('down') then
		new_pos = player.pos + player.dir * -0.05
	end
	if map[math.floor(new_pos.y)][math.floor(new_pos.x)] == 0 then
		player.pos = new_pos
	end
end

function game:event(type, data)
	if type == 'button' and data.down then
		if data.button == 'left' then
		elseif data.button == 'right' then
		elseif data.button == 'up' then
		elseif data.button == 'down' then
		elseif data.button == '1' then
		elseif data.button == '2' then
		elseif data.button == '3' then
		end
	end
end

return game
