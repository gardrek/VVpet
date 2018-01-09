return {
	inputmap = {
		-- system buttons - these buttons are handled differently when an app is run from inside another app
		-- TODO: implement apps calling other apps
		back = {'backspace'}, -- use to return to a previous screen or cancel something.
		home = {'escape'}, -- TODO: Use to return to the app which started the app you'e in
		reset = {'f10'}, -- TODO: reset pinhole, clears all user data
		-- screen buttons - numbered left to right
		['1'] = {'1', 'z'},
		['2'] = {'2', 'x'},
		['3'] = {'3', 'c'},
		-- action buttons - NOTE: some vPET consoles do not have action buttons
		a = {'lctrl', 'rctrl', 'v', 'n'},
		b = {'lshift', 'rshift', 'b'},
		-- direction buttons:
		left = {'a', 'left'},
		right = {'d', 'right'},
		up = {'w', 'up'},
		down = {'s', 'down'},
	},
}
