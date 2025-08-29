local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
local UIController = require(Modules:WaitForChild("UIController", 5))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local BalancePush = Remotes:WaitForChild("BalancePush", 5)
local BalancePull = Remotes:WaitForChild("BalancePull", 5)
local PurchaseRequest = Remotes:WaitForChild("PurchaseRequest", 5)

local EconomyClient = {}
local balance = 0

local function setBalance(amount)
    balance = amount
    UIController.SetPetBux(amount)
end

if BalancePush then
    BalancePush.OnClientEvent:Connect(setBalance)
end

function EconomyClient.GetPetBux()
    return balance
end

function EconomyClient.RequestRefresh()
    if BalancePull then
        local ok, result = pcall(function()
            return BalancePull:InvokeServer()
        end)
        if ok and type(result) == "number" then
            setBalance(result)
        end
    end
    return balance
end

function EconomyClient.SetBalance(amount)
    setBalance(amount)
end

function EconomyClient.Purchase(itemId, cost)
    PurchaseRequest:FireServer(itemId, cost)
end

return EconomyClient