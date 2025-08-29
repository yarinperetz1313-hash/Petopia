local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

-- Remove old pet if one already exists
if workspace:FindFirstChild("Pet") then
    workspace.Pet:Destroy()
end

-- Spawn a simple pet
local pet = Instance.new("Part")
pet.Name = "Pet"
pet.Size = Vector3.new(2, 2, 2)
pet.Shape = Enum.PartType.Ball
pet.Color = Color3.fromRGB(255, 200, 0)
pet.Anchored = false
pet.CanCollide = false
pet.Parent = workspace

local bodyPos = Instance.new("BodyPosition")
bodyPos.MaxForce = Vector3.new(10000, 10000, 10000)
bodyPos.D = 10
bodyPos.P = 10000
bodyPos.Parent = pet

game:GetService("RunService").RenderStepped:Connect(function()
	if char and char.PrimaryPart then
		local followPos = char.PrimaryPart.Position + Vector3.new(3, 0, 3)
		bodyPos.Position = followPos
	end
end)
