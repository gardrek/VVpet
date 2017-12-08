# vPET-64

## Quick Start
Right now the easiest way to run your program is to open up the zip/löve file and put your program files in the /rom folder. This will make your program run on boot. Your main lua should be 'cart.lua' and you can have a sprite file called 'sprites.png'

## Interface
The main vPET has the following buttons, which are mapped to keys on the keyboard:

| vPET | Emulator Key |
|-|-
| Directional buttons | WASD / Arrow keys
| Screen buttons 1, 2, and 3 | 1 / Z, 2 / X, 3 / C
| Back Button | Tab / Backspace
| Home Button | R / Escape

## Files
Currently, the files read for loading an application are:

`cart.lua` — NOTE: this has been renamed to `app.lua` for the post-jam version

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

The following are the available callback functions:

`draw()`

`update(dt)`

`event(type, data)`
This is called when an event happens. Currently, the only event type is `'button'` and it's data structure is `{button , up , down}`
`button` is one of the button strings: `'back'`, `'home'`, `'1'`, `'2'`, `'3'`, `'left'`, `'right'`, `'up'`, and `'down'`. `'up` and `'down'` are booleans, giving whether the button is up or down. `'up'` is always the opposite of `'down'`.

These are also subject to change. One thing is, to combine update and draw into one, if possible.

## API

Warning: This API is in early development, and is subject to change 
without warning. One change that will likely come is packaging it into 
a table, but that will be after some major reform.

Besides the functions below, there is also a read-only `btn` table, giving a boolean for whether each button is pressed.

---
`blit(api.blit(srcx, srcy, w, h, destx, desty, src, dest, lcd)`

copies a rectangle of pixels from one page to another (or the same)

TODO: explain this more

---
`rect(x, y, w, h, color, dest, lcd)`

fills a rectangle with a single color

---

The following functions are deprecated.

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


## Future work

Support for non-square "pixels," which are not in a strict grid is forthcoming. Thus, allowing to create other LCD games, seven-segment displays, etc.
