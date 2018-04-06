
local hw = inherithw(hwdir .. 'vpet_base.lua')

local api = inherithw(hwdir .. 'base.lua')

hw.info = {
	name = 'VV8',
	version = {0, 0, 1},
}

local basedir = 'vpet/'
local buttondir = basedir .. 'buttons/'

local lcd = api.newDotMatrixLCD(0, -16, 64, 64, 2)

lcd.vram.font = 'font.png'

lcd.backlight = {
	color = {0x55, 0xaa, 0xff, 0x55},
}

-- VV8 color
lcd.bgcolor = {0xff, 0xff, 0xee}

lcd.colors = {}

for r = 0, 1 do
	for g = 0, 1 do
		for b = 0, 1 do
			for i = 0, 1 do
				lcd.colors[15 - (i * 8 + r * 4 + g * 2 + b)] = {
					0x11 + r * 0x77 + g * 0x44 + b * 0x44 + i * 0x22,
					0x11 + r * 0x33 + g * 0x55 + b * 0x33 + i * 0x22,
					0x11 + r * 0x22 + g * 0x11 + b * 0x77 + i * 0x22,
				}
			end
		end
	end
end

for index, color in pairs(lcd.colors) do
	for channel, value in pairs(color) do
		if value > 0xff then
			color[channel] = 0xff
			--print(index, channel, value)
		end
	end
end

--[[
lcd.colornames = {
	White = 0,
	Yellow = 1,
	Pink = 2, Magenta = 2,
	Red = 3,
	Grey = 4, Gray = 4,
	Green = 5,
	Blue = 6,
	Black = 7,
}
--]]

table.insert(lcd, {
	type = 'dotmatrix',
	x = 0,
	y = 0,
	w = 64,
	h = 64,
	page = 0,
	pagex = 0,
	pagey = 0,
	scale = 1,
})

table.insert(hw.output, lcd)

api.vpetInsertButtonImages(hw, buttondir, {labels = false})

return hw
