local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local autoSaveRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AutoSave")
local store = DataStoreService:GetDataStore("PlayerState")

autoSaveRemote.OnServerEvent:Connect(function(player, data)
    if typeof(data) ~= "table" then return end
    pcall(function()
        store:SetAsync(player.UserId, data)
    end)
end)

Players.PlayerAdded:Connect(function(player)
    local success, data = pcall(function()
        return store:GetAsync(player.UserId)
    end)
    if success and data then
        autoSaveRemote:FireClient(player, data)
    end
end)