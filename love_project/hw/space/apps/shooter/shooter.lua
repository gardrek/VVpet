local game = {}

vpet.loadpage('page1.png')

local screen = {
	w = 64,
	h = 128,
}

local world = {
	type = 'space',
	x = 0, y = 0,
	basespeed = 30,
	bgcolor = 'Black',
}

world.speed = world.basespeed

local stars = {}

function stars:load(i)
	self[i].x = math.random(0, screen.w - 1)
	self[i].y = math.random(0, screen.h - 1) - screen.h
	self[i].z = math.random() * 3 + 2
end

function stars:update(dt)
	for i, star in ipairs(stars) do
		star.y = star.y + world.speed * dt / star.z
		if star.y > screen.h then
			stars:load(i)
		end
		star.drawx = star.x
		star.drawy = star.y
	end
end

for i = 1, 8 do
	stars[i] = {}
	stars:load(i)
	stars[i].y = stars[i].y + screen.h
end

stars:update(0)

local menu = {
	false,
	false,
	'Start',
}

function overlap(rect1, rect2)
	return rect1.x < rect2.x + rect2.w and
		rect1.x + rect1.w > rect2.x and
		rect1.y < rect2.y + rect2.h and
		rect1.h + rect1.y > rect2.y
end

function damage_collide(obj1, aabb1, obj2, aabb2)
	if overlap(aabb1, aabb2) then
		local damage = math.min(obj1.hp, obj2.hp)
		obj1.hp = obj1.hp - damage
		obj2.hp = obj2.hp - damage
	end
end

local player = {
	team = 'player',
	x = 32,
	y = 96,
	w = 9,
	h = 9,
	hp = 15,
	aabb = {x = 0, y = 0, w = 9, h = 9}, -- FIXME: make sure to update once so the x and y are right
	speed = 50,
	boost = 0,
	gun = {
		cooldown = 0,
		bullet = {
			imagerect = {
				x = 60, y = 0,
				w = 4, h = 8,
			},
				x = 0, y = 0,
				w = 3, h = 7,
			hp = 3,
		},
	},
	draw = function(self)
		self.drawx = math.floor(self.x)
		self.drawy = math.floor(self.y)
		local rand = (math.random(1, 100) < 30 and -1 or 0)
		if self.boost > 6 then
			draw.setColor('Pink')
			draw.line(self.drawx, self.drawy, self.drawx, screen.h)
			if rand == 0 then
					draw.blit(16, 12, 12, 8, self.drawx - 5, self.drawy + 3)
				else
					draw.blit(16, 20, 12, 8, self.drawx - 5, self.drawy + 3)
				--draw.line(self.drawx - 1, self.drawy, self.drawx - 1, screen.h)
				--draw.line(self.drawx + 1, self.drawy, self.drawx + 1, screen.h)
			end
		elseif self.boost > 0 then
			local y = -(6 - math.floor(self.boost)) + rand
			draw.blit(16, 0 - y, 3, 9 + y, self.drawx - 1, self.drawy + 3)
		end
		draw.blit(0, 0, 16, 16, self.drawx - 7, self.drawy - 8)
		--draw.setColor('Green')
		--draw.setColor('Pink')
		--draw.pix(self.drawx, self.drawy + 2)
		--draw.text(self.boost, 0, 0)
		--draw.rect(self.drawx - math.floor(self.w / 2), self.drawy - math.floor(self.h / 2), self.w, self.h)
		--draw.rect(self.aabb)
	end,
	update = function(self, dt)
		---[[ fractional co-ords
		local cx, cy = self.x - math.floor(self.w / 2), self.y - math.floor(self.h / 2)
		if cx < 0 then self.x = self.x - cx end
		if cy < 0 then self.y = self.y - cy end
		if cx + self.w > screen.w then self.x = self.x - (cx + self.w - screen.w) end
		if cy + self.h > screen.h then self.y = self.y - (cy + self.h - screen.h) end
		--]]
		self.drawx = math.floor(self.x)
		self.drawy = math.floor(self.y)
		-- floored co-ords
		self.aabb.x, self.aabb.y = self.drawx - math.floor(self.w / 2), self.drawy - math.floor(self.h / 2)
		if self.gun.cooldown > 0 then
			self.gun.cooldown = self.gun.cooldown - dt
		end
		self.hp = (self.hp + dt) % 33
	end,
}

local Mob = {}
Mob.__index = Mob

function Mob:new(template)
	local mob
	if template then
		mob = {}
		for k, v in pairs(template) do
			mob[k] = v
		end
	else
		mob = {
			x = 0, y = 0, w = 8, h = 8,
			hp = 1,
		}
	end
	setmetatable(mob, self)
	return mob
end

function Mob:update(dt)
	if self.dx then
		self.x = self.x + self.dx * dt
	end
	if self.dy then
		self.y = self.y + self.dy * dt
	end
	if self.hp and self.hp <= 0 then
		self.dead = true
	end
end

function Mob:draw()
	if self.imagerect then
		draw.blit(
			self.imagerect.x, self.imagerect.y,
			self.imagerect.w, self.imagerect.h, 
			self.x, self.y
		)
	end
end

local Bullet = {}
Bullet.list = {}

function Bullet:update(dt)
	Mob.update(self, dt)
	if self.y > 2 * screen.h or self.y + self.h <= -screen.h or
		self.x > 2 * screen.w or self.x + self.w <= -screen.w then
			self.dead = true
	end
end

