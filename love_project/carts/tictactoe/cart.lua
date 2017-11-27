local game={}

local draw = {
	x = 14,
	y = 14,
}

local board = {
	{0, 0, 0},
	{0, 0, 0},
	{0, 0, 0},
}

local cursor={
	x = 1,
	y = 1,
}

local drawcursor = false

local cursor_blink = 0

local to_move = 0

local t = 0

function game:draw()
	cls(0)
	drawspriteblock(2 * to_move + 11, 0, 2, 2, draw.x - 4, draw.y - 12)
	drawspriteblock(9, 5, 2, 7, draw.x + 8, draw.y - 12)
	drawspriteblock(0, 0, 8, 8, draw.x, draw.y)
	drawspriteblock(0, 14, 2, 16, 0, 56)
	for yi = 0, 2 do
		for xi = 0, 2 do
			drawspriteblock(2 * board[yi + 1][xi + 1] + 9, 0, 2, 2, draw.x + 12 * xi, draw.y + 12 * yi)
		end
	end
	if drawcursor then drawspriteblock(9, 2, 3, 3, draw.x + 12 * cursor.x, draw.y + 12 * cursor.y) end
end

function game:update(dt)
	t=t+dt
	cursor_blink = (cursor_blink + dt) % 0.8
	drawcursor = cursor_blink < 0.4
end

function game:input(button, released)
	if not released then
		cursor_blink = 0
		if button == 2 then
			if board[cursor.y+1][cursor.x+1]==0 then
				board[cursor.y+1][cursor.x+1] = to_move + 1
				to_move = 1 - to_move
			end
		elseif button == 1 then
			board = {
				{0, 0, 0},
				{0, 0, 0},
				{0, 0, 0},
			}
			to_move = 0
		elseif button==4 then
			cursor.x = (cursor.x - 1) % 3
		elseif button==5 then
			cursor.x = (cursor.x + 1) % 3
		elseif button==6 then
			cursor.y = (cursor.y - 1) % 3
		elseif button==7 then
			cursor.y = (cursor.y + 1) % 3
		end
	end
end

function drawspriteblock(sx,sy,w,h,x,y)
	local sprw,sprh = 4,4
	for yi=0,w-1 do
		for xi=0,h-1 do
			drawsprite(sx+xi,sy+yi,x+xi*sprw,y+yi*sprh)
		end
	end
end

return game
