-- title:  Micro-Platformer Starter Kit
-- author: Matt Hughson (@mhughson)
-- desc:   Platforming engine in ~100 lines of code.
-- script: lua

--the goal of this cart is to
--demonstrate a very basic
--platforming engine in under
--100 lines of *code*, while
--still maintaining an organized
--and documented game.
--
--it isn't meant to be a demo of
--doing as much as possible, in
--as little code as possible.
--the 100 line limit is just
--meant to encourage people
--that "hey, you can make a game'
--with very little coding!"
--
--this will hopefully give new
--users a simple and easy to
--understand starting point for
--their own platforming games.
--
--note: collision routine is
--based on mario bros 2 and
--mckids, where we use collision
--points rather than a box.
--this has some interesting bugs
--but if it was good enough for
--miyamoto, its good enough for
--me!

-- Ported to VVpet by Gardrek
local game = {}

function lerp(a, b, t) return (1 - t) * a + t * b end

-- Map functions
local map = {}

map.data = {}

map.next = {}

map.x = 0 --16
map.y = 0 --16
map.w = 64
map.h = 64

-- Map tiles
local TILE = {
	AIR = 0,
	FLOOR = 1,
	WATER = 16,
}

-- Water constants and functions
local Water = {
	objList = {},
	minDepth = 1,
	maxDepth = 8,
}

map.defaultTile = TILE.FLOOR

function map:set(x, y, tile)
	self.data[math.floor(y % 256) * 256 + math.floor(x % 256)] = tile % 256
end

function map:get(x, y)
	local i = math.floor(y % 256) * 256 + math.floor(x % 256)
	if not self.data[i] then
		self.data[i] = map.defaultTile
	end
	return self.data[i]
	--return self.data[math.floor(y % 256) * 256 + math.floor(x % 256)] or self.defaultTile
end

function map:isSolid(x, y)
	--TODO: allow other solid blocks
	local tile
	if y then
		tile = self:get(x, y)
	else
		tile = x
	end
	return tile == TILE.FLOOR
end

function map:waterGrounded(x, y)
	-- Tells if tile has water or a solid block under it
	local tile = self:get(x, y + 1)
	return self:isSolid(tile) or Water:depth(tile)
end

for yi = 0, map.h - 1 do
	for xi = 0, map.w - 1 do
		if xi == 0 or yi == 0 or xi == 31 or yi == 15 then
			--map:set(xi, yi, TILE.FLOOR)
		else
			map:set(xi, yi, TILE.AIR)
		end
	end
end

function Water:depth(tile)
	-- This function returns the depth of a water tile, or false if a tile is not a water tile
	local d = tile >= TILE.WATER and
		tile <= TILE.WATER + Water.maxDepth - Water.minDepth and
		tile - TILE.WATER + 1 -- This is the depth equation
	return d
end

