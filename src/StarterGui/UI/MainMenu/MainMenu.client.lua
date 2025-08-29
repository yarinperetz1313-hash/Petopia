print("MainMenu script is running!")

local player = game.Players.LocalPlayer
local gui = script.Parent

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0.2, 0)
textLabel.Text = "MainMenu is working!"
textLabel.TextScaled = true
textLabel.Parent = gui
