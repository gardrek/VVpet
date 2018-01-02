local game = {}

local fallback_colors = {
	'Black',
	'Blue',
	'Green',
	'Cyan',
	'Red',
	'Magenta',
	'Yellow',
	'White',
	'Gray',
	'Grey',
	'Orange',
	'Pink',
}

local colors = {}

local info = hw.getInfo()

local lcd

for i, v in ipairs(info.output) do
	if v.type == 'lcd' and not lcd then lcd = v end
end

if lcd.colornames then
	for name, color_i in pairs(lcd.colornames) do
		colors[color_i + 1] = name
		for i, fallback_name in ipairs(fallback_colors) do
			if name == fallback_name then
				fallback_colors[i] = false
			end
		end
	end
else
	colors[1] = 'White'
	colors[2] = 'Black'
end

for i, name in pairs(fallback_colors) do
	if name then
		colors[#colors + 1] = name
	end
end

local bgc = 0

function game:draw()
	draw.setColor(nil, bgc)
	draw.cls()
	for i, v in ipairs(colors) do
		if vpet.btn('2') then
			draw.setColor(bgc, v)
		else
			draw.setColor(v, bgc)
		end
		draw.text(v, math.floor((i - 1) / 8) * 32 + 1, ((i - 1) % 8) * 8, nil, true)
	end
end

function game:event(type, data)
	if type == 'button' and data.down then
		local button = data.button
		if button == 'up' then
			bgc = (bgc - 1) % (lcd.colors)
		elseif button == 'down' then
			bgc = (bgc + 1) % (lcd.colors)
		end
	end
end

return game
