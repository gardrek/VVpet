-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

local hw = inherithw(hwdir..'vpet_base.lua')

hw.info = {
	name = 'vPET64',
	version = {0, 0, 1}, -- version number, analogous to 0.0.1
}

local basedir = 'vpet64/'

local lcd = {
	-- the lcd unit contains other units specific to it. these units should not appear outside an lcd unit
	-- the lcd subunits are: dotmatrix, backlight, pixelimage
	-- dotmatrix is a rectangular array of pixels which are all the same shape
	-- TODO: backlight lights up the display
	-- pixelimage is for non-square pixels like on seven-segment displays Game and Watch
	type = 'lcd',
	x = 0,
	y = -16,
	w = 68,
	h = 68,
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
		font = 'vpet64/font.png',
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
		y = 0,
		w = 64,
		h = 64,
		page = 0,
		pagex = 0,
		pagey = 0,
	},
}

table.insert(hw.output, lcd)

return hw
