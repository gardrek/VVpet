-- testing for pixelimage support

-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

--local success, hw = loadscript('hw/vpet_base.lua')

--if not success then print('no hw') return nil end

local basedir = 'vpet64/'

local spacedir = 'space/'

local hw = {
	-- available categories include: info, base, output, input
	base = {
		-- base specifies the background image of the device, and the default dimensions of the device
		-- minw and minh are the minimum height and width around the origin that must be shown
		image = spacedir .. 'base.png',
		x = -96,
		y = -96,
		h = 192,
		w = 192,
		minw = 152,
		minh = 148,
	},
	output = {
	-- output is an array of all the output units
	-- types: lcd, led, vibrator?, beeper?
	-- lcd is the most complicated one, having its own subtypes
	},
	-- input is a table optionally containing: buttons, pedometer?, gyro?, touchscreen?, something else?
	input = {
		buttons = {
		---[[
			['1'] = {
				x = -24,
				y = 80,
				w = 20,
				h = 8,
			},
			['2'] = {
				x = 0,
				y = 80,
				w = 20,
				h = 8,
			},
			['3'] = {
				x = 24,
				y = 80,
				w = 20,
				h = 8,
			},
			['back'] = {
				x = -48,
				y = 22,
				w = 12,
				h = 12,
			},
			['home'] = {
				x = 48,
				y = 22,
				w = 12,
				h = 12,
			},
			['left'] = {
				x = -68,
				y = 54,
				w = 8,
				h = 8,
			},
			['right'] = {
				x = -52,
				y = 54,
				w = 8,
				h = 8,
			},
			['up'] = {
				x = -60,
				y = 46,
				w = 8,
				h = 8,
			},
			['down'] = {
				x = -60,
				y = 62,
				w = 8,
				h = 8,
			},
			['a'] = {
				x = 68,
				y = 58,
				w = 14,
				h = 14,
			},
			['b'] = {
				x = 52,
				y = 50,
				w = 14,
				h = 14,
			},
		},
	},
}

hw.info = {
	name = 'SpaceGame',
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
	y = 6,
	w = 64 + 4,
	h = 128 + 4,
	bgcolor = {0x00, 0x11, 0x11},
	vram = {
	-- vram is basically a set of spritesheets called pages
	-- page 0 is always initialized to a blank canvas, and is writable. other pages are read-only (for now)
		w = 64,
		h = 128,
		font = basedir..'font.png',
	},
}

lcd.colors = {}

for r = 0, 1 do
	for g = 0, 1 do
		for b = 0, 1 do
			lcd.colors[(r * 4 + g * 2 + b)] = {
				0x11 + r * 0x77 + g * 0x66 + b * 0x44,
				0x11 + r * 0x33 + g * 0x77 + b * 0x33,
				0x11 + r * 0x22 + g * 0x33 + b * 0x77,
			}
		end
	end
end

lcd.colornames = {
	White = 7,
	Yellow = 6,
	Pink = 5, Magenta = 5,
	Red = 4,
	Grey = 3, Gray = 3,
	Green = 2,
	Blue = 1,
	Black = 0,
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
	h = 128,
	page = 0,
	pagex = 0,
	pagey = 0,
	scale = 1,
})

table.insert(hw.output, lcd)

--[[
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
--]]

return hw
