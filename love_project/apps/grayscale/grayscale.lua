local game = {}

--draw.setColor(1, 0)

game.frametime = 0

game.frames = 0

function game:update(dt)
	self.frames = self.frames + 1
end

function game:draw()
	draw.cls()
	for i = 0, 2 do
		draw.pix(30 + i, 29)
		if self.frames % 2 == 0 then
			draw.pix(30 + i, 30)
		end
		draw.pix(30 + i, 31)
		draw.pix(29, 30 + i)
		draw.pix(33, 30 + i)
		draw.pix(30 + i, 33)
	end
	--[[
	if self.frames % 2 == 0 then
		draw.line(40, 40, 50, 50)
		for i = 1, 5 do
			--if self.frametime < 1 / (60 * i) then
				draw.rect(i * 10 - 5, 10, 8, 8)
			--end
		end
	end
	--]]
end

return game
