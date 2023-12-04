hs.loadSpoon('DarkMode')
hs.loadSpoon('SpeedMenu')
hs.loadSpoon('WindowHighlight')
hs.loadSpoon('WindowResize')

hs.hotkey.bind({'ctrl', 'cmd'}, 'R', function()
	hs.reload()
end)
hs.alert.show('Hammerspoon Reloaded')
