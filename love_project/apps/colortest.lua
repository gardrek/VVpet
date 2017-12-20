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
	0,
	1,
	--[[
	2,
	3,
	4,
	5,
	--]]
}

local bgc

function game:draw()
	if vpet.btn('2') then
		if vpet.btn('3') then
			bgc = 'Black'
		else
			bgc = 'White'
		end
	elseif vpet.btn('3') then
		bgc = 1
	else
		bgc = 0
	end
	--bgc = vpet.btn('2') and 1 or 0
	draw.setColor(nil, bgc)
	draw.cls()
	for i, v in ipairs(colors) do
		--draw.setColor(bgc, v)
		if vpet.btn('1') then
			draw.setColor(bgc, v)
		else
			draw.setColor(v, bgc)
		end
		draw.text(v, math.floor((i - 1) / 8) * 32 + 1, ((i - 1) % 8) * 8, nil, true)
	end
end

return game