function Water:update()
	local tile, tile_up, tile_down, tile_left, tile_right
	local sourcex, sourcey, sourcedepth
	local loop, depth
	-- loop thru all waterfalls
	-- TODO: a first pass where waterfalls on the same side of the same block are  combined?
	for index, obj in ipairs(Water.objList) do
		-- loop thru all the tiles the water falls thru
		-- this way the loop length doesn't change when we add length. if we didn't store it, it would fall instantly
		if obj.rhand == 0 then
			sourcex, sourcey = obj.x - 1, obj.y
		else
			sourcex, sourcey = obj.x + 1, obj.y
		end
		loop = obj.h + 1
		for i = 1, loop do
			tile = map:get(obj.x, obj.y + i - 1) -- tile of lowest portion
			tile_down = map:get(obj.x, obj.y + i) -- tile below lowest portion
			depth = Water:depth(tile_down) -- returns whether tile is water, and to what depth if so
			obj.h = i
			obj.drawh = (obj.h - 1) * 8
			if map:isSolid(tile) or Water:depth(tile) == Water.maxDepth then
				obj.drawh = -1
				break
			end
			if map:isSolid(tile_down) or depth == Water.maxDepth then
				depth = Water:depth(tile)
				depth = depth or 0
				sourcedepth = Water:depth(map:get(sourcex, sourcey))
				if sourcedepth then
					if sourcedepth > 1 then
						map:set(sourcex, sourcey, TILE.WATER + sourcedepth - 2)
					else
						map:set(sourcex, sourcey, TILE.AIR)
					end
					map:set(obj.x, obj.y + i - 1, depth + TILE.WATER)
					obj.drawh = (obj.h - 1) * 8 - depth - 1
				else
					obj.dead = true
				end
				break
			end
		end
	end
	local i = 1
	while i <= #Water.objList do
		if Water.objList[i].dead then
			table.remove(Water.objList, i)
		else
			i = i + 1
		end
	end
	--[==[
	local depth_up, depth_down, depth_left, depth_right
	local fill_left, fill_right, fill_divided, fill_self
	-- loop through the map to uppdate water tiles
	for yi = map.h - 1, 0, -1 do
		for xi = 0, map.w - 1 do
			tile = map:get(xi, yi)
			depth = Water:depth(tile)
			fill_left = false
			fill_right = false
			fill_divisor = 0
			if depth then
				tile_up, tile_down, tile_left, tile_right =
					map:get(xi, yi + 1),
					map:get(xi, yi - 1),
					map:get(xi - 1, yi),
					map:get(xi + 1, yi)
				depth_up, depth_down, depth_left, depth_right =
					Water:depth(tile_up)
					Water:depth(tile_down)
					Water:depth(tile_left)
					Water:depth(tile_right)
				if map:isSolid(tile_down) or depth_down == Water.maxDepth then
					if depth_left and depth_left < Water.maxDepth or not map:isSolid(tile_left) then
						if map:waterGrounded(xi - 1, yi) then fill_left = true end
					end
					if depth_right and depth_right < Water.maxDepth or not map:isSolid(tile_right) then
						if map:waterGrounded(xi + 1, yi) then fill_right = true end
					end
					fill_self = depth
					---[[
					if fill_right and not fill_left then
						fill_divided = math.floor(depth / 2)
						fill_self = fill_self - fill_divided
						fill_right = fill_divided
					elseif not fill_right and fill_left then
						fill_divided = math.floor(depth / 2)
						fill_self = fill_self - fill_divided
						fill_left = fill_divided
					elseif fill_right and fill_left then
						fill_divided = math.floor(depth / 3)
						fill_self = fill_self - fill_divided * 2
						fill_right = fill_divided
						fill_left = fill_divided
					end
					if fill_self > 0 then
						map:set(xi, yi, TILE.WATER + fill_self - Water.minDepth)
					else
						map:set(xi, yi, TILE.AIR)
					end
					if fill_right and fill_right > 0 then map:set(xi + 1, yi, TILE.WATER + fill_right - Water.minDepth) end
					if fill_left and fill_left > 0 then map:set(xi - 1, yi, TILE.WATER + fill_left - Water.minDepth) end
					--]]
				end
			end
		end
	end
	--]==]
end

function Water:draw()
	draw.setColor('Blue')
	local drawx, drawy
	for index, obj in pairs(Water.objList) do
		drawx = map.x + obj.x * 8 + obj.rhand * 7
		drawy = map.y + obj.y * 8 + 7
		--draw.line(drawx, drawy, drawx, drawy + obj.h - 1)
		if obj.drawh >= 0 then
			draw.line(drawx, drawy, drawx, drawy + obj.drawh)
		end
	end
end

function map:update()
	local tile, tile_down, tile_left, tile_right, tile_up
	for yi = map.h - 1, 0, -1 do
		for xi = 0, map.w - 1 do
			tile = map:get(xi, yi)
			if tile >= TILE.WATER and tile <= TILE.WATER + Water.maxDepth - Water.minDepth then
				local depth = tile - TILE.WATER + Water.minDepth
			end
		end
	end
end

function map:draw(x, y)
	x = x or self.x or 0
	y = y or self.y or 0
	local tile, tx, ty
	for yi = 0, map.h - 1 do
		for xi = 0, map.w - 1 do
			tile = map:get(xi, yi)
			tx = x + xi * 8
			ty = y + yi * 8
			if tile == TILE.FLOOR then
				draw.setColor('Green')
				draw.rect(x + xi * 8, y + yi * 8, 8, 8)
			elseif tile >= TILE.WATER and tile <= TILE.WATER + Water.maxDepth - Water.minDepth then
				local depth = tile - TILE.WATER + Water.minDepth
				draw.setColor('Blue')
				draw.rect(x + xi * 8, y + yi * 8 + 8 - depth, 8, depth)
			elseif tile ~= TILE.AIR then
				draw.setColor('White')
				draw.text(tile, tx, ty)
			end
		end
	end
end

