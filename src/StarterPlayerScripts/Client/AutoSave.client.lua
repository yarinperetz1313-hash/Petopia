local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIController"))
local AutoSave = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AutoSave")

local function send()
    AutoSave:FireServer(UIController.State)
end

UIController.Events.PetBuxChanged.Event:Connect(send)
UIController.Events.SettingsChanged.Event:Connect(send)
UIController.Events.AddToInventory.Event:Connect(send)

task.spawn(function()
    while true do
        task.wait(60)
        send()
    end
end)

AutoSave.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    if data.PetBux then UIController.SetPetBux(data.PetBux) end
    if data.MusicVolume then UIController.State.MusicVolume = data.MusicVolume end
    if data.SFXVolume then UIController.State.SFXVolume = data.SFXVolume end
    if data.DebugEnabled ~= nil then UIController.State.DebugEnabled = data.DebugEnabled end
    if data.GraphicsHigh ~= nil then UIController.State.GraphicsHigh = data.GraphicsHigh end
    if data.Keybinds then UIController.State.Keybinds = data.Keybinds end
    UIController.Events.SettingsChanged:Fire(UIController.State)
end)