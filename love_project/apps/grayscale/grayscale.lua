local game = {}

--draw.setColor(1, 0)

game.frametime = 0

local ttt

function game:update(dt)
end

function game:draw()
	self.frametime = self.frametime + 0.016
	draw.cls()
	draw.line(30, 30, 40, 40)
	self.frametime = self.frametime % (1 / 60)
	for i = 1, 5 do
		if self.frametime < 1 / (60 * i) then
			draw.rect(i * 10 - 5, 10, 8, 8)
		end
	end
end

return {} --game
