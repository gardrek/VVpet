local game = {}

local cursor={
	index = 1,
	text = string.char(2) .. string.char(3),
}

local drawcursor = false

local cursor_blink = 0

-- game.applist is injected by the emulator because cheaty cheat cheat

local menu = {
	false, --'Info',
	'Run',
	false, --'BG   ',
}

function game:draw()
	draw.setColor('Black', 'White')
	draw.cls()
	if not self.applist or #self.applist == 0 then
		draw.text('no apps', 8, 0)
	else
		draw.text('App list', 1, 0)
		draw.rect(0, 8, 64, 1)
		for i, app in ipairs(self.applist) do
			drawcursor = true
			local color = drawcursor and i == cursor.index and 0 or 1
			draw.setColor(color, 1 - color)
			draw.text(app.name or app.file, 1, i * 8 + 2, nil, i == cursor.index)
		end
		draw.setColor(0, 1)
		for index, menuItem in ipairs(menu) do
			if type(menuItem) == 'string' then
				draw.text(menuItem:sub(1, 5), (index - 1) * 32 + 1, 57, 2 - index, true)
			end
		end
	end
end

function game:update(dt)
	cursor_blink = (cursor_blink + dt) % 1.0
	drawcursor = cursor_blink < 0.5
end

function game:event(type, data)
	---[[
	if type == 'button' and data.down then
		local button = data.button
		cursor_blink = 0
		if self.applist and #self.applist ~= 0 then
			if button == '2' then
				local ok, message = vpet.subapp(self.applist[cursor.index].name, false)
				if ok then
					message = 'Loading subapp '..self.applist[cursor.index].name
				end
				print(message)
			elseif button == '1' then
			elseif button == 'left' then
			elseif button == 'right' then
			elseif button == 'up' then
				cursor.index = (cursor.index - 2) % #self.applist + 1
			elseif button == 'down' then
				cursor.index = (cursor.index) % #self.applist + 1
			end
		end
	end
	--]]
end

return game
