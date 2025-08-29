local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataCatalog"))
local Inventory = require(script.Parent.InventoryServer)

local BalanceStore = DataStoreService:GetDataStore("PetBux")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local BalancePush = Remotes:WaitForChild("BalancePush")
local BalancePull = Remotes:WaitForChild("BalancePull")

local PurchaseRequest = Remotes:WaitForChild("PurchaseRequest")

local THROTTLE_WINDOW = 0.5
local lastRequest = {}

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
    lastRequest[player] = nil
end)

BalancePull.OnServerInvoke = function(player)
    return balances[player] or 0
end

PurchaseRequest.OnServerEvent:Connect(function(player, itemId, cost)
    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < THROTTLE_WINDOW then
        PurchaseRequest:FireClient(player, false, "Please wait before making another purchase")
        return
    end
    lastRequest[player] = now

    local item = DataCatalog.GetItem(itemId)
    if not item then
        PurchaseRequest:FireClient(player, false, "Invalid item")
        warn(("Player %s attempted to purchase invalid item '%s'"):format(player.Name, tostring(itemId)))
        return
    end
    if cost == nil or cost ~= item.price then
        PurchaseRequest:FireClient(player, false, "Invalid price")
        warn(("Player %s sent mismatched cost for '%s': %s (expected %d)"):format(player.Name, tostring(itemId), tostring(cost), item.price))
        return
    end

    local current = balances[player] or 0
    if current < item.price then
        PurchaseRequest:FireClient(player, false, "Insufficient funds")
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