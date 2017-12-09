local game = {}

local n = 0
local bgcolor = 0
local offset = 0

function game:update(dt)
	n = n + dt * 90
end

function game:draw()
	draw.cls(bgcolor)
	for yi = 0, 15 do
		for xi = 0, 15 do
			offset = -math.floor(math.sin((n - yi * 4)/17) * 4)
			blit(xi * 4, yi * 4, 4, 4, xi * 4 + offset, yi * 4)
		end
	end
end

function game:event(type, data)
	if type == 'button' and data.button == '2' then
		if data.down then
			bgcolor = 1
			vpet.led(false)
		else
			bgcolor = 0
			vpet.led(true)
		end
	end
end

return game
