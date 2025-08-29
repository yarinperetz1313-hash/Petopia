print("✅ HUD is working!")
local gui = script.Parent
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.2,0,0.1,0)
label.Position = UDim2.new(0,10,0,10)
label.Text = "Coins: 0"
label.TextScaled = true
label.Parent = gui
