--[[
    MainMenu.client.lua
    Professional main menu system for Petopia.

    Sections
    --------
    1. Constants and configuration
    2. State management
    3. Utility helpers
    4. UI construction
    5. Animation helpers
    6. Input & events
    7. Debug overlay and fail-safes
--]]

------------------------------
-- 1. Constants & Requires --
------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local UIController = require(ModulesFolder:WaitForChild("UIController"))
assert(UIController, "UIController module missing")

local GUI_NAME = "PetopiaMainMenu"

local COLORS = {
    Blue = Color3.fromRGB(45, 120, 220),
    DarkBlue = Color3.fromRGB(25, 25, 50),
    White = Color3.new(1, 1, 1),
    Black = Color3.new(0, 0, 0),
}

local SOUND_ASSETS = {
    Music = "rbxassetid://1843521443",
    Click = "rbxassetid://12221967",
}

----------------------------------------------------------------
-- 2. State management & forward declarations ------------------
----------------------------------------------------------------

local menuState = {
    Visible = true,
    LastOpened = os.time(),
}

local mainGui
local rootFrame
local titleLabel
local buttonContainer
local debugLabel
local backgroundMusic

local buildUI
local showMenu
local hideMenu
local toggleMenu
local setupTitleEffects
local ensureGui

----------------------------------------------------------------
-- 3. Utility helpers ------------------------------------------
----------------------------------------------------------------

local function createButton(name, text, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0.6, 0, 0, 60)
    button.BackgroundColor3 = COLORS.Blue
    button.BorderSizePixel = 2
    button.BorderColor3 = COLORS.White
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamBold
    button.TextSize = 32
    button.Text = text
    button.TextColor3 = COLORS.White
    button.TextStrokeTransparency = 0
    button.TextStrokeColor3 = COLORS.Black

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local function onHover(hovering)
        local goal = {
            BackgroundColor3 = hovering and COLORS.Blue:lerp(COLORS.White, 0.1) or COLORS.Blue,
            TextSize = hovering and 36 or 32,
        }
        TweenService:Create(button, TweenInfo.new(0.15), goal):Play()
    end

    button.MouseEnter:Connect(function()
        onHover(true)
    end)
    button.MouseLeave:Connect(function()
        onHover(false)
    end)

    button.Activated:Connect(function()
        local click = Instance.new("Sound")
        click.SoundId = SOUND_ASSETS.Click
        click.Volume = 0.5
        click.Parent = button
        click:Play()
        task.delay(1, function()
            click:Destroy()
        end)
        callback()
    end)

    return button
end

----------------------------------------------------------------
-- 4. UI construction ------------------------------------------
----------------------------------------------------------------

