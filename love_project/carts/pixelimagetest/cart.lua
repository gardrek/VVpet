local game = {}

local n = 0
local bgcolor = 0
local h = 64
local w = 64

function game:draw()
	vpet.cls(bgcolor)
	--vpet.rect(0, 16, false, false, bgcolor)
	n = n + 1
	local offset
	for yi = 0, h - 1 do
		offset = -math.floor(math.sin((n - yi * 4)/17) * 4)
		vpet.blit(0, yi, w, 1, offset, yi)
	end
	--blit(32, 0, 8, 8, 0, 0, 1)
	--pix(math.floor(n / 16) % 10, 0, 1)
	---[[
	for iii, vvv in ipairs{'left', 'up', 'down', 'right', 'back', 'home', '1', '2', '3'} do
		if vpet.btn[vvv] then
			vpet.pix(iii, 0)
		else
			vpet.pix(iii, 0, 0)
		end
	end
	--]]
end

function game:event(type, data)
	if type == 'button' and data.button == '2' then
		if data.down then
			bgcolor = 1
			led(false)
		else
			bgcolor = 0
			led(true)
		end
	end
end

return game
