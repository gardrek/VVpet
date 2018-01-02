local game = {}

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

function game:draw()
	draw.setColor(nil, bgc)
	--draw.cls()
	draw.pix(x, y)
end

function game:event(type, data)
	if type == 'button' and data.down then
		local button = data.button
		if button == 'left' then
			x = (x - 1) % 24
		elseif button == 'right' then
			x = (x + 1) % 24
		elseif button == 'up' then
			y = (y - 1) % 24
		elseif button == 'down' then
			y = (y + 1) % 24
		end
	end
end

return game
