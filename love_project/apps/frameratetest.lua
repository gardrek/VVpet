local game = {}

tick0 = 0
tick1 = 0

sec1 = 0
sec2 = 0
sec3 = os.time()

function game:update(dt)
  tick0 = tick0 + dt * 60
  tick1 = tick1 + 1
end

local tick708 = false

function game:draw()
  draw.cls(0)
  draw.text(tick0, 1, 0)
  draw.text(tick1, 1, 7)
  draw.text(tick1 - tick0, 1, 14)
  draw.text(tick0 / 60, 1, 21)
  draw.text(tick1 / 60, 1, 28)
  draw.text(os.difftime(os.time(), sec3), 1, 35)
  --[[
  if tick1 % 3 == 0 then
    draw.rect(60 - 12, 60, 4, 4)
  end
  if tick1 % 2 == 0 then
    draw.rect(60 - 8, 60, 4, 4)
  end
  if tick1 % 3 ~= 0 then
    draw.rect(60 - 4, 60, 4, 4)
  end
  --]]
  --if tick1 % 2 == 0 then
    --draw.rect(60 - 4, 60, 4, 4)
  --end
  if tick708 then
    draw.rect(60 - 4, 60, 4, 4)
  end
  tick708 = not tick708
  draw.rect(60, 60, 4, 4)
end

return game

