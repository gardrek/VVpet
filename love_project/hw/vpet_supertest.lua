-- testing for pixelimage support

-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

--local success, hw = loadscript('hw/vpet_base.lua')

--if not success then print('no hw') return nil end

hw = dofile(hwdir..'vpet_base.lua')

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
		basedir..'vram.png',
		false, false, false, false,
	},
	-- Sub-units
	{
		type = 'backlight',
		color = {0x55, 0xaa, 0xff, 0x55},
	},
}

for i = -1, 1, 2 do
	table.insert(hw.output, {
		-- the led unit is a simple light that can be on or off
		type = 'led',
		x = i * 16,
		y = -56,
		w = 4,
		h = 4,
		image_on = basedir..'led_on.png',
		image_off = basedir..'led_off.png',
	})
end

for i = 0, 3 do
	table.insert(lcd, {
		-- the dotmatrix unit is a rectangular array of pixels on an lcd.
		-- NOTE: the co-ordinates here are relative to the CENTER of the LCD screen
		type = 'dotmatrix',
		x = i * 16 - 24,
		y = -5 * i,
		w = 15,
		h = 64 - 10 * i,
		page = 0,
		pagex = 16 * i,
		pagey = 0,
	})
end

table.insert(hw.output, lcd)

return hw
