-- testing for pixelimage support

-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

local hw = inherithw(hwdir..'vpet_base.lua')

hw.info = {
	name = 'vPET48',
	version = {0, 0, 1},
}

hw.base.defaultscale = 2

local lcd = {
	-- the lcd unit contains other units specific to it. these units should not appear outside an lcd unit
	-- the lcd subunits are: dotmatrix, backlight, pixelimage
	-- dotmatrix is a rectangular array of pixels which are all the same shape
	-- TODO: backlight lights up the display
	-- pixelimage is for non-square pixels like on seven-segment displays Game and Watch
	type = 'lcd',
	x = 0,
	y = -16,
	w = 64 + 4,
	h = 64 + 4,
	bgcolor = {0xee, 0xff, 0xee},
	colors = {
		[0] = {0xdd, 0xee, 0xcc}, -- white (paper)
		[1] = {0x11, 0x11, 0x22}, -- black (ink)
	},
	vram = {
	-- vram is basically a set of spritesheets called pages
	-- page 0 is always initialized to a blank canvas, and is writable. other pages are read-only (for now)
		w = 64,
		h = 64,
		font = 'font.png',
	},
	backlight = {
		color = {0x55, 0xaa, 0xff, 0x55},
	},
	-- Sub-units
	{
		-- the dotmatrix unit is a rectangular array of pixels on an lcd.
		-- NOTE: the co-ordinates here are relative to the CENTER of the LCD screen
		type = 'dotmatrix',
		x = 0,
		y = 8,
		w = 64,
		h = 64,
		page = 0,
		pagex = 0,
		pagey = 16,
		scale = 1,
	},
}

local pix = {
	type = 'pixelimage',
	x = 4,
	y = 2,
	atlas = 'test/pixelimage_atlas.png',
	quads = {},
}

pix.quads = {
	{x = 0, y = 4, w = 8, h = 8},
	{x = 8, y = 0, w = 8, h = 8},
	{x = 8, y = 8, w = 8, h = 8},
	{x = 16, y = 4, w = 8, h = 8},
	{x = 24, y = 8, w = 8, h = 8},
	{x = 32, y = 8, w = 8, h = 8},
}

for i = 0, 2 do
	table.insert(pix.quads, {x = 24 + i * 12, y = 0, w = 12, h = 8})
end

--[[
for i = 0, 31 do
	pix.quads[i+1] = {x = i * 8, y = 0, w = 8, h = 8}
end

local ox, oy = 0, 2

for yi = 0, 2 do
	for xi = 0, 4 do
		
	end
end
--]]

table.insert(lcd, pix)
table.insert(hw.output, lcd)

return hw
