-- Server-side script managing coins, inventory, purchases, equipping pets, etc.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlayerData = require(Modules:WaitForChild("PlayerData"))

-- ensure a Remotes folder exists
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

-- create or get remote events
local function getOrCreateRemote(name)
    local r = remotes:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = remotes
    end
    return r
end

local purchaseEvent   = getOrCreateRemote("PurchasePet")
local coinsUpdated    = getOrCreateRemote("CoinsUpdated")
local getInventoryEvent= getOrCreateRemote("GetInventory")
local equipPetEvent   = getOrCreateRemote("EquipPet")

-- list of possible pets; just strings for now
local petNames = {"Dog","Cat","Fox","Bunny"}

local function updateCoins(player)
    coinsUpdated:FireClient(player, PlayerData.getCoins(player))
end

-- new player setup
Players.PlayerAdded:Connect(function(player)
    PlayerData.newPlayer(player)
    updateCoins(player)
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerData.removePlayer(player)
end)

-- handle purchase
purchaseEvent.OnServerEvent:Connect(function(player)
    local cost = 50
    local coins = PlayerData.getCoins(player)
    if coins < cost then return end
    PlayerData.removeCoins(player, cost)
    -- give random pet
    local pet = petNames[math.random(1,#petNames)]
    PlayerData.addPet(player, pet)
    updateCoins(player)
end)

-- handle inventory request
getInventoryEvent.OnServerEvent:Connect(function(player)
    local inv = PlayerData.getInventory(player)
    getInventoryEvent:FireClient(player, inv)
end)

-- handle equip
equipPetEvent.OnServerEvent:Connect(function(player, petName)
    PlayerData.setEquippedPet(player, petName)
    -- you could spawn pet model here
end)

-- update coins when changed (PlayerData has no events; call updateCoins after each change)
