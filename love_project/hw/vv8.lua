-- testing for pixelimage support

-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

--local success, hw = loadscript('hw/vpet_base.lua')

--if not success then print('no hw') return nil end

local hw = dofile(hwdir..'vpet_base.lua')

hw.info = {
	name = 'VV8',
	version = {0, 0, 1},
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
	vram = {
	-- vram is basically a set of spritesheets called pages
	-- page 0 is always initialized to a blank canvas, and is writable. other pages are read-only (for now)
		w = 64,
		h = 64,
		font = basedir..'font.png',
		false,
		false,
		'pika/pika.png',
	},
	backlight = {
		color = {0x55, 0xaa, 0xff, 0x55},
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

for k,v in pairs(hw.input.buttons) do
	if tonumber(k) then -- this is hacky, but I like it
		v.image_up = basedir..'screen_button.png'
		v.image_down = basedir..'screen_button_pressed.png'
		--v.image_down = 'pika/pika.png'
	else
		v.image_up = basedir..k..'_button.png'
		v.image_down = basedir..k..'_button_pressed.png'
	end
end

return hw