function Bullet:add(template, mods)
	local mob = Mob:new(template)
	if mods then
		for k, v in pairs(mods) do
			mob[k] = v
		end
	end
	mob.update = self.update
	table.insert(self.list, mob)
end

local Enemy = {}
Enemy.list = {}

function Enemy:add(template, mods)
	local mob = Mob:new(template)
	if mods then
		for k, v in pairs(mods) do
			mob[k] = v
		end
	end
	mob.update = self.update
	table.insert(self.list, mob)
end

function Enemy:update(...)
	Bullet.update(self, ...)
end

--local Particle = 

function game:draw()
	draw.setColor('White', world.bgcolor)
	draw.cls()
	for i, star in ipairs(stars) do
		if world.type == 'space' then
			draw.pix(star.drawx, star.drawy)
		elseif world.type == 'hyperspace' then
			draw.line(star.drawx, star.drawy, star.drawx, star.drawy - (world.speed + world.basespeed) / world.basespeed)
		end
	end
	for i, v in ipairs(Bullet.list) do
		v:draw(dt)
	end
	for i, v in ipairs(Enemy.list) do
		v:draw(dt)
	end
	--draw.text((world.speed - world.basespeed) / world.basespeed)
	for i = 1, player.hp do
		local p = (i - 1) % 4
		if p < 2 then
			draw.blit(0, (p % 2) * 4 + 56, 4, 4, math.floor((i - 1) / 4) * 8, ((i - 1) % 2) * 4)
		else
			draw.blit(4, (1 - (p % 2)) * 4 + 56, 4, 4, math.floor((i - 1) / 4) * 8 + 4, (1 - (i - 1) % 2) * 4)
		end
	end
	draw.text(#Enemy.list, 0, 8)
	draw.line(0, world.y % screen.h, screen.w, world.y % screen.h)
	player:draw()
	draw.setColor('White')
	--[[
	for k, v in pairs(vpet.btn) do
		if v then draw.text(k, 0, 8) break end
		print(k, v)
	end
	draw.setColor('Blue', 'Grey')
	for index, menuItem in ipairs(menu) do
		if type(menuItem) == 'string' then
			draw.text(menuItem:sub(1, 5), (index - 1) * 32 + 1, screen.h - 7, 2 - index, true)
		end
	end
	--]]
end

function game:update(dt)
	local dx = dt * player.speed
	local dy = dt * player.speed * 0.8
	if vpet.btn['left'] then
		player.x = player.x - dx
	elseif vpet.btn['right'] then
		player.x = player.x + dx
	end
	if vpet.btn['up'] then
		player.y = player.y - dy
		if world.type == 'space' then
			player.boost = player.boost + 50 * dt
		elseif world.type == 'planet' and player.boost > 2 then
			player.boost = player.boost + 20 * dt
		end
	elseif vpet.btn['down'] then
		player.y = player.y + dy
		if world.type == 'space' then
			player.boost = 0
		elseif world.type == 'planet' and player.boost > 2 then
			player.boost = player.boost - 20 * dt
		end
	else
		if world.type == 'space' then
			player.boost = player.boost - 30 * dt
		elseif world.type == 'planet' then
			if player.boost > 4 then
				player.boost = player.boost - 10 * dt
			else
				player.boost = player.boost + 10 * dt
			end
		end
	end
	if vpet.btn['b'] then
		if player.gun.cooldown <= 0 then
			Bullet:add(player.gun.bullet, {
				x = player.x - player.gun.bullet.w / 2, y = player.y - player.gun.bullet.h / 2,
				dx = 0, dy = -70,
				team = 'player',
			})
			player.gun.cooldown = 0.2
		end
	end
	if world.type == 'hyperspace' then
		player.boost = 2 + (world.speed - world.basespeed) / world.basespeed
		world.speed = world.speed + dt * world.basespeed
		if world.speed > 6 * world.basespeed then world.speed = 6 * world.basespeed end
	else
		world.speed = world.basespeed
		if player.boost > 6 then player.boost = 6 end
		if player.boost < 0 then player.boost = 0 end
	end
	player:update(dt)
	local i, v
	i = 1
	while i <= #Bullet.list do
		v = Bullet.list[i]
		v:update(dt)
		if v.dead then
			table.remove(Bullet.list, i)
		else
			i = i + 1
		end
	end
	i = 1
	while i <= #Enemy.list do
		v = Enemy.list[i]
		v:update(dt)
		for bltindex, blt in ipairs(Bullet.list) do
			if v.team ~= blt.team then
				damage_collide(v, v, blt, blt)
			end
		end
		if v.dead then
			table.remove(Enemy.list, i)
		else
			i = i + 1
		end
	end
	stars:update(dt)
	world.y = world.y + world.speed * dt
	if math.random(3 / dt) <= 1 then
		Enemy:add({
			x = math.random(0, screen.w - 16), y = -16,
			w = 16, h = 16,
			imagerect = {
				x = 48, y = 8, w = 16, h = 16,
			},
			dx = 0, dy = 30,
			hp = 8,
			team = 'enemy',
		})
	end
end

function game:event(type, data)
	if type == 'button' and data.down then
		if data.button == '1' then
			world.type = 'space'
			world.bgcolor = 'Black'
			player.boost = 0
		elseif data.button == '2' then
			world.type = 'planet'
			world.bgcolor = 'Blue'
			player.boost = 4
		elseif data.button == '3' then
			world.type = 'hyperspace'
			world.bgcolor = 'Black'
		elseif data.button == 'b' then
		end
	end
end

return game
