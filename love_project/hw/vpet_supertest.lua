-- testing for pixelimage support

-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

--local success, hw = loadscript('hw/vpet_base.lua')

--if not success then print('no hw') return nil end

hw = dofile(hwdir..'vpet_base.lua')

hw.info = {
	name = 'SUPERtest',
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
	--[[ Pikachu Palette
	colors = {
		[0] =
		{0xdd, 0xee, 0xcc},
		{0x11, 0x11, 0x22},
		{0xee, 0xcc, 0x22},
		{0xcc, 0x33, 0x00},
	},
	--]]
	--[[ MATRIAX8C
	colors = {
		[0] =
		{0xf0, 0xf0, 0xdc},
		{0xfa, 0xc8, 0x00},
		{0x10, 0xc8, 0x40},
		{0x00, 0xa0, 0xc8},
		{0xd2, 0x40, 0x40},
		{0xa0, 0x69, 0x4b},
		{0x73, 0x64, 0x64},
		{0x10, 0x18, 0x20},
	},
	--]]
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

---[[ VV8 color
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

--[[
for i = 0, #lcd.colors do
	print('index', i, 'rgb:', unpack(lcd.colors[i]))
end
--]]

for index, color in pairs(lcd.colors) do
	for channel, value in pairs(color) do
		if value > 0xff then
			color[channel] = 0xff
			--print(index, channel, value)
		end
	end
end
--]]

--[[
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

for i = 0, 0 do
	table.insert(lcd, {
		-- the dotmatrix unit is a rectangular array of pixels on an lcd.
		-- NOTE: the co-ordinates here are relative to the CENTER of the LCD screen
		type = 'dotmatrix',
		x = 0,
		y = i*32 - 24,
		w = 32,
		h = 16,
		page = 0,
		pagex = 16 * i,
		pagey = 0,
		scale = 2,
	})
end
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
