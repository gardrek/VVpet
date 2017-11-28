# vPET-64

## Files
Currently, the files read for loading an application are:
`cart.lua`
`sprites.png`
These must be in the same folder.

In future versions, other files to be loaded will be specified in the lua script.

TODO: Explain Hardware Files

## Callbacks

Instead of using global space, as is more typical of fantasy consoles, callbacks are implemented through a table, as methods of that table.

Each application's Lua script returns a table with the callback functions included as methods.

Below is a small sample program illustrating this. Note the `table:method` syntax, which implies the `self` variable/argument.

	local game = {}

	local bgcolor = 0

	function game:draw()
		cls(bgcolor)
	end

	function game:event(type, data)
		if type == 'button' and data.button == '2' then
			if data.down then
				bgcolor = 1
			else
				bgcolor = 0
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
