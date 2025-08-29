local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local DataCatalog = require(Modules:WaitForChild("DataCatalog"))
local Inventory = require(script.Parent.InventoryServer)

local BalanceStore = DataStoreService:GetDataStore("PetBux")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local BalancePush = Remotes:WaitForChild("BalancePush")
local BalancePull = Remotes:WaitForChild("BalancePull")

local PurchaseRequest = Remotes:WaitForChild("PurchaseRequest")

local balances = {}

local function sendBalance(player)
    BalancePush:FireClient(player, balances[player])
end

Players.PlayerAdded:Connect(function(player)
    local ok, amount = pcall(function()
        return BalanceStore:GetAsync(player.UserId)
    end)
    balances[player] = ok and amount or 0
    sendBalance(player)
end)

Players.PlayerRemoving:Connect(function(player)
    pcall(function()
        BalanceStore:SetAsync(player.UserId, balances[player] or 0)
    end)
    balances[player] = nil
end)

BalancePull.OnServerInvoke = function(player)
    return balances[player] or 0
end

PurchaseRequest.OnServerEvent:Connect(function(player, itemId, cost)
    local item = DataCatalog.GetItem(itemId)
    if not item then
        warn(("Player %s attempted to purchase invalid item '%s'"):format(player.Name, tostring(itemId)))
        return
    end
    if cost ~= nil and cost ~= item.price then
        warn(("Player %s sent mismatched cost for '%s': %s (expected %d)"):format(player.Name, tostring(itemId), tostring(cost), item.price))
        return
    end

    local current = balances[player] or 0
    if current < item.price then
        return
    end

    balances[player] = current - item.price
    sendBalance(player)

    if item.type == "Pet" then
        item.level = 1
        item.xp = 0
        local traits = {"Playful", "Lazy", "Energetic"}
        item.trait = traits[math.random(#traits)]
    end

    Inventory.AddItem(player, item)
end)

return {}