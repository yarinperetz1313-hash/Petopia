--[[
    HUD.client.lua
    Always-visible heads-up display showing PetBux balance and
    icon buttons for major UI windows. A global debug overlay
    reports the state of all UI systems each frame.

    Sections
    --------
    1. Constants & Requires
    2. UI Construction
    3. Event Wiring
    4. Debug Overlay
--]]

------------------------------
-- 1. Constants & Requires --
------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local UIController = require(ModulesFolder:WaitForChild("UIController"))
local EconomyClient = require(ModulesFolder:WaitForChild("EconomyClient"))
assert(UIController, "UIController module missing")

local COLORS = {
    Blue = Color3.fromRGB(45,120,220),
    White = Color3.new(1,1,1),
    Black = Color3.new(0,0,0),
}

local mainGui = script.Parent
mainGui.ResetOnSpawn = false
mainGui.IgnoreGuiInset = true

local balanceLabel
local debugLabel

local function makeButton(name, text, eventName, order)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.fromOffset(40,40)
    btn.Position = UDim2.new(1, -(50 * order), 0, 10)
    btn.AnchorPoint = Vector2.new(1,0)
    btn.BackgroundColor3 = COLORS.Blue
    btn.AutoButtonColor = false
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.TextColor3 = COLORS.White
    btn.TextStrokeTransparency = 0
    btn.TextStrokeColor3 = COLORS.Black
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.Parent = mainGui

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = COLORS.Blue:lerp(COLORS.White,0.1)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = COLORS.Blue
    end)
    btn.Activated:Connect(function()
        UIController.Fire(eventName)
        TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.fromOffset(44,44)}):Play()
        task.delay(0.1, function()
            TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.fromOffset(40,40)}):Play()
        end)
    end)
end

------------------------------
-- 2. UI Construction --------
------------------------------
balanceLabel = Instance.new("TextLabel")
balanceLabel.Size = UDim2.new(0,200,0,30)
balanceLabel.Position = UDim2.new(1,-10,0,60)
balanceLabel.AnchorPoint = Vector2.new(1,0)
balanceLabel.BackgroundTransparency = 1
balanceLabel.Font = Enum.Font.GothamBold
balanceLabel.TextSize = 22
balanceLabel.TextColor3 = COLORS.White
balanceLabel.TextStrokeTransparency = 0
balanceLabel.TextStrokeColor3 = COLORS.Black
balanceLabel.TextXAlignment = Enum.TextXAlignment.Right
balanceLabel.Text = "🪙 PetBux: 0"
balanceLabel.Parent = mainGui

makeButton("ShopButton","💎","ToggleShop",1)
makeButton("InventoryButton","🎒","ToggleInventory",2)
makeButton("SettingsButton","⚙","ToggleSettings",3)

------------------------------
-- 3. Event Wiring -----------
------------------------------
UIController.Events.BalanceChanged.Event:Connect(function(amount)
    balanceLabel.Text = string.format("🪙 PetBux: %,d", amount)
end)

-- initialise label with current balance in case state updated before connection
balanceLabel.Text = string.format("🪙 PetBux: %,d", UIController.State.PetBux)

UIController.Events.DebugOverlayToggled.Event:Connect(function(enabled)
    debugLabel.Visible = enabled
end)

------------------------------
-- 4. Debug Overlay ----------
------------------------------
debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(0,600,0,60)
debugLabel.Position = UDim2.new(0,10,1,-70)
debugLabel.BackgroundTransparency = 1
debugLabel.Font = Enum.Font.Code
debugLabel.TextSize = 14
debugLabel.TextColor3 = COLORS.White
debugLabel.TextStrokeTransparency = 0
debugLabel.TextStrokeColor3 = COLORS.Black
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.TextYAlignment = Enum.TextYAlignment.Top
debugLabel.Parent = mainGui

debugLabel.Visible = UIController.State.DebugEnabled
debugLabel.Text = ""

RunService.RenderStepped:Connect(function()
    if not UIController.State.DebugEnabled then return end
    local s = UIController.State
    debugLabel.Text = string.format(
        "PetBux: %d | Shop: %s (Tab: %s, Items: %d) | Inventory: %s (Slots: %d/%d) | Settings: %s | Marketplace: %s | Last: %s",
        s.PetBux,
        tostring(s.ShopOpen), s.ShopTab, s.ShopItems or 0,
        tostring(s.InventoryOpen), s.InventorySlots or 0, s.InventoryCapacity or 0,
        tostring(s.SettingsOpen),
        s.MarketplaceState or "idle",
        s.LastEvent or "none"
    )
    if s.ActivePet then
        debugLabel.Text = debugLabel.Text .. string.format("\nPet: %s", s.ActivePet)
    end
end)

-- starting demo balance
UIController.SetPetBux(1245)