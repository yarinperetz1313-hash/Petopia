--[[
    UIController.lua
    Centralised collection of BindableEvents used for client <-> client
    communication between user interface systems.  Each event is wrapped
    in a table for organised access.
--]]

local UIController = {}

UIController.State = {
    PetBux = 0,
    ShopOpen = false,
    ShopTab = "Pets",
    ShopItems = 0,
    PendingItem = nil,
    InventoryOpen = false,
    InventorySlots = 0,
    InventoryCapacity = 0,
    SettingsOpen = false,
    MarketplaceState = "idle",
    DebugEnabled = true,
    GraphicsHigh = true,
    Keybinds = {
        Inventory = Enum.KeyCode.I,
        Shop = Enum.KeyCode.B,
        Settings = Enum.KeyCode.O,
    },
    MusicVolume = 0.5,
    SFXVolume = 0.5,
}

UIController.Events = {
    ToggleInventory = Instance.new("BindableEvent"),
    ToggleShop = Instance.new("BindableEvent"),
    ToggleSettings = Instance.new("BindableEvent"),
    ToggleMenu = Instance.new("BindableEvent"),
    AddToInventory = Instance.new("BindableEvent"),
    PetBuxChanged = Instance.new("BindableEvent"),
    TogglePetBuxPurchase = Instance.new("BindableEvent"),
    DebugOverlayToggled = Instance.new("BindableEvent"),
    SettingsChanged = Instance.new("BindableEvent"),
}
for name, event in pairs(UIController.Events) do
    assert(event, ("UIController event missing: %s"):format(name))
end

function UIController.SetPetBux(amount)
    UIController.State.PetBux = amount
    UIController.Events.PetBuxChanged:Fire(amount)
end

return UIController