-- Make a level with ~*~MATH~*~!
do
	local tile = TILE.FLOOR
	for i = 0, 4 do
		map:set(i, 6, tile)
		map:set(i + 4, 3, tile)
		map:set(i + 4, 9, tile)
		map:set(i + 7, 12, tile)
		map:set(4, i + 8, tile)
		map:set(i + 15, 14 - i, tile)
		map:set((4 - i) + 20, 14 - i, tile)
	end
	map:set(23, 14, TILE.WATER + math.floor(Water.maxDepth / 2) - Water.minDepth)
	map:set(19, 14, TILE.WATER + math.floor(Water.maxDepth / 2) - Water.minDepth)
	-- Water for the water falls~
	map:set(31, 1, TILE.WATER)
	map:set(0, 1, TILE.WATER)
	map:set(1, 4, tile)
end


-- Insert the two waterfalls into the level
table.insert(Water.objList, {
	x = 30,
	y = 1,
	rhand = 1,
	h = 0,
	drawh = -1,
})

table.insert(Water.objList, {
	x = 1,
	y = 1,
	rhand = 0,
	h = 0,
	drawh = -1,
})

-- flag table used to store which tiles
-- are solid
local ftable = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
}

-- checks if a specific tile is solid.
-- todo: do bitfield check not ==
function fget(tile,flag)
	return (ftable[tile] and (ftable[tile]==flag))
end

--player
p1 = {
	--position
	x = 16,
	y = 16,
	--velocity
	dx = 0,
	dy = 0,

	--is the player standing on
	--the ground. used to determine
	--if they can jump.
	isgrounded=false,

	--tuning constants

	jumpvel=2.4,
}

--globals
g = {
	grav = 0.1, -- gravity per frame
}

local frametime = 0

-- called 30 times per second
function game:update(dt)
	--remember where we started
	local startx = p1.x

	--jump
	--

	--if on the ground and the
	--user presses 2 or up...
	-- FIXME: change this to be when pressed down, not while held
	if (hw.btn('up') or hw.btn('2')) and p1.isgrounded then
		--launch the player upwards
		p1.dy = -p1.jumpvel
	end

	--walk
	--

	p1.dx = 0
	if hw.btn('left') then --left
		p1.dx = -1
	end
	if hw.btn('right') then --right
		p1.dx = 1
	end

	--move the player left/right
	p1.x = p1.x + p1.dx * dt * 60

	--hit side walls
	--

	--check for walls in the
	--direction we are moving.
	local xoffset = 0
	if p1.dx > 0 then xoffset = 7 end

	--look for a wall
	local h = map:get((p1.x + xoffset) / 8, (p1.y + 7) / 8)
	if fget(h, 0) then
		--they hit a wall so move them
		--back to their original pos.
		--it should really move them to
		--the edge of the wall but this
		--mostly works and is simpler.
		p1.x = startx
	end

	--accumulate gravity
	--p1.dy = p1.dy + g.grav

	--fall
	--p1.y = p1.y + p1.dy * dt * 60

	-- Verlet integration simplified for constant acceleration
	-- dy = velocity, grav = acceleration
	p1.y = p1.y + p1.dy * dt * 60 + 0.5 * g.grav * dt * 60 * dt * 60
	p1.dy = p1.dy + g.grav * dt * 60

	--hit floor
	--

	--check bottom center of the
	--player.
	local v = map:get((p1.x + 4) / 8, (p1.y + 8) / 8)

	--assume they are floating
	--until we determine otherwise
	p1.isgrounded = false

	--only check for floors when
	--moving downward
	if p1.dy >= 0 then
		--look for a solid tile
		if fget(v, 0) then
			--place p1 on top of tile
			p1.y = math.floor((p1.y) / 8) * 8
			--halt velocity
			p1.dy = 0
			--allow jumping again
			p1.isgrounded = true
		end
	end

	--hit ceiling
	--

	--check top center of p1
	v = map:get((p1.x + 4) / 8, (p1.y) / 8)

	--only check for ceilings when
	--moving up
	if p1.dy <= 0 then
		--look for solid tile
		if fget(v, 0) then
			--position p1 right below
			--ceiling
			p1.y = math.floor((p1.y + 8) / 8) * 8
			--halt upward velocity
			p1.dy = 0
		end
	end

	if frametime > 0.4 then
		map:update()
		--Water:update()
		frametime = frametime % 0.4
	end

	-- infinite water sources
	map:set(31, 1, TILE.WATER)
	map:set(0, 1, TILE.WATER)

	map.x = lerp(map.x, 28 - (p1.x + p1.dx * 16), dt * 4)
	map.y = lerp(map.y, 28 - (p1.y + p1.dy * 16), dt * 8)

	frametime = frametime + dt
end

function game:draw()
	draw.cls('Black') --clear the screen
	map:draw() --draw map
	Water:draw()
	draw.setColor('Yellow')
	draw.rect(p1.x + map.x, p1.y + map.y, 8, 8) --draw player
end

return game
