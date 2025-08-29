local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local autoSaveRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AutoSave")
local autoSavePull = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AutoSavePull")
local store = DataStoreService:GetDataStore("PlayerState")

local SAVE_INTERVAL = 60
local SAVE_COOLDOWN = 30 -- minimum time between actual DataStore writes

local lastSaved = {}

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

local function fetchPlayerState(player)
    local success, data = pcall(function()
        return autoSavePull:InvokeClient(player)
    end)
    if not success or not validateData(data) then
        if data then
            warn(("Invalid autosave data from %s"):format(player.Name))
        end
        return nil
    end
    return data
end

local function savePlayer(player)
    local now = os.clock()
    local last = lastSaved[player]
    if last and now - last < SAVE_COOLDOWN then
        return
    end

    local data = fetchPlayerState(player)
    if not data then
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
    if not success or not validateData(data) then
        data = table.clone(DEFAULT_STATE)
    end

    autoSaveRemote:FireClient(player, data)

    task.spawn(function()
        while player.Parent do
            task.wait(SAVE_INTERVAL)
            savePlayer(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayer(player)
    lastSaved[player] = nil
end)