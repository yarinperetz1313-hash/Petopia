-- HUD script: displays current coins and buttons to open Shop or Inventory.
-- It listens for coin updates from the server.

local player = game.Players.LocalPlayer
local screen = script.Parent
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local coinsUpdated = remotes:WaitForChild("CoinsUpdated")

screen:ClearAllChildren()
screen.Enabled = false

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(0.3,0,0.1,0)
coinsLabel.Position = UDim2.new(0.01,0,0.02,0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextColor3 = Color3.fromRGB(255,255,0)
coinsLabel.Text = "Coins: 0"
coinsLabel.Parent = screen

local shopBtn = Instance.new("TextButton")
shopBtn.Size = UDim2.new(0.15,0,0.08,0)
shopBtn.Position = UDim2.new(0.01,0,0.15,0)
shopBtn.Text = "Shop"
shopBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
shopBtn.TextColor3 = Color3.fromRGB(255,255,255)
shopBtn.TextScaled = true
shopBtn.Parent = screen

local invBtn = Instance.new("TextButton")
invBtn.Size = UDim2.new(0.15,0,0.08,0)
invBtn.Position = UDim2.new(0.18,0,0.15,0)
invBtn.Text = "Inventory"
invBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
invBtn.TextColor3 = Color3.fromRGB(255,255,255)
invBtn.TextScaled = true
invBtn.Parent = screen

-- Show Shop/Inventory on button click
shopBtn.MouseButton1Click:Connect(function()
    local ui = screen.Parent
    ui.Shop.Enabled = true
    ui.HUD.Enabled = false
end)
invBtn.MouseButton1Click:Connect(function()
    local ui = screen.Parent
    ui.Inventory.Enabled = true
    ui.HUD.Enabled = false
end)

-- update coins
coinsUpdated.OnClientEvent:Connect(function(newCoins)
    coinsLabel.Text = "Coins: ".. tostring(newCoins)
end)
