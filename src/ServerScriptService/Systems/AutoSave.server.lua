local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local autoSaveRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AutoSave")
local store = DataStoreService:GetDataStore("PlayerState")

local SAVE_INTERVAL = 60
local SAVE_COOLDOWN = 30 -- minimum time between actual DataStore writes
local REQUEST_COOLDOWN = 30 -- minimum time between client save requests

local lastSaveRequest = {}
local lastSaved = {}
local playerStates = {}

-- expected structure for player state
local SCHEMA = {
    PetBux = "number",
    MusicVolume = "number",
    SFXVolume = "number",
    DebugEnabled = "boolean",
    GraphicsHigh = "boolean",
    Keybinds = "table",
}

local DEFAULT_STATE = {
    PetBux = 0,
    MusicVolume = 0,
    SFXVolume = 0,
    DebugEnabled = false,
    GraphicsHigh = false,
    Keybinds = {},
}

local function validateData(data)
    if typeof(data) ~= "table" then
        return false
    end

    -- ensure all keys exist and match expected types
    for key, expectedType in pairs(SCHEMA) do
        if typeof(data[key]) ~= expectedType then
            return false
        end
    end

    -- ensure no unexpected keys are present
    for key in pairs(data) do
        if SCHEMA[key] == nil then
            return false
        end
    end

    return true
end

autoSaveRemote.OnServerEvent:Connect(function(player, data)
    local now = os.clock()
    local last = lastSaveRequest[player]
    if last and now - last < REQUEST_COOLDOWN then
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
    if not data or not validateData(data) then
        if data then
            warn(("Refusing to save invalid data for %s"):format(player.Name))
        end
        return
    end

    local now = os.clock()
    local last = lastSaved[player]
    if last and now - last < SAVE_COOLDOWN then
        return
    end

    pcall(function()
        store:SetAsync(player.UserId, data)
    end)
    lastSaved[player] = now
end

Players.PlayerAdded:Connect(function(player)
    local success, data = pcall(function()
        return store:GetAsync(player.UserId)
    end)
    if success and validateData(data) then
        playerStates[player] = data
    else
        playerStates[player] = table.clone(DEFAULT_STATE)
    end

    autoSaveRemote:FireClient(player, playerStates[player])

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
    lastSaved[player] = nil
end)