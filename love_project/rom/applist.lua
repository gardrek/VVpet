local game = {}

local cursor = {
	index = 1,
	text = string.char(2) .. string.char(3),
}

local drawcursor = false

local cursor_blink = 0

local scroll = 0


game.applist = vpet.listapps() -- is no longer injected by the emulator because that was bad mmkay

game.status = 'Select an app to run'
game.status_scroll = 64
game.status_scroll_speed = 4

if not game.applist  or #game.applist == 0 then
	game.status = 'No apps  found'
end

local menu = {
	false, --'Info',
	'Run',
	false, --'BG   ',
}

function lerp(a, b, t) return (1 - t) * a + t * b end

function game:draw()
	draw.setColor('Black', 'White')
	draw.cls()
	if self.applist and #self.applist ~= 0 then
		for i, app in ipairs(self.applist) do
			drawcursor = true
			local color = drawcursor and i == cursor.index and 'Gray' or 'Blue'
			draw.setColor(color, 'Blue')
			draw.text(app.name or app.file, 1, i * 8 + 24 - scroll, nil, i == cursor.index)
		end
	end
	draw.setColor('Gray')
	draw.rect(0, 0, nil, 8)
	draw.setColor('Blue')
	draw.text('App list', 1, 0)
	draw.rect(0, 8, nil, 1)
	draw.setColor('Gray')
	draw.rect(0, 49, nil, 16)
	draw.setColor('Blue')
	draw.rect(0, 49, nil, 1)
	draw.setColor('Red')
	if #self.status * 4 < 64 then
		draw.text(self.status, 1, 50)
		self.status_scroll = 64
	else
		draw.text(self.status, self.status_scroll, 50)
	end
	draw.setColor('White', 'Blue')
	for index, menuItem in ipairs(menu) do
		if type(menuItem) == 'string' then
			draw.text(menuItem:sub(1, 5), (index - 1) * 32 + 1, 57, 2 - index, true)
		end
	end
end

function game:update(dt)
	cursor_blink = (cursor_blink + dt) % 1.0
	drawcursor = cursor_blink < 0.5
	scroll = lerp(scroll, cursor.index * 8, dt * 8)
	if self.status_scroll > -#self.status * 4 then
		self.status_scroll = lerp(self.status_scroll, self.status_scroll - self.status_scroll_speed, dt * 8)
	else
		self.status_scroll = 64
	end
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
					message = 'Loaded subapp '..self.applist[cursor.index].name
				end
				game.status = message
				self.status_scroll = 64
				print(message)
				draw.cls()
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