buildUI = function()
    mainGui = script.Parent
    mainGui.Name = GUI_NAME
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true

    rootFrame = Instance.new("Frame")
    rootFrame.Size = UDim2.fromScale(1, 1)
    rootFrame.BackgroundColor3 = COLORS.DarkBlue
    rootFrame.Parent = mainGui

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.DarkBlue),
        ColorSequenceKeypoint.new(1, COLORS.Blue),
    })
    gradient.Rotation = 0
    gradient.Parent = rootFrame

    backgroundMusic = Instance.new("Sound")
    backgroundMusic.SoundId = SOUND_ASSETS.Music
    backgroundMusic.Volume = 0.25
    backgroundMusic.Looped = true
    backgroundMusic.Parent = rootFrame

    titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = "🐾 PETOPIA 🐾"
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 72
    titleLabel.Size = UDim2.new(1, 0, 0, 140)
    titleLabel.Position = UDim2.new(0, 0, 0.15, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = COLORS.White
    titleLabel.TextStrokeColor3 = COLORS.Black
    titleLabel.TextStrokeTransparency = 0
    titleLabel.Parent = rootFrame

    local particles = Instance.new("ParticleEmitter")
    particles.Rate = 15
    particles.Speed = NumberRange.new(2, 5)
    particles.Lifetime = NumberRange.new(2, 4)
    particles.Rotation = NumberRange.new(-180, 180)
    particles.Texture = "rbxassetid://2418761071"
    particles.Parent = titleLabel

    buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, 0, 0, 300)
    buttonContainer.Position = UDim2.new(0, 0, 0.4, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = rootFrame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 20)
    layout.Parent = buttonContainer

    local playButton = createButton("Play", "▶ PLAY", function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation")
        if spawn then
            character:MoveTo(spawn.Position + Vector3.new(0, 3, 0))
        end
        hideMenu()
    end)
    playButton.Parent = buttonContainer

    local invButton = createButton("Inventory", "🎒 INVENTORY", function()
        UIController.Events.ToggleInventory:Fire()
        hideMenu()
    end)
    invButton.Parent = buttonContainer

    local shopButton = createButton("Shop", "💎 SHOP", function()
        UIController.Events.ToggleShop:Fire()
        hideMenu()
    end)
    shopButton.Parent = buttonContainer

    local settingsButton = createButton("Settings", "⚙ SETTINGS", function()
        UIController.Events.ToggleSettings:Fire()
        hideMenu()
    end)
    settingsButton.Parent = buttonContainer

    debugLabel = Instance.new("TextLabel")
    debugLabel.Size = UDim2.new(0, 400, 0, 20)
    debugLabel.Position = UDim2.new(0, 10, 1, -30)
    debugLabel.BackgroundTransparency = 1
    debugLabel.Font = Enum.Font.Code
    debugLabel.TextSize = 14
    debugLabel.TextXAlignment = Enum.TextXAlignment.Left
    debugLabel.TextColor3 = COLORS.White
    debugLabel.TextStrokeTransparency = 0
    debugLabel.TextStrokeColor3 = COLORS.Black
    debugLabel.Parent = rootFrame

    setupTitleEffects()
    showMenu()
end

----------------------------------------------------------------
-- 5. Animation helpers ---------------------------------------
----------------------------------------------------------------

setupTitleEffects = function()
    task.spawn(function()
        while titleLabel do
            local goal1 = { TextStrokeTransparency = 0.5 }
            TweenService:Create(titleLabel, TweenInfo.new(1.5), goal1):Play()
            task.wait(1.5)
            local goal2 = { TextStrokeTransparency = 0 }
            TweenService:Create(titleLabel, TweenInfo.new(1.5), goal2):Play()
            task.wait(1.5)
        end
    end)
end

showMenu = function()
    menuState.Visible = true
    menuState.LastOpened = os.time()
    rootFrame.Visible = true
    rootFrame.BackgroundTransparency = 1
    TweenService:Create(rootFrame, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
    backgroundMusic:Play()
end

hideMenu = function()
    menuState.Visible = false
    TweenService:Create(rootFrame, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
    task.delay(0.25, function()
        rootFrame.Visible = false
    end)
end

toggleMenu = function()
    if menuState.Visible then
        hideMenu()
    else
        showMenu()
    end
end

----------------------------------------------------------------
-- 6. Input & events ------------------------------------------
----------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end
    if input.KeyCode == Enum.KeyCode.Escape then
        toggleMenu()
    end
end)

UIController.Events.ToggleMenu.Event:Connect(toggleMenu)

----------------------------------------------------------------
-- 7. Debug overlay & fail-safes ------------------------------
----------------------------------------------------------------

local function updateDebug()
    debugLabel.Text = string.format("Menu: %s | LastOpened: %d", tostring(menuState.Visible), menuState.LastOpened)
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if debugLabel then
            updateDebug()
        end
    end
end)

ensureGui = function()
    if not mainGui or not mainGui.Parent then
        buildUI()
    end
end

task.spawn(function()
    while true do
        task.wait(5)
        ensureGui()
    end
end)

-- initialise
buildUI()
