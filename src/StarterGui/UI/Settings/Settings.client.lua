--[[
    Settings.client.lua
    Placeholder settings window with open/close animations and
    UIController integration. Allows toggling via O key or HUD
    button and reports its state for the global debug overlay.

    Sections
    --------
    1. Constants & Requires
    2. State & UI construction
    3. Animation helpers
    4. Input & Events
    5. Debug & Watchdog
--]]

------------------------------
-- 1. Constants & Requires --
------------------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local UIController = require(ModulesFolder:WaitForChild("UIController"))
assert(UIController, "UIController module missing")

local GUI_NAME = "PetopiaSettings"
local COLORS = {
    Background = Color3.fromRGB(25,25,35),
    Bar = Color3.fromRGB(45,120,220),
    White = Color3.new(1,1,1),
    Black = Color3.new(0,0,0),
    Red = Color3.fromRGB(200,60,60),
}

------------------------------
-- 2. State & UI construction --
------------------------------
local settingsState = { Visible = false }
UIController.State.SettingsOpen = false

local mainGui, window, dragBar, closeButton, debugLabel
local buildUI, openSettings, closeSettings, toggleSettings, ensureGui

local function makeDraggable(frame, handle)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local startPos = frame.Position
            local startInput = input.Position
            local conn
            conn = UserInputService.InputChanged:Connect(function(move)
                if move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch then
                    local delta = move.Position - startInput
                    frame.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
                end
            end)
            input.Changed:Connect(function(state)
                if state == Enum.UserInputState.End and conn then conn:Disconnect() end
            end)
        end
    end)
end

buildUI = function()
    mainGui = script.Parent
    mainGui.Name = GUI_NAME
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true
    mainGui.Enabled = false

    window = Instance.new("Frame")
    window.Size = UDim2.new(0.4,0,0.45,0)
    window.Position = UDim2.new(0.3,0,0.275,0)
    window.BackgroundColor3 = COLORS.Background
    window.BorderSizePixel = 0
    window.Visible = false
    window.Parent = mainGui
    Instance.new("UICorner",window).CornerRadius = UDim.new(0,12)

    local shadow = Instance.new("ImageLabel")
    shadow.AnchorPoint = Vector2.new(0.5,0.5)
    shadow.Position = UDim2.new(0.5,0,0.5,0)
    shadow.Size = UDim2.new(1,20,1,20)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0,0,0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10,10,118,118)
    shadow.ZIndex = 0
    shadow.Parent = window

    dragBar = Instance.new("Frame")
    dragBar.Size = UDim2.new(1,0,0,40)
    dragBar.BackgroundColor3 = COLORS.Bar
    dragBar.Parent = window
    Instance.new("UICorner",dragBar).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-50,1,0)
    title.Position = UDim2.new(0,10,0,0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 32
    title.TextColor3 = COLORS.White
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = COLORS.Black
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "⚙ Settings"
    title.Parent = dragBar

    closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0,40,0,40)
    closeButton.Position = UDim2.new(1,-40,0,0)
    closeButton.BackgroundColor3 = COLORS.Red
    closeButton.Text = "✖"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 24
    closeButton.TextColor3 = COLORS.White
    closeButton.TextStrokeTransparency = 0
    closeButton.TextStrokeColor3 = COLORS.Black
    closeButton.AutoButtonColor = false
    closeButton.Parent = dragBar
    Instance.new("UICorner",closeButton).CornerRadius = UDim.new(0,8)

    local placeholder = Instance.new("TextLabel")
    placeholder.Size = UDim2.new(1,-20,1,-60)
    placeholder.Position = UDim2.new(0,10,0,50)
    placeholder.BackgroundTransparency = 1
    placeholder.Font = Enum.Font.GothamBold
    placeholder.TextSize = 24
    placeholder.TextColor3 = COLORS.White
    placeholder.TextStrokeTransparency = 0
    placeholder.TextStrokeColor3 = COLORS.Black
    placeholder.TextWrapped = true
    placeholder.Text = "Settings coming soon!"
    placeholder.Parent = window

    debugLabel = Instance.new("TextLabel")
    debugLabel.Size = UDim2.new(0,300,0,20)
    debugLabel.Position = UDim2.new(0,10,1,-30)
    debugLabel.BackgroundTransparency = 1
    debugLabel.Font = Enum.Font.Code
    debugLabel.TextSize = 14
    debugLabel.TextColor3 = COLORS.White
    debugLabel.TextStrokeTransparency = 0
    debugLabel.TextStrokeColor3 = COLORS.Black
    debugLabel.Parent = mainGui

    makeDraggable(window,dragBar)

    closeButton.Activated:Connect(function()
        closeSettings()
    end)
end

------------------------------
-- 3. Animation helpers ------
------------------------------
openSettings = function()
    settingsState.Visible = true
    UIController.State.SettingsOpen = true
    mainGui.Enabled = true
    window.Visible = true
    window.Size = UDim2.new(0,0,0,0)
    window.Position = UDim2.new(0.5,0,0.5,0)
    TweenService:Create(window,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Size = UDim2.new(0.4,0,0.45,0),
        Position = UDim2.new(0.3,0,0.275,0),
    }):Play()
end

closeSettings = function()
    settingsState.Visible = false
    UIController.State.SettingsOpen = false
    TweenService:Create(window,TweenInfo.new(0.2),{
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(0.5,0,0.5,0),
    }):Play()
    task.delay(0.2,function()
        window.Visible = false
        mainGui.Enabled = false
    end)
end

toggleSettings = function()
    if settingsState.Visible then
        closeSettings()
    else
        openSettings()
    end
end

------------------------------
-- 4. Input & Events ---------
------------------------------
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.O then
        toggleSettings()
    elseif input.KeyCode == Enum.KeyCode.Escape and settingsState.Visible then
        closeSettings()
    end
end)

UIController.Events.ToggleSettings.Event:Connect(toggleSettings)

------------------------------
-- 5. Debug & Watchdog -------
------------------------------
local function updateDebug()
    debugLabel.Text = string.format("Settings: %s", tostring(settingsState.Visible))
end

updateDebug()

spawn(function()
    while true do
        task.wait(0.5)
        updateDebug()
    end
end)

ensureGui = function()
    if not mainGui or not mainGui.Parent then
        buildUI()
    end
end

spawn(function()
    while true do
        task.wait(5)
        ensureGui()
    end
end)

-- initialise
buildUI()