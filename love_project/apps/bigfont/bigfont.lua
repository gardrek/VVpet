local game = {}

--Global alert!
bigfont = {
  w = 6, h = 12,
}

function game:init()
  draw.setSrc(vpet.loadpage('bigfont.png'), 'app')
  draw.setColor('White', 'Black')
end

x = 64
y = 64

function game:tick()
  draw.cls()
  bigfont:drawtext('Test, test, hello! )(*&^%$#@! @ME !NOT #hashtag $hollaholla', x, y, 0)
  if hw.btn('left') then x = x - 1 end
  if hw.btn('right') then x = x + 1 end
end

function bigfont:drawtext(str, x, y, align)
  str = tostring(str)
  x = x or 0
  y = y or 0
  align = align or 1
  local ch, srcx, srcy, xi, yi, width
  width = #str * self.w
  xi = ((align - 1) * width) / 2
  yi = 0
  for i = 1, #str do
    ch = str:byte(i) - 32
    srcx = (ch % 16) * self.w
    srcy = math.floor(ch / 16) * self.h
    draw.blit(srcx, srcy, self.w, self.h, x + (i - 1) * self.w + xi, y + yi)
  end
end

return game
