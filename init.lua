hs.loadSpoon('SpeedMenu')
hs.loadSpoon('WindowResize')

hs.hotkey.bind({'ctrl', 'alt'}, 'R', function()
	hs.reload()
end)
hs.alert.show('Hammerspoon reloaded')