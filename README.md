# VVpet

![Animated image of VVpet running](https://i.imgur.com/vhCwHG2.gif)

## Interface
VVpet is an emulator for virtual pets that never existed. VVpet is not precisely a fantasy console, but rather a set of related fantasy consoles and tools to create your own. The vPET series of virtual consoles includes flagship vPET64, the main console which the others are each a variation of.

Consoles in the vPET series have the following buttons, which are mapped to keys on the keyboard:

| vPET | Emulator Key |
|-|-
| Directional buttons | WASD / Arrow keys
| Screen buttons 1, 2, and 3 | 1 / Z, 2 / X, 3 / C
| Back Button | Backspace
| Home Button | Escape

The following additional buttons are also mapped:

| vPET | Emulator Key |
|-|-
| a | control, v, n
| b | shift, b

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
      vpet.cls(bgcolor)
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

The following are the available callback functions: `draw()`, `update(dt)`, `event(type, data)`

This is called when an event happens. Currently, the only event type is `'button'` and it's data structure is `{button , up , down}`
`button` is one of the button strings: `'back'`, `'home'`, `'1'`, `'2'`, `'3'`, `'left'`, `'right'`, `'up'`, and `'down'`. `'up` and `'down'` are booleans, giving whether the button is up or down. `'up'` is always the opposite of `'down'`.

These are also subject to change.

## API

Warning: This API is in early development, and is subject to change 
without warning. One change that will likely come is packaging it into 
a table, but that will be after some major reform.

Besides the functions below, there is also a read-only `btn` table, giving a boolean for whether each button is pressed.

---
`vpet.loadpage(file, page, lcd)`

Loads an image `file` into page number `page` for drawing onto `lcd`.

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

`x` and `y`  default to `0`.

`w` and `h`  default to the width and height of the screen, respectively.

---
`draw.pix(x, y)`

Colors a single pixel.

---
`draw.blit(api.blit(srcx, srcy, w, h, destx, desty)`

copies a rectangle of pixels from one page to another (or the same)

TODO: explain this more

---
`draw.text(str, x, y, align, rect)`

Draws string `str` at co-ordinates `x, y`. `align` is a number representing alignment, 1 for right-aligned (default), 0 for centered, -1 for left-aligned. If rect is true, a rectangle will be drawn behind the text, using the background color. If rect is false, no rectangle will be drawn. If rect is a color, that color will be used for the rectangle.

---
`vpet.led(on)`

If `on` is given, turns the LED on for true and off for false. Either way, returns whether the LED is on.

---
`vpet.subapp(appname, cansub)`

Runs another app, suspending the running app. `appname` is the name of the app, not the file, so if your app is `'game.lua'` or `'game/app.lua'` then `appname` would be `'game'`.

---
`vpet.quit()`

Exits the app, returning to the calling app, if there is one.


## Future work

Virtual hardware specification files are included, and the comments in those files provide enough documentation to make your own hardware. However, this is not documented in this README as it is subject to change. The hardware loading function is full of assumptions and errors waiting to happen. Modify hardware with caution.
