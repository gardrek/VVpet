-- testing for pixelimage support

-- hw description returns a table with at least the members output and input
-- the format of the table is detailed below
-- all x, y co-ordinates are measured with the origin at the CENTER of the device

local basedir = 'vpet64/'

local hw = {
	-- available categories include: info, base, output, input
	info = {
		name = 'vPET64 test',
		version = {0, 0, 1}, -- version number, analogous to 0.0.1
	},
	base = {
		-- base specifies the background image of the device, and the default dimensions of the device
		-- minw and minh are the minimum height and width around the origin that must be shown
		image = basedir..'base.png',
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
			-- the led unit is a simple light that can be on or off
			type = 'led',
			x = 0,
			y = -56,
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
		},
	},
}

for k,v in pairs(hw.input.buttons) do
	if tonumber(k) then -- this is hacky, but I like it
		v.image_up = basedir..'screen_button.png'
		v.image_down = basedir..'screen_button_pressed.png'
	else
		v.image_up = basedir..k..'_button.png'
		v.image_down = basedir..k..'_button_pressed.png'
	end
end

return hw
