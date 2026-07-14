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

local function trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function formatSpeed(bytes)
    if bytes / 1024 > 1024 then
        return string.format("%6.2f MB/s", bytes / 1024 / 1024)
    end
    return string.format("%6.2f KB/s", bytes / 1024)
end

local function getInterfaceBytes(interface)
    local output = trim(hs.execute('netstat -ibn | grep -e ' .. interface .. ' -m 1'))
    if output == "" then return 0, 0 end

    local fields = {}
    for field in output:gmatch("%S+") do
        table.insert(fields, field)
    end
    return tonumber(fields[7]) or 0, tonumber(fields[10]) or 0
end

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

local function requestLocationPermissionIfNeeded(self)
    -- macOS Sonoma+ requires Location Services to read WiFi SSID
    if not hs.location or not hs.location.servicesEnabled() then return end
    if self.locationRequested then return end
    self.locationRequested = true
    hs.location.start()
    hs.timer.doAfter(2, function()
        hs.location.stop()
        self:rescan()
    end)
end

local function stopSpeedTimer(self)
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
end

local function data_diff(self)
    local in_seq, out_seq = getInterfaceBytes(self.interface)
    local in_diff = in_seq - self.inseq
    local out_diff = out_seq - self.outseq

    local disp_str = '↓' .. formatSpeed(in_diff) .. ' ↑' .. formatSpeed(out_diff)
    self.disp_str = hs.styledtext.new(disp_str, {font={size=12.0}})
    self.menubar:setTitle(self.disp_str)
    self.inseq = in_seq
    self.outseq = out_seq
end

local function buildMenuItems(self)
    local menuitems_table = {}

    if self.interface then
        local interface_detail = hs.network.interfaceDetails(self.interface) or {}
        local connectionLabel = self.connectionType == "wifi" and "WiFi" or "Ethernet"
        table.insert(menuitems_table, {
            title = "Connection: " .. connectionLabel .. " (" .. self.interface .. ")",
        })

        local ssid = self.connectionType == "wifi" and getSSID(self.interface)
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
        local macaddr = trim(hs.execute('ifconfig ' .. self.interface .. ' | grep ether | awk \'{print $2}\''))
        table.insert(menuitems_table, {
            title = "MAC Addr: " .. macaddr,
            tooltip = "Copy MAC Address to clipboard",
            fn = function() hs.pasteboard.setContents(macaddr) end
        })
    end

    table.insert(menuitems_table, {
        title = "Rescan Network Interfaces",
        fn = function() self:rescan() end
    })

    return menuitems_table
end

function obj:init()
    self.menubar = hs.menubar.new()
    self.menubar:autosaveName("xuqingfeng.speedmenu")
    requestLocationPermissionIfNeeded(self)
    self:rescan()

    if self.rescanTimer then
        self.rescanTimer:stop()
        self.rescanTimer = nil
    end
    -- rescan network interface every 6 hours
    self.rescanTimer = hs.timer.doEvery(21600, function() self:rescan() end)

    if self.wifiWatcher then
        self.wifiWatcher:stop()
        self.wifiWatcher = nil
    end
    self.wifiWatcher = hs.wifi.watcher.new(function()
        self:rescan()
    end):start()
end

--- SpeedMenu:rescan()
--- Method
--- Redetect the active interface and redraw everything.
---
function obj:rescan()
    local interface, connectionType = detectActiveInterface()
    local interfaceChanged = interface ~= self.interface
    self.interface = interface
    self.connectionType = connectionType
    logger.df("I! interface: %s (%s)", self.interface, self.connectionType or "unknown")

    if self.interface then
        if interfaceChanged or not self.timer then
            self.inseq, self.outseq = getInterfaceBytes(self.interface)
            stopSpeedTimer(self)
            self.timer = hs.timer.doEvery(1, function() data_diff(self) end)
        end
    else
        stopSpeedTimer(self)
        self.menubar:setTitle("⚠︎")
    end

    self.menubar:setMenu(buildMenuItems(self))
end

return obj
