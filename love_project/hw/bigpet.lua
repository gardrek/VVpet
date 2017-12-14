-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

local hw = inherithw(hwdir..'vpet_base.lua')

hw.info = {
	name = 'bigPET',
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
	w = 256 + 4,
	h = 128 + 4,
	bgcolor = {0xee, 0xee, 0xee},
	vram = {
	-- vram is basically a set of spritesheets called pages
	-- page 0 is always initialized to a blank canvas, and is writable. other pages are read-only (for now)
		w = 256,
		h = 128,
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
		w = 256,
		h = 128,
		page = 0,
		pagex = 0,
		pagey = 0,
	},
}

-- VV8 color
lcd.bgcolor = {0xff, 0xff, 0xee}

lcd.colors = {}

for r = 0, 1 do
	for g = 0, 1 do
		for b = 0, 1 do
			lcd.colors[7 - (r * 4 + g * 2 + b)] = {
				0x11 + r * 0x77 + g * 0x66 + b * 0x44,
				0x11 + r * 0x33 + g * 0x77 + b * 0x33,
				0x11 + r * 0x22 + g * 0x33 + b * 0x77,
			}
		end
	end
end

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

for index, color in pairs(lcd.colors) do
	for channel, value in pairs(color) do
		if value > 0xff then
			color[channel] = 0xff
			--print(index, channel, value)
		end
	end
end

table.insert(hw.output, lcd)

return hw
