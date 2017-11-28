-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below

return {
	-- output contains all the output units
	-- types: lcd, led, vibrator?, beeper?
	-- lcd is the most complicated one, having its own subtypes
	output = {
		{
			-- the lcd unit contains other units specific to it. these units should not appear outside an lcd unit
			-- the lcd subunits are: dotmatrix, backlight, 
			type = 'lcd',
			x = -34,
			y = -50,
			w = 68,
			h = 68,
			{
				-- the dotmatrix unit is a rectangular array of pixels on an lcd. it is typically used for the main screen
				type = 'dotmatrix',
				x = -32,
				y = -48,
				w = 64,
				h = 64,
			},
		},
		{
			-- the led unit is a simple light that can be on or off
			type = 'led',
			x = -2,
			y = -58,
		},
	},
	input = {
		buttons = {
			['1'] = {
				x = -34,
				y = 22,
				w = 20,
				h = 8,
			},
			['2'] = {
				x = -10,
				y = 22,
				w = 20,
				h = 8,
			},
			['3'] = {
				x = 14,
				y = 22,
				w = 20,
				h = 8,
			},
			['back'] = {
				x = -36,
				y = 36,
				w = 10,
				h = 10,
			},
			['home'] = {
				x = 26,
				y = 36,
				w = 10,
				h = 10,
			},
			['left'] = {
				x = -14,
				y = 43,
				w = 8,
				h = 8,
			},
			['right'] = {
				x = 6,
				y = 43,
				w = 8,
				h = 8,
			},
			['up'] = {
				x = -4,
				y = 36,
				w = 8,
				h = 8,
			},
			['down'] = {
				x = -4,
				y = 50,
				w = 8,
				h = 8,
			},
		},
	},
}
