-- Shop GUI script: displays current coins and allows purchasing random pets for a fixed price.
-- Uses PurchasePet remote to buy a pet.

local player = game.Players.LocalPlayer
local screen = script.Parent
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local purchaseEvent = remotes:WaitForChild("PurchasePet")
local coinsUpdated  = remotes:WaitForChild("CoinsUpdated")

-- create interface
screen:ClearAllChildren()
screen.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.4,0,0.4,0)
frame.Position = UDim2.new(0.3,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.Parent = screen

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1,0,0.2,0)
header.Text = "SHOP"
header.TextScaled = true
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextColor3 = Color3.fromRGB(255,255,0)
header.Parent = frame

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1,0,0.2,0)
coinsLabel.Position = UDim2.new(0,0,0.2,0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.Gotham
coinsLabel.TextColor3 = Color3.fromRGB(255,255,255)
coinsLabel.Parent = frame

local buyButton = Instance.new("TextButton")
buyButton.Size = UDim2.new(0.8,0,0.25,0)
buyButton.Position = UDim2.new(0.1,0,0.55,0)
buyButton.Text = "Buy Egg (50)"
buyButton.TextScaled = true
buyButton.Font = Enum.Font.GothamBold
buyButton.BackgroundColor3 = Color3.fromRGB(0,170,0)
buyButton.TextColor3 = Color3.fromRGB(255,255,255)
buyButton.Parent = frame

buyButton.MouseButton1Click:Connect(function()
    purchaseEvent:FireServer()
end)

-- update coin count when server notifies
coinsUpdated.OnClientEvent:Connect(function(newAmount)
    coinsLabel.Text = "Coins: ".. tostring(newAmount)
end)

-- hide on start
screen.Enabled = false
