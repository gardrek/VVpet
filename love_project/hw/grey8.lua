
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

local r
for k = 0, 7 do
	r = (7 - k) * 0x22 + 0x11
	lcd.colors[k] = {r, r, r}
end

lcd.colornames = {
	White = 0,
	Black = 7,
}

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
