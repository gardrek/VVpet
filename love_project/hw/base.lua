-- This is not a full hardware, but rather some useful tools to use as a basais for construction of similar hardwware

local api = {}

function api.newDotMatrixLCD(x, y, w, h, border)
	return {
		type = 'lcd',
		x = x,
		y = y,
		w = w + border,
		h = h + border,
		bgcolor = {0xee, 0xee, 0xee},
		colors = {
			[0] = {0xdd, 0xdd, 0xdd},
			[1] = {0x11, 0x11, 0x11},
		},
		ghosting = 0x77,
		vram = {
			w = w,
			h = h,
		},
		{
			type = 'dotmatrix',
			x = 0,
			y = 0,
			w = w,
			h = h,
			page = 0,
			pagex = 0,
			pagey = 0,
		},
	}
end

function api.vpetInsertButtonImages(hw, buttondir, flags)
	flags = flags or {}
	for k, v in pairs(hw.input.buttons) do
		if tonumber(k) and not flags.labels then
			v.image_up = buttondir .. 'screen_button.png'
			v.image_down = buttondir .. 'screen_button_pressed.png'
		elseif (k == 'a' or k == 'b') and not flags.labels then
			v.image_up = buttondir .. 'action_button.png'
			v.image_down = buttondir .. 'action_button_pressed.png'
		else
			v.image_up = buttondir .. k .. '_button.png'
			v.image_down = buttondir .. k .. '_button_pressed.png'
		end
	end
end

return api
