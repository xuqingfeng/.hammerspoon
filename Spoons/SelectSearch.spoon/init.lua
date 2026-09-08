--- === SelectSearch ===
---
--- 划词搜索/翻译
---
--- Search or translate the selected text in the default browser (⌥⌘S)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "SelectSearch"
obj.version = "1.0"
obj.author = "xuqingfeng"
obj.homepage = "https://github.com/xuqingfeng/.hammerspoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local logger = hs.logger.new("selectSearch", "debug")

-- 暂存并获取选中文本
local function getSelectedText()
    local old = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(30000) -- 30ms 等待剪贴板更新
    local sel = hs.pasteboard.getContents()
    -- 恢复原剪贴板
    if old then hs.pasteboard.setContents(old) end
    return sel or ""
end

-- 搜索引擎/动作定义
local actions = {
    { text = "🔍 Google 搜索", url = "https://www.google.com/search?q=" },
    { text = "🐙 GitHub 搜索", url = "https://github.com/search?q=" },
    { text = "📘 有道翻译",    url = "https://www.youdao.com/result?word=" },
    { text = "🌐 Google 翻译", url = "https://translate.google.com/?sl=auto&tl=zh-CN&text=" },
    { text = "📕 维基百科",    url = "https://zh.wikipedia.org/wiki/" },
}

--- SelectSearch:showSelectSearch()
--- Method
--- 弹出 Chooser，对选中的文本执行搜索或翻译。
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:showSelectSearch()
    local text = getSelectedText()
    if not text or text == "" then
        hs.alert.show("⚠️ 没有选中文本")
        return
    end

    local choices = {}
    for _, a in ipairs(actions) do
        table.insert(choices, {
            text = a.text,
            url = a.url .. hs.http.encodeForQuery(text),
            -- 可选：把原词也带进去供后续使用
            query = text,
        })
    end

    local chooser = hs.chooser.new(function(choice)
        if not choice then return end
        -- 用默认浏览器打开
        hs.urlevent.openURL(choice.url)
    end)

    chooser:choices(choices)
    chooser:placeholderText("选中: " .. (text:sub(1, 30)) .. (text:len() > 30 and "…" or ""))
    chooser:show()
end

function obj:init()
    -- 绑定快捷键 ⌥⌘S
    hs.hotkey.bind({"alt", "cmd"}, "S", function() self:showSelectSearch() end)
    logger.df("Select-Search 已加载 ⌥⌘S")
end

return obj
