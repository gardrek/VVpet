# vPET-64

## Quick Start
Right now the easiest way to run your program is to open up the zip/löve file and put your program files in the /rom folder. This will make your program run on boot. Your main lua should be 'cart.lua' and you can have a sprite file called 'sprites.png'

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
      if type == 'button' and data.button == 'down' then
        if data.down then
          bgcolor = 1
        else
          bgcolor = 0
        end
      end
    end

    return game

The following are the available callback functions:
`draw()`, `update(dt)`, `event(type, data)`

These are also subject to change. One thing is, to combine update and draw into one, if possible.

## API

Warning: This API is in early development, and is subject to change without warning. One change that will likely come is packaging it into a table, but that will be after some major reform.

---
`blit(api.blit(srcx, srcy, w, h, destx, desty, src, dest, lcd)`

copies a rectangle of pixels from one page to another (or the same)

TODO: explain this more

---
The following functions are going to be replaced eventually, but still work as of now. Consider them deprecated.
---

`drawsprite(sx, sy, x, y)`

`sx, sy` selects which 4x4 tile to draw

`x, y` is the screen co-ordinates at which to draw it

---
`cls(color)`

If `color` is given, clears the main screen to that color, if not, clears it to color 0.

---
`led(on)`

If `on` is given, turns the LED on for true and off for false. Either way, returns whether the LED is on.
