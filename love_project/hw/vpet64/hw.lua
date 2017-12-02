-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

local hw = {
	-- available categories include: info, base, output, input
	info = {
		name = 'vPET64',
		version = {0, 0, 1}, -- version number, analogous to 0.0.1
	},
	base = {
		-- base specifies the background image of the device, and the default dimensions of the device
		-- minw and minh are the minimum height and width around the origin that must be shown
		image = 'base.png',
		x = -64,
		y = -64,
		h = 128,
		w = 128,
		minw = 80,
		minh = 120,
	},
	output = {
	-- output is an array of all the output units
	-- types: lcd, led, vibrator?, beeper?
	-- lcd is the most complicated one, having its own subtypes
		{
			-- the lcd unit contains other units specific to it. these units should not appear outside an lcd unit
			-- the lcd subunits are: dotmatrix, backlight, (something else that handles shapes instead of just a dot-matrix)
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
			vrom = {
			-- vrom is basically a set of spritesheets called pages
			-- page 0 is always initialized to a blank canvas, and is writable. other pages are read-only (for now)
				w = 64,
				h = 64,
				'vrom.png',
			},
			{
				-- the dotmatrix unit is a rectangular array of pixels on an lcd.
				-- NOTE: the co-ordinates here are relative to the CENTER of the LCD screen
				type = 'dotmatrix',
				x = 0,
				y = 0,
				w = 64,
				h = 64,
				page = 0,
			},
			{
				type = 'backlight',
				color = {0x55, 0xaa, 0xff, 0x55},
			},
		},
		{
			-- the led unit is a simple light that can be on or off
			type = 'led',
			x = 0,
			y = -56,
			w = 4,
			h = 4,
			image_on = 'led_on.png',
			image_off = 'led_off.png',
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
		},
	},
}

for k,v in pairs(hw.input.buttons) do
	if tonumber(k) then
		v.image_up = 'screen_button.png'
		v.image_down = 'screen_button_pressed.png'
	else
		v.image_up = k..'_button.png'
		v.image_down = k..'_button_pressed.png'
	end
end

return hw
