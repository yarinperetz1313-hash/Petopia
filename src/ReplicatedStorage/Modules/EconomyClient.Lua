local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIController"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BalancePush = Remotes:WaitForChild("BalancePush", 5)
local BalancePull = Remotes:WaitForChild("BalancePull", 5)

local EconomyClient = {}
local balance = 0

local function setBalance(amount)
    balance = amount
    UIController.State.PetBux = amount
    UIController.Fire("BalanceChanged", balance)
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

-- expose setter for server confirmation handlers
function EconomyClient.SetBalance(amount)
    setBalance(amount)
end

return EconomyClient