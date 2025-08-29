local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local InventoryStore = DataStoreService:GetDataStore("Inventory")

local inventories = {}

Players.PlayerAdded:Connect(function(player)
    local ok, data = pcall(function()
        return InventoryStore:GetAsync(player.UserId)
    end)
    inventories[player] = ok and data or {}
end)

Players.PlayerRemoving:Connect(function(player)
    pcall(function()
        InventoryStore:SetAsync(player.UserId, inventories[player] or {})
    end)
    inventories[player] = nil
end)

local function addItem(player, item)
    inventories[player] = inventories[player] or {}
    table.insert(inventories[player], item)
end

return {
    GetInventory = function(player)
        return inventories[player] or {}
    end,
    AddItem = addItem,
}