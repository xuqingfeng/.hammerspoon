local obj = {}

function connectToCiscoAnyConnect()

    local app = hs.application.find("Cisco AnyConnect Secure Mobility Client")
    if app then
        app:activate()
        -- fill in VPN host
        hs.eventtap.keyStroke({"cmd"}, "delete")
        hs.eventtap.keyStrokes(CISCO_ANY_CONNECT_VPN_HOST)
        hs.eventtap.keyStroke({}, "return")

        -- sleep
        hs.execute("sleep 1")
        -- get RSA token
        local stoken = hs.execute("stoken tokencode", {
            with_user_env = true
        })
        hs.eventtap.keyStrokes(stoken)
        hs.eventtap.keyStroke({}, "return")

        -- sleep
        hs.execute("sleep 3")
        hs.eventtap.keyStroke({}, "return")
    end
end

function obj:init()
    hs.hotkey.bind({"ctrl", "cmd"}, "V", connectToCiscoAnyConnect)
end

return obj
