local game = {}

--[[
local hwinfo = hw.getInfo()

local lcd

for i, v in ipairs(hwinfo.output) do
	if v.type == 'lcd' then
		lcd = lcd or v
	end
end

local x, y = 10, 10

for yi = 0, 23 do
	for xi = 0, 23 do
		draw.setColor(math.random(0, lcd.colors - 1))
		draw.pix(xi, yi)
	end
end

draw.setColor(1)
--]]

vpet.loadpage('egg.png')
vpet.loadpage()

local t = 0
local d

local Egg = {}
Egg.__index = Egg

function Egg.new()
	local egg = {}
	setmetatable(egg, self)


	--egg:gen()

	return egg
end


local egg = Egg.new()

function egg:gen()
	self.seed = {}
	for i = 1, 8 do
		self.seed[i] = math.random(0, 0xff)
	end
	self:init()
end

function egg:init()
	self.stripe = {}
	self.spot = {}
	for i = 0, 3 do
		local has_stripe = bit.rshift(self.seed[1], i * 2) % 2 == 1
		if has_stripe then
			self.stripe[i] = bit.rshift(self.seed[1], i * 2 + 1) % 2
		else
			self.stripe[i] = false
			self.spot[i] = {
				pat = bit.rshift(self.seed[i + 1], 2) % 8,
				pos = self.seed[i + 1] % 4,
			}
		end
	end
end

egg:gen()

function egg:draw(x, y, squash)
	draw.blit(squash * 32, 32, 32, 32, x, y)
	local off = {x = 0, y = 0, stripe = 0}
	if squash == 1 then
		off.x = -1
	end
	for i = 0, 3 do
		if squash == 1 then
			off.y = 3 - i
		end
		if self.stripe[i] then
			off.stripe = self.stripe[i]
			if squash == 1 then
				draw.blit(12 + 32 * off.stripe, i * 6, 4, 6, x + 14, y + 4 + 6 * i + off.y)
			end
			draw.blit(0 + 32 * off.stripe, i * 6, 12, 6, x + 4 + off.x, y + 4 + 6 * i + off.y)
			draw.blit(16 + 32 * off.stripe, i * 6, 12, 6, x + 16 - off.x, y + 4 + 6 * i + off.y)
		else
			local spot = self.spot[i]
			if spot.pos == 1 or spot.pos == 2 then off.x = -off.x end
			draw.blit(spot.pat * 8, 24, 8, 8, x + off.x + math.floor((spot.pos % 3) * 3.5) + 9 --[[+ i % 2]], y + 6 * i + off.y + 4)
			if spot.pos == 1 or spot.pos == 2 then off.x = -off.x end
			if spot.pos == 3 then
				draw.blit(spot.pat * 8, 24, 8, 8, x - off.x + 16 --[[+ i % 2]], y + 6 * i + off.y + 4)
			end
		end
	end
end

function game:draw()
	draw.cls()
	d = t % 100 > 50 and 1 or 0
	--d = 0
	egg:draw(16, 16, d)
end

function game:update(dt)
	t = (t + 1) % 100
end

function game:event(type, data)
	if type == 'button' and data.down then
		local button = data.button
		if button == '2' then
			egg:gen()
		end
		--[[
		if button == 'left' then
			x = (x - 1) % 24
		elseif button == 'right' then
			x = (x + 1) % 24
		elseif button == 'up' then
			y = (y - 1) % 24
		elseif button == 'down' then
			y = (y + 1) % 24
		end
		--]]
	end
end

return game
