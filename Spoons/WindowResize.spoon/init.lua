-- Window management
local obj = {}

-- Defines for window maximize toggler
local frameCache = {}
local logger = hs.logger.new("windows")

-- Resize current window

function winresize(how)
    local win = hs.window.focusedWindow()
    local app = win:application():name()
    local windowLayout
    local newrect

    if how == "left" then
        newrect = hs.layout.left50
    elseif how == "right" then
        newrect = hs.layout.right50
    elseif how == "up" then
        newrect = {0, 0, 1, 0.5}
    elseif how == "down" then
        newrect = {0, 0.5, 1, 0.5}
    elseif how == "max" then
        newrect = hs.layout.maximized
    elseif how == "left_third" or how == "hthird-0" then
        newrect = {0, 0, 1 / 3, 1}
    elseif how == "middle_third_h" or how == "hthird-1" then
        newrect = {1 / 3, 0, 1 / 3, 1}
    elseif how == "right_third" or how == "hthird-2" then
        newrect = {2 / 3, 0, 1 / 3, 1}
    elseif how == "top_third" or how == "vthird-0" then
        newrect = {0, 0, 1, 1 / 3}
    elseif how == "middle_third_v" or how == "vthird-1" then
        newrect = {0, 1 / 3, 1, 1 / 3}
    elseif how == "bottom_third" or how == "vthird-2" then
        newrect = {0, 2 / 3, 1, 1 / 3}
    end

    win:move(newrect)
end

function win_move_screen_between_monitors(how)
    local win = hs.window.focusedWindow()
    if how == "left" then
        win:moveOneScreenWest()
    elseif how == "right" then
        win:moveOneScreenEast()
    end
end

-- Resize screen by quarter - https://medium.com/@jhkuperus/window-management-with-hammerspoon-personal-productivity-c77adc436888
local GRID_SIZE = 4
local HALF_GRID_SIZE = GRID_SIZE / 2
local screenPositions = {}
screenPositions.topLeft = {
    x = 0,
    y = 0,
    w = HALF_GRID_SIZE,
    h = HALF_GRID_SIZE
}
screenPositions.topRight = {
    x = HALF_GRID_SIZE,
    y = 0,
    w = HALF_GRID_SIZE,
    h = HALF_GRID_SIZE
}
screenPositions.bottomLeft = {
    x = 0,
    y = HALF_GRID_SIZE,
    w = HALF_GRID_SIZE,
    h = HALF_GRID_SIZE
}
screenPositions.bottomRight = {
    x = HALF_GRID_SIZE,
    y = HALF_GRID_SIZE,
    w = HALF_GRID_SIZE,
    h = HALF_GRID_SIZE
}
hs.grid.setGrid(GRID_SIZE .. 'x' .. GRID_SIZE)
hs.grid.setMargins({0, 0})
hs.window.animationDuration = 0
function win_resize_2(how)
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    if how == "top-left" then
        hs.grid.set(win, screenPositions.topLeft, screen)
    elseif how == "top-right" then
        hs.grid.set(win, screenPositions.topRight, screen)
    elseif how == "bottom-left" then
        hs.grid.set(win, screenPositions.bottomLeft, screen)
    elseif how == "bottom-right" then
        hs.grid.set(win, screenPositions.bottomRight, screen)
    end
end

-- Toggle a window between its normal size, and being maximized
function toggle_window_maximized()
    local win = hs.window.focusedWindow()
    if frameCache[win:id()] then
        win:setFrame(frameCache[win:id()])
        frameCache[win:id()] = nil
    else
        frameCache[win:id()] = win:frame()
        win:maximize()
    end
end

-- Move between thirds of the screen
function get_horizontal_third(win)
    local frame = win:frame()
    local screenframe = win:screen():frame()
    local relframe = hs.geometry(frame.x - screenframe.x, frame.y - screenframe.y, frame.w, frame.h)
    local third = math.floor(3.01 * relframe.x / screenframe.w)
    logger.df("Screen frame: %s", screenframe)
    logger.df("Window frame: %s, relframe %s is in horizontal third #%d", frame, relframe, third)
    return third
end

function get_vertical_third(win)
    local frame = win:frame()
    local screenframe = win:screen():frame()
    local relframe = hs.geometry(frame.x - screenframe.x, frame.y - screenframe.y, frame.w, frame.h)
    local third = math.floor(3.01 * relframe.y / screenframe.h)
    logger.df("Screen frame: %s", screenframe)
    logger.df("Window frame: %s, relframe %s is in vertical third #%d", frame, relframe, third)
    return third
end

function left_third()
    local win = hs.window.focusedWindow()
    local third = get_horizontal_third(win)
    if third == 0 then
        winresize("hthird-0")
    else
        winresize("hthird-" .. (third - 1))
    end
end

function right_third()
    local win = hs.window.focusedWindow()
    local third = get_horizontal_third(win)
    if third == 2 then
        winresize("hthird-2")
    else
        winresize("hthird-" .. (third + 1))
    end
end

function up_third()
    local win = hs.window.focusedWindow()
    local third = get_vertical_third(win)
    if third == 0 then
        winresize("vthird-0")
    else
        winresize("vthird-" .. (third - 1))
    end
end

function down_third()
    local win = hs.window.focusedWindow()
    local third = get_vertical_third(win)
    if third == 2 then
        winresize("vthird-2")
    else
        winresize("vthird-" .. (third + 1))
    end
end

function center()
    local win = hs.window.focusedWindow()
    win:centerOnScreen()
end

-------- Key bindings

-- Halves of the screen
hs.hotkey.bind({"ctrl", "cmd"}, "Left", hs.fnutils.partial(winresize, "left"))
hs.hotkey.bind({"ctrl", "cmd"}, "Right", hs.fnutils.partial(winresize, "right"))
hs.hotkey.bind({"ctrl", "cmd"}, "Up", hs.fnutils.partial(winresize, "up"))
hs.hotkey.bind({"ctrl", "cmd"}, "Down", hs.fnutils.partial(winresize, "down"))

-- Quarter of the screen
hs.hotkey.bind({"ctrl", "cmd"}, "1", hs.fnutils.partial(win_resize_2, "top-left"))
hs.hotkey.bind({"ctrl", "cmd"}, "2", hs.fnutils.partial(win_resize_2, "top-right"))
hs.hotkey.bind({"ctrl", "cmd"}, "3", hs.fnutils.partial(win_resize_2, "bottom-left"))
hs.hotkey.bind({"ctrl", "cmd"}, "4", hs.fnutils.partial(win_resize_2, "bottom-right"))

-- Center of the screen
hs.hotkey.bind({"ctrl", "cmd"}, "C", center)

-- Thirds of the screen
hs.hotkey.bind({"ctrl", "alt"}, "Left", left_third)
hs.hotkey.bind({"ctrl", "alt"}, "Right", right_third)
hs.hotkey.bind({"ctrl", "alt"}, "Up", up_third)
hs.hotkey.bind({"ctrl", "alt"}, "Down", down_third)

-- Maximized
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "F", hs.fnutils.partial(winresize, "max"))
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "Up", hs.fnutils.partial(winresize, "max"))

-- Move between monitors
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "Left", hs.fnutils.partial(win_move_screen_between_monitors, "left"))
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "Right", hs.fnutils.partial(win_move_screen_between_monitors, "right"))

return obj
