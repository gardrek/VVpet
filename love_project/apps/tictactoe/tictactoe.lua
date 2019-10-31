local game = {}

vpet.loadpage('sprites.png')

local board, to_move

function reset()
	board = {
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		x = 14,
		y = 14,
	}
	to_move = 0
end

reset()

local cursor={
	x = 1,
	y = 1,
}

local drawcursor = false

local cursor_blink = 0

function game:draw()
	draw.setSrc(1, 'app')
	draw.cls(0)
	drawspriteblock(2 * to_move + 11, 0, 2, 2, board.x - 4, board.y - 12)
	drawspriteblock(9, 5, 2, 7, board.x + 8, board.y - 12)
	drawspriteblock(0, 0, 9, 9, board.x, board.y)
	drawspriteblock(0, 14, 2, 16, 0, 56)
	for yi = 0, 2 do
		for xi = 0, 2 do
			drawspriteblock(2 * board[yi + 1][xi + 1] + 9, 0, 2, 2, board.x + 12 * xi, board.y + 12 * yi)
		end
	end
	if drawcursor then drawspriteblock(9, 2, 3, 3, board.x + 12 * cursor.x, board.y + 12 * cursor.y) end
end

function game:update(dt)
	cursor_blink = (cursor_blink + dt) % 0.8
	drawcursor = cursor_blink < 0.4
end

function game:event(type, data)
	if type == 'button' and data.down then
		local button = data.button
		cursor_blink = 0
		if button == '2' then -- play
			if board[cursor.y + 1][cursor.x + 1]==0 then
				board[cursor.y + 1][cursor.x + 1] = to_move + 1
				to_move = 1 - to_move
			end
		elseif button == '1' then
			reset()
		elseif button == 'left' then
			cursor.x = (cursor.x - 1) % 3
		elseif button == 'right' then
			cursor.x = (cursor.x + 1) % 3
		elseif button == 'up' then
			cursor.y = (cursor.y - 1) % 3
		elseif button == 'down' then
			cursor.y = (cursor.y + 1) % 3
		end
	end
end

function drawspriteblock(sx, sy, w, h, x, y)
	local sprw, sprh = 4, 4
	for yi = 0, w - 1 do
		for xi = 0, h - 1 do
			drawsprite(sx + xi, sy + yi, x + xi * sprw, y + yi * sprh)
		end
	end
end

function drawsprite(sx,sy,x,y)
	draw.blit(sx*4, sy*4, 4, 4, x, y)
end

return game
