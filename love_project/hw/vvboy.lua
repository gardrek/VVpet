-- testing for pixelimage support

-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

--local success, hw = loadscript('hw/vpet_base.lua')

--if not success then print('no hw') return nil end

local basedir = 'vpet64/'

local vvboydir = 'vvboy/'

local main_screen = {
	w = 160,
	h = 144,
}

local hw = {
	-- available categories include: info, base, output, input
	base = {
		-- base specifies the background image of the device, and the default dimensions of the device
		-- minw and minh are the minimum height and width around the origin that must be shown
		image = vvboydir .. 'base.png',
		x = -64,
		y = -32,
		h = 256,
		w = 256,
		minw = 152,
		minh = 148,
	},
	output = {
	-- output is an array of all the output units
	-- types: lcd, led, vibrator?, beeper?
	-- lcd is the most complicated one, having its own subtypes
		{
			-- the led unit is a simple light that can be on or off
			type = 'led',
			x = -44,
			y = 26 + 32,
			w = 4,
			h = 4,
			image_on = basedir..'led_on.png',
			image_off = basedir..'led_off.png',
		},
	},
	-- input is a table optionally containing: buttons, pedometer?, gyro?, touchscreen?, something else?
	input = {

		buttons = {
			['1'] = {
				x = -24,
				y = 26,
				w = 20,
				h = 8,
			},
			['2'] = {
				x = 0,
				y = 26,
				w = 20,
				h = 8,
			},
			['3'] = {
				x = 24,
				y = 26,
				w = 20,
				h = 8,
			},
			['back'] = {
				x = -32,
				y = 42,
				w = 12,
				h = 12,
			},
			['home'] = {
				x = 32,
				y = 42,
				w = 12,
				h = 12,
			},
			['left'] = {
				x = -10,
				y = 47,
				w = 8,
				h = 8,
			},
			['right'] = {
				x = 10,
				y = 47,
				w = 8,
				h = 8,
			},
			['up'] = {
				x = 0,
				y = 40,
				w = 8,
				h = 8,
			},
			['down'] = {
				x = 0,
				y = 54,
				w = 8,
				h = 8,
			},
			--[[
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
			--]]
		},
	},
}

hw.info = {
	name = 'VVboy',
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
	y = -32,
	w = main_screen.w + 8,
	h = main_screen.h + 8,
	bgcolor = {0xee, 0xff, 0xcc}, --#ddffaa
	vram = {
	-- vram is basically a set of spritesheets called pages
	-- page 0 is always initialized to a blank canvas, and is writable. other pages are read-only (for now)
		w = main_screen.w,
		h = main_screen.h,
		font = basedir..'font.png',
	},
}

lcd.ghosting = 0x88

lcd.colors = {}

for g = 0, 1 do
	for b = 0, 1 do
		lcd.colors[3 - (g * 2 + b)] = {
			0x11 + g * 0x88 + b * 0x55,
			0x11 + g * 0xaa + b * 0x44,
			0x22 + g * 0x33 + b * 0x66,
		}
	end
end

lcd.colornames = {
	White = 0, Yellow = 0,
	Light = 1, Green = 1, Grey = 1, Gray = 1,
	Dark = 2, Blue = 2,
	Black = 3,
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
	w = main_screen.w,
	h = main_screen.h,
	page = 0,
	pagex = 0,
	pagey = 0,
	scale = 1,
})

table.insert(hw.output, lcd)

for k,v in pairs(hw.input.buttons) do
	v.y = v.y + 32
	if tonumber(k) then -- this is hacky, but I like it
		v.image_up = basedir..'screen_button.png'
		v.image_down = basedir..'screen_button_pressed.png'
	else
		v.image_up = basedir..k..'_button.png'
		v.image_down = basedir..k..'_button_pressed.png'
	end
end

return hw
