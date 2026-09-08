--- === SelectSearch ===
---
--- Search, translate, or jump to the copied link in the default browser (⌥⌘S)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "SelectSearch"
obj.version = "1.0"
obj.author = "xuqingfeng"
obj.homepage = "https://github.com/xuqingfeng/.hammerspoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local logger = hs.logger.new("selectSearch", "debug")

-- Save the clipboard, copy the selected text, then restore the clipboard
local function getSelectedText()
    local old = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(30000) -- wait 30ms for the clipboard to update
    local sel = hs.pasteboard.getContents()
    -- restore the original clipboard contents
    if old then hs.pasteboard.setContents(old) end
    return sel or ""
end

-- Strip trailing punctuation from a URL (e.g. the period/comma when copying a whole sentence)
-- Note: Lua patterns work on bytes, so full-width chars must be compared literally,
-- they cannot be placed inside a [] pattern class
local function stripTrailingPunct(url)
    url = url:gsub("[,.;:]+$", "")
    local fullwidth = { "。", "，", "；", "：", "！", "？" }
    while true do
        local removed = false
        for _, p in ipairs(fullwidth) do
            if url:sub(-#p) == p then
                url = url:sub(1, -#p - 1)
                removed = true
                break
            end
        end
        if not removed then break end
    end
    return url
end

-- Detect a link inside the text; returns nil if none is found
local function extractURL(text)
    if not text or text == "" then return nil end

    local t = text:gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" then return nil end

    local url
    if t:match("^https?://") then
        -- the whole text is already a full URL
        url = t
    elseif t:match("^www%.") then
        -- missing scheme, prepend it
        url = "https://" .. t
    elseif not t:match("%s") then
        -- no scheme and no whitespace: has a path like github.com/user/repo,
        -- or a subdomain like sub.example.com
        local dotCount = select(2, t:gsub("%.", ""))
        if dotCount >= 2 or (dotCount >= 1 and t:find("/", 1, true)) then
            url = "https://" .. t
        end
    else
        -- otherwise grab the first http(s):// URL embedded in the text
        url = t:match("(https?://[^%s]+)")
        if not url then
            -- fall back to a www. URL embedded in the text
            url = t:match("(www%.[^%s]+)")
            if url then url = "https://" .. url end
        end
    end

    if not url then return nil end
    url = stripTrailingPunct(url)
    if url == "" then return nil end
    return url
end

-- Search engines / actions
local actions = {
    { text = "🔍 Google Search", url = "https://www.google.com/search?q=" },
    { text = "🌐 Google Translate", url = "https://translate.google.com/?sl=auto&tl=zh-CN&text=" },
    { text = "📘 有道翻译",    url = "https://www.youdao.com/result?word=" },
    { text = "📕 Wikipedia",    url = "https://zh.wikipedia.org/wiki/" },
}

--- SelectSearch:showSelectSearch()
--- Method
--- Show a Chooser to search/translate the selected text, or jump to it if it is a link.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:showSelectSearch()
    local text = getSelectedText()
    if not text or text == "" then
        hs.alert.show("⚠️ no text selected")
        return
    end

    local choices = {}

    -- offer a direct "open link" option when the text is a link
    -- Note: do not add a subText here, or hs.chooser switches to a smaller-font
    -- cell and this row will no longer match the search-engine rows
    local link = extractURL(text)
    if link then
        table.insert(choices, {
            text = "🔗 Go To Link",
            url = link,
            query = text,
        })
    end

    for _, a in ipairs(actions) do
        table.insert(choices, {
            text = a.text,
            url = a.url .. hs.http.encodeForQuery(text),
            -- optional: carry the original word along for later use
            query = text,
        })
    end

    local chooser = hs.chooser.new(function(choice)
        if not choice then return end
        -- open in the default browser
        hs.urlevent.openURL(choice.url)
    end)

    chooser:choices(choices)
    chooser:placeholderText("Selected: " .. (text:sub(1, 30)) .. (text:len() > 30 and "…" or ""))
    chooser:show()
end

function obj:init()
    -- bind the hotkey: ⌥⌘S
    hs.hotkey.bind({"alt", "cmd"}, "S", function() self:showSelectSearch() end)
    logger.df("SelectSearch loaded ⌥⌘S")
end

return obj
