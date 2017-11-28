# vPET-64

## Files
Currently, the files read for loading an application are:
`cart.lua`
`sprites.png`
These must be in the same folder.

In future versions, other files to be loaded will be specified in the lua script.

TODO: Hardware Files

## Callbacks

Instead of using global space, as is more typical of fantasy consoles, callbacks are implemented through a table, as methods of that table.

	local game = {}

	`function game:draw()`
		cls(bgcolor)
		n = n + 1
		for yi = 0, 15 do
			for xi = 0, 15 do
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


## API

Warning: This API is in early development, and is subject to change without warning.

`drawsprite(sx, sy, x, y)`

`sx, sy` selects which 4x4 tile to draw

`x, y` is the screen co-ordinates at which to draw it

---
`cls(color)`

If `color` is given, clears the main screen to that color, if not, clears it to color 0.
