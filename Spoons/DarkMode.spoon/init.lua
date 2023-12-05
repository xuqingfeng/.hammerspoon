local obj = {}

local logger = hs.logger.new("windows", "debug")

function isDarkMode()
    return hs.execute("defaults read -g AppleInterfaceStyle") == "Dark\n"
end

function setDarkDode()
    if isDarkMode() then
        hs.osascript.applescript([[
            tell application "System Events"
		        set dark mode of appearance preferences to false
	        end tell
        ]])
    else
        hs.osascript.applescript([[
            tell application "System Events"
		        set dark mode of appearance preferences to true
	        end tell
        ]])
    end
end

function obj:init()
    hs.hotkey.bind({'ctrl', 'cmd'}, 'D', setDarkDode)
end

return obj
