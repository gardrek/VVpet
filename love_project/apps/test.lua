return {
  x = 32, y = 32, r = 10,
  tick = function(self)
    draw.cls()
    local r, xi
    for i = -2, 2 do
      r = self.r + i
      --draw.circle(self.x + self.r * i * 2 + 1, self.y, r)
    end
    --draw.circle(self.x, self.y, self.r)
    if hw.btn('2') then
      draw.pix(self.x, self.y)
    end
  end,
  event = function(self, type, data)
    qbert[1] = 1 -- o noes error
    if type == 'button' and data.down then
      if data.button == 'left' then
        self.x = self.x - 1
      elseif data.button == 'right' then
        self.x = self.x + 1
      elseif data.button == 'up' then
        self.y = self.y - 1
      elseif data.button == 'down' then
        self.y = self.y + 1
      elseif data.button == '1' then
        self.r = self.r - 1
      elseif data.button == '3' then
        self.r = self.r + 1
      end
    end
  end,
}
