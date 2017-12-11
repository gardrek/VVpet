local game = {}

local colors = {
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

local bgc

function game:draw()
	bgc = vpet.btn['2'] and 1 or 0
	draw.setColor(nil, bgc)
	draw.cls()
	for i, v in ipairs(colors) do
		draw.setColor(bgc, v)
		draw.text(v, math.floor((i - 1) / 8) * 32 + 1, ((i - 1) % 8) * 8, nil, true)
	end
end

return game
