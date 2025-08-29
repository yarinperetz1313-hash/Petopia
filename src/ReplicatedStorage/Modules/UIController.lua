--[[
    UIController.lua
    Centralised collection of BindableEvents used for client <-> client
    communication between user interface systems.  Each event is wrapped
    in a table for organised access.
--]]

local UIController = {}

UIController.Events = {
    ToggleInventory = Instance.new("BindableEvent"),
    ToggleShop = Instance.new("BindableEvent"),
    ToggleSettings = Instance.new("BindableEvent"),
    ToggleMenu = Instance.new("BindableEvent"),
}
for name, event in pairs(UIController.Events) do
    assert(event, ("UIController event missing: %s"):format(name))
end

return UIController
