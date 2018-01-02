
local hw = inherithw(hwdir .. 'vpet_base.lua')

local api = inherithw(hwdir .. 'base.lua')



--hw.base.y = -128
--hw.base.h = 512

--hw.base.x = -1280
--hw.base.w = 2560

local basedir = 'vpet/'
local buttondir = basedir .. 'buttons/'

local lcd = api.newDotMatrixLCD(0, -16, 64, 64, 2)

lcd.scalex = 2

lcd.vram.font = 'font.png'

lcd.backlight = {
	color = {0x55, 0xaa, 0xff, 0x55},
}

-- VV8 color
lcd.bgcolor = {0x00, 0x00, 0x00}

lcd.colors = {
	[0] =
	{0x11, 0x11, 0x11},
	{0x11, 0xdd, 0xdd},
	{0xdd, 0xdd, 0x11},
	{0x99, 0x11, 0xdd},
	{0x11, 0xdd, 0x11},
	{0xdd, 0x11, 0x11},
	{0x11, 0x11, 0xdd},
	{0xdd, 0x99, 0x11},
}

--[:I, :O, :T, :S, :Z, :J, :L]
--[cyan, yellow, purple, green, red, blue, orange

---[[
lcd.colornames = {
	Black = 0,
	Cyan = 1,
	Yellow = 2,
	Purple = 3,
	Green = 4,
	Red = 5,
	Blue = 6,
	Orange = 7,
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
