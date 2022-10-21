-- https://github.com/edwardbaeg/dotfiles/blob/master/hammerspoon/init.lua
local obj = {}

hs.window.highlight.ui.overlayColor = {0, 0, 0, 0.01} -- overlay color
hs.window.highlight.ui.overlay = false
hs.window.highlight.ui.frameWidth = 3 -- draw a frame around the focused window in overlay mode; 0 to disable
hs.window.highlight.ui.frameColor = {1, 0, 0, 0.8}
hs.window.highlight.start()

hs.window.filter.default:subscribe(hs.window.filter.windowFullscreened, function(window, appName)
    hs.window.highlight.ui.overlay = false
end)
hs.window.filter.default:subscribe(hs.window.filter.windowUnfullscreened, function(window, appName)
    hs.window.highlight.ui.overlay = true
end)

hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function(window, appName)
    local win = hs.window.focusedWindow()
    local isFullScreen = win:isFullScreen()

    if isFullScreen and hs.window.highlight.ui.overlay then
        hs.window.highlight.ui.overlay = false
    elseif not isFullscreen and not hs.window.highlight.ui.overlay then
        hs.window.highlight.ui.overlay = true
    end
end)

return obj
