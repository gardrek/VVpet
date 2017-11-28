-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below

return {
	files = {
		base = 'base.png'
	},
	-- output contains all the output units
	-- types: lcd, led, vibrator?, beeper?
	-- lcd is the most complicated one, having its own subtypes
	output = {
		{
			-- the lcd unit contains other units specific to it. these units should not appear outside an lcd unit
			-- the lcd subunits are: dotmatrix, backlight, 
			type = 'lcd',
			x = 0,
			y = -16,
			w = 68,
			h = 68,
			{
				-- the dotmatrix unit is a rectangular array of pixels on an lcd. it is typically used for the main screen
				type = 'dotmatrix',
				x = 0,
				y = -16,
				w = 64,
				h = 64,
			},
		},
		{
			-- the led unit is a simple light that can be on or off
			type = 'led',
			x = 0,
			y = -56,
			w = 4,
			h = 4,
		},
	},
	input = {
		buttons = {
			['1'] = {
				x = -24,
				y = 18,
				w = 20,
				h = 8,
			},
			['2'] = {
				x = 0,
				y = 18,
				w = 20,
				h = 8,
			},
			['3'] = {
				x = 24,
				y = 18,
				w = 20,
				h = 8,
			},
			['back'] = {
				x = -32,
				y = 42,
				w = 10,
				h = 10,
			},
			['home'] = {
				x = 32,
				y = 42,
				w = 10,
				h = 10,
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
