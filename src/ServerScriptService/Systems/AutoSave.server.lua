local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local autoSaveRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AutoSave")
local store = DataStoreService:GetDataStore("PlayerState")

local SAVE_INTERVAL = 60
local THROTTLE_INTERVAL = 30

local lastSaveRequest = {}
local playerStates = {}

local function validateData(data)
    if typeof(data) ~= "table" then
        return false
    end
    if data.PetBux ~= nil and typeof(data.PetBux) ~= "number" then
        return false
    end
    if data.MusicVolume ~= nil and typeof(data.MusicVolume) ~= "number" then
        return false
    end
    if data.SFXVolume ~= nil and typeof(data.SFXVolume) ~= "number" then
        return false
    end
    if data.DebugEnabled ~= nil and typeof(data.DebugEnabled) ~= "boolean" then
        return false
    end
    if data.GraphicsHigh ~= nil and typeof(data.GraphicsHigh) ~= "boolean" then
        return false
    end
    if data.Keybinds ~= nil and typeof(data.Keybinds) ~= "table" then
        return false
    end
    return true
end

autoSaveRemote.OnServerEvent:Connect(function(player, data)
    local now = os.clock()
    local last = lastSaveRequest[player]
    if last and now - last < THROTTLE_INTERVAL then
        return
    end
    if not validateData(data) then
        warn(("Invalid autosave data from %s"):format(player.Name))
        return
    end
    lastSaveRequest[player] = now
    playerStates[player] = data
end)

local function savePlayer(player)
    local data = playerStates[player]
    if not data then
        return
    end
    pcall(function()
        store:SetAsync(player.UserId, data)
    end)
end

Players.PlayerAdded:Connect(function(player)
    local success, data = pcall(function()
        return store:GetAsync(player.UserId)
    end)
    if success and data then
        playerStates[player] = data
        autoSaveRemote:FireClient(player, data)
    else
        playerStates[player] = {}
    end

    task.spawn(function()
        while player.Parent do
            task.wait(SAVE_INTERVAL)
            savePlayer(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayer(player)
    playerStates[player] = nil
    lastSaveRequest[player] = nil
end)