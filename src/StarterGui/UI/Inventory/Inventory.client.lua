-- Inventory GUI: lists all owned pets and lets you equip one.
-- Uses remote events to request data and equip a pet.

local player = game.Players.LocalPlayer
local screen = script.Parent
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local getInventoryEvent = remotes:WaitForChild("GetInventory")
local equipPetEvent = remotes:WaitForChild("EquipPet")
local inventoryList = {}  -- will be provided by server

screen:ClearAllChildren()
screen.Enabled = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.5,0,0.5,0)
frame.Position = UDim2.new(0.25,0,0.25,0)
frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
frame.Parent = screen

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0.15,0)
title.Text = "Inventory"
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255,255,0)
title.Parent = frame

-- container for pet buttons
local container = Instance.new("Frame")
container.Size = UDim2.new(1,0,0.85,0)
container.Position = UDim2.new(0,0,0.15,0)
container.BackgroundTransparency = 1
container.Parent = frame

local function refreshInventory(pets)
    -- clear
    for _, child in ipairs(container:GetChildren()) do
        child:Destroy()
    end
    -- create a button for each pet
    for i, petName in ipairs(pets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0.15,0)
        btn.Position = UDim2.new(0,0,(i-1)*0.15,0)
        btn.Text = "Equip ".. petName
        btn.BackgroundColor3 = Color3.fromRGB(0,170,170)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = container
        btn.MouseButton1Click:Connect(function()
            equipPetEvent:FireServer(petName)
        end)
    end
end

-- handle server sending inventory
getInventoryEvent.OnClientEvent:Connect(function(pets)
    inventoryList = pets
    refreshInventory(pets)
end)

-- when the inventory UI is enabled, ask server for latest inventory
screen:GetPropertyChangedSignal("Enabled"):Connect(function()
    if screen.Enabled then
        getInventoryEvent:FireServer()
    end
end)
