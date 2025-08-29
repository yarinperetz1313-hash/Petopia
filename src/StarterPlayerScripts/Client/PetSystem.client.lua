--[[
    PetSystem.client.lua
    Spawns owned pets beside the player, assigns random traits,
    and handles basic following and leveling. Pets are purely
    client-side placeholders for now.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIController = require(Modules:WaitForChild("UIController"))

local LocalPlayer = Players.LocalPlayer

local traits = {
    Playful = {speed = 10, behaviour = function(p) if math.random()<0.01 then p:TweenSize(p.Size*1.2, "Out", "Quad",0.2,true) end end},
    Lazy = {speed = 4},
    Energetic = {speed = 14},
}

local pets = {}

local function spawnPet(data)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local petModel
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if assets and assets:FindFirstChild(data.id) then
        petModel = assets[data.id]:Clone()
    else
        petModel = Instance.new("Part")
        petModel.Shape = Enum.PartType.Ball
        petModel.Color = Color3.fromRGB(255, 200, 0)
        petModel.Size = Vector3.new(1,1,1)
    end
    petModel.CanCollide=false
    petModel.Anchored=false
    petModel.Position = hrp.Position + Vector3.new(2,0,0)
    petModel.Parent = workspace

    pets[data.id] = {
        model = petModel,
        speed = (traits[data.trait] and traits[data.trait].speed) or 8,
        name = data.name,
        level = data.level or 1,
        xp = data.xp or 0,
        trait = data.trait,
    }
    UIController.State.ActivePet = string.format("%s | Lvl %d | XP %d | Trait %s | Following true", data.name, data.level or 1, data.xp or 0, data.trait)
end

UIController.Events.AddToInventory.Event:Connect(function(item)
    if item.type == "Pet" then
        spawnPet(item)
    end
end)

RunService.Heartbeat:Connect(function(dt)
    for id, pet in pairs(pets) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local model = pet.model
        if hrp and model then
            local direction = (hrp.Position - model.Position)
            local distance = direction.Magnitude
            if distance > 5 then
                model.CFrame = model.CFrame + direction.Unit * pet.speed * dt
            end
            local t = traits[pet.trait]
            if t and t.behaviour then t.behaviour(model) end
            pet.xp = pet.xp + dt*5
            if pet.xp >= 100 then
                pet.level = pet.level + 1
                pet.xp = pet.xp - 100
            end
        end
    end
end)

return {}