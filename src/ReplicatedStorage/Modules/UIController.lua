--[[
    UIController.lua
    Centralised collection of BindableEvents used for client <-> client
    communication between user interface systems.  Each event is wrapped
    in a table for organised access.
--]]

local UIController = {}

UIController.State = {
    PetBux = 0,
    LastEvent = "none",
}

UIController.Events = {
    ToggleMenu = Instance.new("BindableEvent"),
    ToggleInventory = Instance.new("BindableEvent"),
    ToggleShop = Instance.new("BindableEvent"),
    ToggleSettings = Instance.new("BindableEvent"),
    TogglePetBux = Instance.new("BindableEvent"),
    AddToInventory = Instance.new("BindableEvent"),
    BalanceChanged = Instance.new("BindableEvent"),
    SettingsChanged = Instance.new("BindableEvent"),
    DebugOverlayToggled = Instance.new("BindableEvent"),
}

for name, event in pairs(UIController.Events) do
    assert(event, ("UIController event missing: %s"):format(name))
end

function UIController.Fire(name, ...)
    local evt = UIController.Events[name]
    assert(evt, ("Unknown UI event: %s"):format(name))
    UIController.State.LastEvent = name
    evt:Fire(...)
end

function UIController.On(name, fn)
    local evt = UIController.Events[name]
    assert(evt, ("Unknown UI event: %s"):format(name))
    return evt.Event:Connect(fn)
end

UIController.FireEvent = UIController.Fire -- backward compatibility

function UIController.SetPetBux(amount)
    UIController.State.PetBux = amount
    UIController.Fire("BalanceChanged", amount)
end

return UIController