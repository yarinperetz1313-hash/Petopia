local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    local current = balances[player] or 0
    if type(cost) == "number" and current >= cost then
        balances[player] = current - cost
        sendBalance(player)
        -- inventory integration handled elsewhere
    end
end)

return {}