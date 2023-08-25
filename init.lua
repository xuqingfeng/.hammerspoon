hs.loadSpoon('SpeedMenu')
hs.loadSpoon('WindowResize')
hs.loadSpoon('WindowHighlight')
hs.loadSpoon('DarkMode')

hs.hotkey.bind({'ctrl', 'cmd'}, 'R', function()
	hs.reload()
end)
hs.alert.show('Hammerspoon reloaded')
