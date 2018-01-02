
local hw = inherithw(hwdir .. 'vpet_base.lua')

local api = inherithw(hwdir .. 'base.lua')

hw.info = {
	name = 'Quadlu',
	version = {0, 0, 1},
}

hw.base.defaultscale = 2

local basedir = 'vpet/'
local buttondir = basedir .. 'buttons/'

local lcd = {
	type = 'lcd',
	x = 0,
	y = -16,
	w = 128 + 8,
	h = 128 + 8,
	bgcolor = {0xff, 0xff, 0xff},
	--bgcolor = {0x22, 0x11, 0x33},
	colors = {
		[0] = {0xdd, 0xdd, 0xdd},
		[1] = {0x11, 0x11, 0x11},
	},
	ghosting = 0x77,
	vram = {
		w = 24,
		h = 24,
	},

	scale = 1,

	-- Well
	{
		type = 'dotmatrix',
		x = -39,
		y = 4,
		w = 10,
		h = 24,
		page = 0,
		pagex = 0,
		pagey = 0,
		scale = 5,
	},

	-- Next pieces
	{
		type = 'dotmatrix',
		x = 0,
		y = -24,
		w = 4,
		h = 2,
		page = 0,
		pagex = 10,
		pagey = 0,
		scale = 2,
	},
	{
		type = 'dotmatrix',
		x = 0,
		y = -20,
		w = 4,
		h = 2,
		page = 0,
		pagex = 10,
		pagey = 2,
		scale = 3,
	},
	{
		type = 'dotmatrix',
		x = 0,
		y = -16,
		w = 4,
		h = 2,
		page = 0,
		pagex = 10,
		pagey = 4,
		scale = 4,
	},

	-- Held piece
	{
		type = 'dotmatrix',
		x = 20,
		y = 0,
		w = 4,
		h = 2,
		page = 0,
		pagex = 10,
		pagey = 6,
	},
}

lcd.scale = 1

lcd.vram.font = 'font.png'

lcd.colors = {
	[0] =
	{0xee, 0xee, 0xee},
	{0x11, 0x99, 0xdd},
	{0xdd, 0xdd, 0x33},
	{0x99, 0x33, 0x99},
	{0x33, 0x99, 0x11},
	{0xdd, 0x33, 0x33},
	{0x33, 0x11, 0x99},
	{0xdd, 0x99, 0x33},
}

--[[{
	[0] =
	{0x11, 0x11, 0x11},
	{0x11, 0xdd, 0xdd},
	{0xdd, 0xdd, 0x11},
	{0x99, 0x11, 0xdd},
	{0x11, 0xdd, 0x11},
	{0xdd, 0x11, 0x11},
	{0x11, 0x11, 0xdd},
	{0xdd, 0x99, 0x11},
}]]

--[:I, :O, :T, :S, :Z, :J, :L]
--[cyan, yellow, purple, green, red, blue, orange

---[[
lcd.colornames = {
	White = 0,--Black = 0,
	Cyan = 1,
	Yellow = 2,
	Purple = 3,
	Green = 4,
	Red = 5,
	Blue = 6,
	Orange = 7,
}
--]]

table.insert(hw.output, lcd)

api.vpetInsertButtonImages(hw, buttondir, {labels = false})

return hw
