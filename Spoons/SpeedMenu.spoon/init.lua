--- === SpeedMenu ===
---
--- Menubar netspeed meter
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/SpeedMenu.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/SpeedMenu.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "SpeedMenu"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local logger = hs.logger.new("speed", "debug")

local function isWifiInterface(interface)
    if not interface then return false end
    return hs.fnutils.contains(hs.wifi.interfaces() or {}, interface)
end

local function detectActiveInterface()
    local ipv4, ipv6 = hs.network.primaryInterfaces()
    local interface = ipv4 or ipv6
    if not interface then return nil, nil end

    local connectionType = isWifiInterface(interface) and "wifi" or "ethernet"
    return interface, connectionType
end

local function executeNumber(cmd)
    local output = hs.execute(cmd)
    return tonumber(output) or 0
end

local function requestLocationPermissionIfNeeded()
    -- macOS Sonoma+ requires Location Services to read WiFi SSID
    if not hs.location or not hs.location.servicesEnabled() then return end
    if obj.locationRequested then return end
    obj.locationRequested = true
    hs.location.start()
    hs.timer.doAfter(2, function()
        hs.location.stop()
        obj:rescan()
    end)
end

local function getSSID(interface)
    local wifiInterfaces = hs.wifi.interfaces() or {}
    local wifiInterface = interface
    if not hs.fnutils.contains(wifiInterfaces, wifiInterface) then
        wifiInterface = wifiInterfaces[1]
    end
    if not wifiInterface then return nil end

    local ssid = hs.wifi.currentNetwork(wifiInterface)
    if not ssid then
        local details = hs.wifi.interfaceDetails(wifiInterface)
        ssid = details and details.ssid
    end
    if not ssid then
        local netDetails = hs.network.interfaceDetails(wifiInterface)
        ssid = netDetails and netDetails.AirPort and netDetails.AirPort.SSID
    end
    return ssid
end

function obj:init()
    self.menubar = hs.menubar.new()
    self.menubar:autosaveName("xuqingfeng.speedmenu")
    requestLocationPermissionIfNeeded()
    obj:rescan()

    if obj.rescanTimer then
        obj.rescanTimer:stop()
        obj.rescanTimer = nil
    end
    -- rescan network interface every 6 hours
    obj.rescanTimer = hs.timer.doEvery(21600, function() obj:rescan() end)
end

local function data_diff()
    local in_seq = executeNumber(obj.instr)
    local out_seq = executeNumber(obj.outstr)
    local in_diff = in_seq - obj.inseq
    local out_diff = out_seq - obj.outseq
    if in_diff/1024 > 1024 then
        obj.kbin = string.format("%6.2f", in_diff/1024/1024) .. ' MB/s'
    else
        obj.kbin = string.format("%6.2f", in_diff/1024) .. ' KB/s'
    end
    if out_diff/1024 > 1024 then
        obj.kbout = string.format("%6.2f", out_diff/1024/1024) .. ' MB/s'
    else
        obj.kbout = string.format("%6.2f", out_diff/1024) .. ' KB/s'
    end
    -- local disp_str = '↓' .. obj.kbin .. ' ↑'.. obj.kbout
    -- FIXME: obj.kbout not accurate
    local disp_str = '↓' .. obj.kbin
    obj.disp_str = hs.styledtext.new(disp_str, {font={size=12.0}})
    obj.menubar:setTitle(obj.disp_str)
    obj.inseq = in_seq
    obj.outseq = out_seq
end

--- SpeedMenu:rescan()
--- Method
--- Redetect the active interface and redraw everything.
---

function obj:rescan()

    obj.interface, obj.connectionType = detectActiveInterface()
    logger.df("I! interface: %s (%s)", obj.interface, obj.connectionType or "unknown")

    local menuitems_table = {}
    if obj.interface then
        -- Inspect active interface and create menuitems
        local interface_detail = hs.network.interfaceDetails(obj.interface)
        local connectionLabel = obj.connectionType == "wifi" and "WiFi" or "Ethernet"
        table.insert(menuitems_table, {
            title = "Connection: " .. connectionLabel .. " (" .. obj.interface .. ")",
        })
        local ssid = obj.connectionType == "wifi" and getSSID(obj.interface)
        if ssid then
            table.insert(menuitems_table, {
                title = "SSID: " .. ssid,
                tooltip = "Copy SSID to clipboard",
                fn = function() hs.pasteboard.setContents(ssid) end
            })
        end
        if interface_detail.IPv4 then
            local ipv4 = interface_detail.IPv4.Addresses[1]
            table.insert(menuitems_table, {
                title = "IPv4: " .. ipv4,
                tooltip = "Copy IPv4 to clipboard",
                fn = function() hs.pasteboard.setContents(ipv4) end
            })
        end
        if interface_detail.IPv6 then
            local ipv6 = interface_detail.IPv6.Addresses[1]
            table.insert(menuitems_table, {
                title = "IPv6: " .. ipv6,
                tooltip = "Copy IPv6 to clipboard",
                fn = function() hs.pasteboard.setContents(ipv6) end
            })
        end
        local macaddr = hs.execute('ifconfig ' .. obj.interface .. ' | grep ether | awk \'{print $2}\'')
        table.insert(menuitems_table, {
            title = "MAC Addr: " .. macaddr,
            tooltip = "Copy MAC Address to clipboard",
            fn = function() hs.pasteboard.setContents(macaddr) end
        })
        -- Start watching the netspeed delta
        obj.instr = 'netstat -ibn | grep -e ' .. obj.interface .. ' -m 1 | awk \'{print $7}\''
        obj.outstr = 'netstat -ibn | grep -e ' .. obj.interface .. ' -m 1 | awk \'{print $10}\''

        obj.inseq = executeNumber(obj.instr)
        obj.outseq = executeNumber(obj.outstr)

        if obj.timer then
            obj.timer:stop()
            obj.timer = nil
        end
        obj.timer = hs.timer.doEvery(1, data_diff)
    else
        if obj.timer then
            obj.timer:stop()
            obj.timer = nil
        end
        obj.menubar:setTitle("⚠︎")
    end
    table.insert(menuitems_table, {
        title = "Rescan Network Interfaces",
        fn = function() obj:rescan() end
    })
    obj.menubar:setMenu(menuitems_table)
end

return obj
