# VVpet

![VVpet logo icon](/love_project/icon.png)

![Animated image of VVpet running](/vPET64-demo.gif)

VVpet is a system for making and playing virtual LCD games. VVpet is not just one fantasy console, but more like a set of related fantasy consoles. It also allows one to easily make their own fantasy consoles, as well as games for those consoles.

## Getting Started
VVpet is made with Löve 0.10.2, so you will need that to run it. Once you have love, simply run love with the project folder as the game, for example: in a terminal, run `love love_project`; or, in a gui, drag the folder to the Löve executable.

## Interface
VVpet is an emulator for virtual pets that never existed. VVpet is not just one fantasy console, but rather a set of related fantasy consoles and tools to create your own. VVpet comes with the vPET series of virtual consoles, including flagship vPET64, the main console which the others are each a variation of.

The emulation interface has the following key bindings:

| Emulator Key | Function |
|-|-
| Minus - | Decrease size
| Equals = | Increase size

Consoles in the vPET series may have the following buttons, which are mapped to keys on the keyboard:

| vPET | Emulator Key |
|-|-
| Directional buttons | WASD / Arrow keys
| Screen buttons 1, 2, and 3 | 1 / Z, 2 / X, 3 / C
| Back Button | Backspace
| Home Button | Escape
| a | control, v, n
| b | shift, b

Note that some vPET consoles do not have action buttons 'a' and 'b'

## Files
Your application should have a unique name, and the location of the main script should be one of the following:

`$NAME.lua`

`$NAME/$NAME.lua`

`$NAME/app.lua`

Any pages must be in the same folder as the main script. In order for your app to show up in the app list, it shoudl be in the `apps/` folder.

## Callbacks

Instead of using global space, as is more typical of fantasy consoles, callbacks are implemented through a table, as methods of that table.

Each application's Lua script returns a table with the callback functions included as methods.

Below is a small sample program illustrating this. Note the `table:method` syntax, which implies the `self` variable/argument.

    local game = {}

    local bgcolor = 0

    function game:draw()
      draw.cls(bgcolor)
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

The following are the available callback functions: `draw()`, `update(dt)`, `event(type, data)`, `quit()`

`update()` is run every 1/60th of a second.

`draw()` is deprecated, but it runs every 1/60th of a second, right after `update()`

`event(type, data)` is called when an event happens. The event types are:

`'button'`

This event is triggered when a button is pressed or released. The data table has the keys is `button`, `up`, and `down`. `button` is one of the button strings: `'back'`, `'home'`, `'1'`, `'a'`, `'left'` etc. `'up` and `'down'` are booleans, giving whether the button is up or down. `'up'` is always the opposite of `'down'`.

`'quit'`

This event is triggered when the app stops running. The data structure is empty in the current version

These are also subject to change.

`quit()` is called when the app finishes running.

When an app exits, the following happens, in this order:

1. the `'quit'` event is called for `app:event()` if it exists
2. `app:quit()` is called, if it exists
3. the app actually exits

nothing happens between any of these steps

## API

Warning: This API is in early development, and is subject to change without warning.

Note: Currently, drawing from a source to itself is not supported.

---
`draw.setColor(color, bgcolor)`

Sets the drawing color, and the background color. If either is not given, it wont be set.

---
`draw.getColor()`

returns `color, bgcolor`

Returns the drawing color and the background color.

---
`draw.setDest(page, hw)`

Set the destination for drawing commands. The first argument is which page, the second is which hardware. Hardware choices are `'screen'` for the main LCD screen, `'app'` for pages loaded with `loadpage()`, or a number, for numbered LCD screens.

---
`draw.setSrc(page, hw)`

Set the source for drawing commands. The first argument is which page, the second is which hardware. Hardware choices are `'screen'` for the main LCD screen, `'app'` for pages loaded with `loadpage()`, or a number, for numbered LCD screen

---
`draw.cls(color)`

If `color` is given, clears the main screen to that color, if not, clears it to the background color.

---
`draw.rect(x, y, w, h)`

Fills a rectangle with a single color.

`x` and `y` default to `0`.

`w` and `h` default to the width and height of the screen, respectively.

---
`draw.pix(x, y)`

Colors a single pixel.

---
`draw.blit(srcx, srcy, w, h, destx, desty)`

copies a rectangle of pixels from one page to another.

TODO: explain this more

---
`draw.text(str, x, y, align, rect)`

Draws string `str` at co-ordinates `x, y`. `align` is a number representing alignment, 1 for right-aligned (default), 0 for centered, -1 for left-aligned. If rect is true, a rectangle will be drawn behind the text, using the background color. If rect is false, no rectangle will be drawn. If rect is a color, that color will be used for the rectangle.

---
`draw.line(x0, y0, x1, y1)`
Draws a line from point `x0, y0` to point `x1, y1`.

---
`os.subapp(appname, cansub)`

Runs another app, suspending the running app. `appname` is the name of the app, not the file, so if your app is `'game.lua'` or `'game/app.lua'` then `appname` would be `'game'`.

---
`os.quit()`

Exits the app, returning to the calling app, if there is one. See above for what happens when an app exits.

---
The following commands will be depecated when the hw API is more mature:

---
`hw.btn(button)`

Returns a boolean representing whether the given button is held, or nil if the button does not exist.

---
`vpet.led(on)`

If `on` is given, turns the LED on for true and off for false. Either way, returns whether the LED is on.

---
`vpet.loadpage(file, page, lcd)`

Loads an image `file` into page number `page` for drawing onto `lcd`.



## Future work

Virtual hardware specification files are included, and the comments in those files provide enough documentation to make your own hardware. However, this is not documented in this README as it is subject to change. The hardware loading function is full of assumptions and errors waiting to happen. Modify hardware with caution.

![Pixel art VVpet wordart](/logo.png)
