local game = {}

local textcolor = 'Black'
local rectcolor = 'Green'
local align = 1
local x, y = 32, 32
local speed = 120
local s = 'This is a test of the text output system.'

for i = 0, 15 do
	s = s .. string.char(i)
end
s = s .. string.char(0)
s = s .. string.char(3)

s = s .. string.char(2)
s = s .. string.char(1)

s = s .. string.char(4)
s = s .. string.char(7)

s = s .. string.char(6)
s = s .. string.char(5)

local num

for i = 0, 15 do
	num = math.random(1, 7)
	if num == 1 then
		s = s .. string.char(15)
	elseif num == 2 then
		s = s .. string.char(12) .. string.char(14)
	else
		s = s .. string.char(12)
		for i = 1, num - 2 do
			s = s .. string.char(13)
		end
		s = s .. string.char(14)
	end
end

local menu = {
	'Hey',
	'Hi',
	'Hello',
}

function game:update(dt)
	if vpet.btn('up') then y = y - dt * speed end
	if vpet.btn('down') then y = y + dt * speed end
	if vpet.btn('left') then x = x - dt * speed end
	if vpet.btn('right') then x = x + dt * speed end
end

function game:draw()
	draw.setColor(nil, 'White')
	draw.cls()
	draw.blit(4, 4, 20, 20, 10, 10)
	draw.setColor(rectcolor)
	draw.rect(30, 4, 20, 20, 10, 10)
	draw.setColor('Green', 'Yellow')
	draw.text(s, x, y, align, false)
	draw.setColor('Red')
	draw.text('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPAASDFGHJKLZXCVBNM	1234567890 !@#$%^&*()_+-=`~[]\\;\',./{}|<>?:"', x, y + 8, align, 'Blue')
	local al = 1
	for off, st in ipairs(menu) do
		draw.setColor('Black', 'White')
		draw.text(st, (off - 1) * 32 + 1, 57, al, true)
		al = al - 1
	end
end

function game:event(type, data)
	if type == 'button' and data.down then
		if data.button == '1' then
			align = -1
		elseif data.button == '2' then
			align = 0
		elseif data.button == '3' then
			align = 1
		--[[
		elseif data.button == 'up' then
			y = y - 1
		elseif data.button == 'down' then
			y = y + 1
		elseif data.button == 'left' then
			x = x - 1
		elseif data.button == 'right' then
			x = x + 1
		--]]
		end
	end
end

return game
