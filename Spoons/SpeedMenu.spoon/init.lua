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
    requestLocationPermissionIfNeeded(self)
    self:rescan()

    if self.rescanTimer then
        self.rescanTimer:stop()
        self.rescanTimer = nil
    end
    -- rescan network interface every 6 hours
    self.rescanTimer = hs.timer.doEvery(21600, function() self:rescan() end)
end

local function data_diff(self)
    local in_seq = executeNumber(self.instr)
    local out_seq = executeNumber(self.outstr)
    local in_diff = in_seq - self.inseq
    local out_diff = out_seq - self.outseq
    if in_diff/1024 > 1024 then
        self.kbin = string.format("%6.2f", in_diff/1024/1024) .. ' MB/s'
    else
        self.kbin = string.format("%6.2f", in_diff/1024) .. ' KB/s'
    end
    if out_diff/1024 > 1024 then
        self.kbout = string.format("%6.2f", out_diff/1024/1024) .. ' MB/s'
    else
        self.kbout = string.format("%6.2f", out_diff/1024) .. ' KB/s'
    end
    -- local disp_str = '↓' .. self.kbin .. ' ↑'.. self.kbout
    -- FIXME: self.kbout not accurate
    local disp_str = '↓' .. self.kbin
    self.disp_str = hs.styledtext.new(disp_str, {font={size=12.0}})
    self.menubar:setTitle(self.disp_str)
    self.inseq = in_seq
    self.outseq = out_seq
end

--- SpeedMenu:rescan()
--- Method
--- Redetect the active interface and redraw everything.
---

function obj:rescan()

    self.interface, self.connectionType = detectActiveInterface()
    logger.df("I! interface: %s (%s)", self.interface, self.connectionType or "unknown")

    local menuitems_table = {}
    if self.interface then
        -- Inspect active interface and create menuitems
        local interface_detail = hs.network.interfaceDetails(self.interface)
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
        local macaddr = hs.execute('ifconfig ' .. self.interface .. ' | grep ether | awk \'{print $2}\'')
        table.insert(menuitems_table, {
            title = "MAC Addr: " .. macaddr,
            tooltip = "Copy MAC Address to clipboard",
            fn = function() hs.pasteboard.setContents(macaddr) end
        })
        -- Start watching the netspeed delta
        self.instr = 'netstat -ibn | grep -e ' .. self.interface .. ' -m 1 | awk \'{print $7}\''
        self.outstr = 'netstat -ibn | grep -e ' .. self.interface .. ' -m 1 | awk \'{print $10}\''

        self.inseq = executeNumber(self.instr)
        self.outseq = executeNumber(self.outstr)

        if self.timer then
            self.timer:stop()
            self.timer = nil
        end
        self.timer = hs.timer.doEvery(1, function() data_diff(self) end)
    else
        if self.timer then
            self.timer:stop()
            self.timer = nil
        end
        self.menubar:setTitle("⚠︎")
    end
    table.insert(menuitems_table, {
        title = "Rescan Network Interfaces",
        fn = function() self:rescan() end
    })
    self.menubar:setMenu(menuitems_table)
end

return obj
