require("config")

hs.loadSpoon('Cherry')
hs.loadSpoon('CiscoAnyConnect')
hs.loadSpoon('DarkMode')
hs.loadSpoon('WindowResize')
-- put SpeedMenu the last one
hs.loadSpoon('SpeedMenu')

hs.hotkey.bind({'ctrl', 'cmd'}, 'R', function()
	hs.reload()
end)
hs.alert.show('Hammerspoon Reloaded')
