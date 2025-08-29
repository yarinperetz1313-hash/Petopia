-- Main menu script: displays the Play, Shop and Inventory buttons.
-- When Play is clicked, hide the menu and show HUD.  Shop and Inventory buttons open those UIs.

local player = game.Players.LocalPlayer
local screen = script.Parent  -- this LocalScript lives under a ScreenGui (MainMenu)

-- make sure other screens exist
local parent = screen.Parent
local shopGui    = parent:FindFirstChild("Shop")
local inventoryGui = parent:FindFirstChild("Inventory")
local hudGui       = parent:FindFirstChild("HUD")

-- helper to hide all menu GUIs
local function hideAllMenus()
    screen.Enabled = false
    if shopGui then shopGui.Enabled = false end
    if inventoryGui then inventoryGui.Enabled = false end
    if hudGui then hudGui.Enabled = false end
end

-- build simple interface programmatically
screen:ClearAllChildren()
screen.Enabled = true

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.3, 0, 0.4, 0)
frame.Position = UDim2.new(0.35,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(45,45,45)
frame.Parent = screen

local title = Instance.new("TextLabel")
title.Text = "PETOPIA"
title.Size = UDim2.new(1,0,0.2,0)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255,255,0)
title.Parent = frame

local function makeButton(name, order, text)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Button"
    btn.Text = text
    btn.Size = UDim2.new(0.8,0,0.15,0)
    btn.Position = UDim2.new(0.1,0,0.25 + (order-1)*0.18,0)
    btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.Parent = frame
    return btn
end

local playButton     = makeButton("Play",1,"Play")
local shopButton     = makeButton("Shop",2,"Shop")
local inventoryButton= makeButton("Inventory",3,"Inventory")

playButton.MouseButton1Click:Connect(function()
    hideAllMenus()
    if hudGui then hudGui.Enabled = true end
end)

shopButton.MouseButton1Click:Connect(function()
    hideAllMenus()
    if shopGui then shopGui.Enabled = true end
end)

inventoryButton.MouseButton1Click:Connect(function()
    hideAllMenus()
    if inventoryGui then inventoryGui.Enabled = true end
end)
