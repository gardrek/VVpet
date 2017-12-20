
local basedir = 'vpet/'

local api = inherithw(hwdir .. 'base.lua')

local spacedir = 'space/'

local offset = -13

local hw = {
	base = {
		image = basedir .. 'shells/spaceblur.png',
		image_scale = 0.5,
		image_linear_filter = true,
		x = -256,
		y = -256,
		h = 512,
		w = 512,
		minw = 152,
		minh = 148,
	},
	input = {
		buttons = {
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
				y = 14,
				w = 12,
				h = 12,
			},
			['home'] = {
				x = 48,
				y = 14,
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

local lcd = api.newDotMatrixLCD(0, 6 + offset, 64, 128, 2)

lcd.bgcolor = {0x00, 0x11, 0x11}

lcd.vram.font = 'font.png'

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

hw.output = {
	lcd,
	{
		type = 'led',
		x = -40,
		y = 13,
		w = 4,
		h = 4,
		image_on = basedir .. 'led_on.png',
		image_off = basedir .. 'led_off.png',
	},
}

api.vpetInsertButtonImages(hw, basedir .. 'buttons/', {labels = true})

for k, v in pairs(hw.input.buttons) do
	v.y = v.y + offset
end

return hw
