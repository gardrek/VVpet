local game = {}

local n = 0
local bgcolor = 0

function game:draw()
	cls(bgcolor)
	n = n + 1
	for yi = 0, 15 do
		for xi = 0, 15 do
			-- Drawsprite gives two x, y pairs, the first is the sprite to draw, the second is the location on screen to draw it.
			-- tiles are 4x4
			drawsprite(xi, yi, xi*4 - math.floor(math.sin((n - yi * 4)/17) * 4), yi * 4)
			--drawsprite(xi,yi,xi*4,yi*4)
		end
	end
end

function game:input(button, released)
	if button == 2 then
		if released then
			bgcolor = 0
		else
			bgcolor = 1
		end
	end
end

return game
