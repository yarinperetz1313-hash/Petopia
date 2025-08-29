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
local settingsState = { Visible = false, ActiveTab = "Audio" }
UIController.State.SettingsOpen = false

local TAB_ORDER = {"Audio","Display","Controls"}
local tabFrames = {}
local controlsRefs = {}

local mainGui, window, dragBar, closeButton, tabBar, contentFrame, debugLabel
local buildUI, switchTab, openSettings, closeSettings, toggleSettings, ensureGui, applyState
local waitingForKey

local function createToggle(parent, labelText, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-20,0,30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.TextColor3 = COLORS.White
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = COLORS.Black
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0.7,0,1,0)
    label.Text = labelText
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.3,0,1,0)
    btn.Position = UDim2.new(0.7,0,0,0)
    btn.BackgroundColor3 = COLORS.Bar
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.TextColor3 = COLORS.White
    btn.TextStrokeTransparency = 0
    btn.TextStrokeColor3 = COLORS.Black
    btn.Text = initial and "ON" or "OFF"
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    btn.Activated:Connect(function()
        initial = not initial
        btn.Text = initial and "ON" or "OFF"
        callback(initial)
        UIController.Fire("SettingsChanged", UIController.State)
    end)

    return frame, btn
end

local function createKeybind(parent, action, initial)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-20,0,30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.TextColor3 = COLORS.White
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = COLORS.Black
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = action
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.3,0,1,0)
    button.Position = UDim2.new(0.7,0,0,0)
    button.BackgroundColor3 = COLORS.Bar
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamBold
    button.TextSize = 20
    button.TextColor3 = COLORS.White
    button.TextStrokeTransparency = 0
    button.TextStrokeColor3 = COLORS.Black
    button.Text = initial.Name
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0,6)

    button.Activated:Connect(function()
        waitingForKey = {button=button, action=action}
        button.Text = "..."
    end)

    return frame, button
end

local function createSlider(parent, labelText, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-20,0,40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.TextColor3 = COLORS.White
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = COLORS.Black
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = string.format("%s: %0.2f", labelText, initial)
    label.Parent = frame

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0.15,0,1,0)
    minus.Position = UDim2.new(0.7,0,0,0)
    minus.BackgroundColor3 = COLORS.Bar
    minus.AutoButtonColor = false
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 20
    minus.TextColor3 = COLORS.White
    minus.TextStrokeTransparency = 0
    minus.TextStrokeColor3 = COLORS.Black
    minus.Text = "-"
    minus.Parent = frame
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0,6)

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0.15,0,1,0)
    plus.Position = UDim2.new(0.85,0,0,0)
    plus.BackgroundColor3 = COLORS.Bar
    plus.AutoButtonColor = false
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 20
    plus.TextColor3 = COLORS.White
    plus.TextStrokeTransparency = 0
    plus.TextStrokeColor3 = COLORS.Black
    plus.Text = "+"
    plus.Parent = frame
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0,6)

    local value = initial
    local function updateLabel()
        label.Text = string.format("%s: %0.2f", labelText, value)
        callback(value)
    end

    minus.Activated:Connect(function()
        value = math.clamp(value - 0.1, 0, 1)
        updateLabel()
        UIController.Fire("SettingsChanged", UIController.State)
    end)
    plus.Activated:Connect(function()
        value = math.clamp(value + 0.1, 0, 1)
        updateLabel()
        UIController.Fire("SettingsChanged", UIController.State)
    end)

    updateLabel()
    return frame, label
end

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

local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Text = name
    btn.Size = UDim2.new(0,100,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.TextColor3 = COLORS.White
    btn.TextStrokeColor3 = COLORS.Black
    btn.TextStrokeTransparency = 0
    btn.Activated:Connect(function()
        switchTab(name)
    end)
    return btn
end

buildUI = function()
    mainGui = script.Parent
    mainGui.Name = GUI_NAME
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true
    mainGui.Enabled = false
    mainGui:ClearAllChildren()

    window = Instance.new("Frame")
    window.Size = UDim2.new(0.4,0,0.45,0)
    window.Position = UDim2.new(0.5,0,0.5,0)
    window.AnchorPoint = Vector2.new(0.5,0.5)
    window.BackgroundColor3 = COLORS.Background
    window.BackgroundTransparency = 0.25
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
    closeButton.Position = UDim2.new(1,-5,0,5)
    closeButton.AnchorPoint = Vector2.new(1,0)
    closeButton.BackgroundColor3 = COLORS.Red
    closeButton.Text = "❌"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 24
    closeButton.TextColor3 = COLORS.White
    closeButton.TextStrokeTransparency = 0
    closeButton.TextStrokeColor3 = COLORS.Black
    closeButton.AutoButtonColor = false
    closeButton.Parent = dragBar
    Instance.new("UICorner",closeButton).CornerRadius = UDim.new(0,8)
    tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1,-20,0,40)
    tabBar.Position = UDim2.new(0,10,0,50)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = window
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,10)

    for _,name in ipairs(TAB_ORDER) do
        createTabButton(name).Parent = tabBar
    end

    contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1,-20,1,-120)
    contentFrame.Position = UDim2.new(0,10,0,110)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = window

    -- Audio tab
    local audio = Instance.new("Frame", contentFrame)
    audio.Size = UDim2.new(1,0,1,0)
    audio.BackgroundTransparency = 1
    audio.Visible = false
    local _, musicLabel = createSlider(audio, "Music", UIController.State.MusicVolume or 0.5, function(v)
        UIController.State.MusicVolume = v
    end)
    controlsRefs.MusicLabel = musicLabel
    local _, sfxLabel = createSlider(audio, "SFX", UIController.State.SFXVolume or 0.5, function(v)
        UIController.State.SFXVolume = v
    end)
    controlsRefs.SFXLabel = sfxLabel
    tabFrames.Audio = audio

    -- Display tab
    local display = Instance.new("Frame", contentFrame)
    display.Size = UDim2.new(1,0,1,0)
    display.BackgroundTransparency = 1
    display.Visible = false
    local _, dbgBtn = createToggle(display, "Debug Overlay", UIController.State.DebugEnabled, function(enabled)
        UIController.State.DebugEnabled = enabled
        UIController.Fire("DebugOverlayToggled", enabled)
    end)
    controlsRefs.DebugToggle = dbgBtn
    local _, gfxBtn = createToggle(display, "Graphics High", UIController.State.GraphicsHigh, function(enabled)
        UIController.State.GraphicsHigh = enabled
    end)
    controlsRefs.GraphicsToggle = gfxBtn
    tabFrames.Display = display

    -- Controls tab
    local controls = Instance.new("Frame", contentFrame)
    controls.Size = UDim2.new(1,0,1,0)
    controls.BackgroundTransparency = 1
    controls.Visible = false
    local _, invBtn = createKeybind(controls, "Inventory", UIController.State.Keybinds.Inventory)
    controlsRefs.InventoryKey = invBtn
    local _, shopBtn = createKeybind(controls, "Shop", UIController.State.Keybinds.Shop)
    controlsRefs.ShopKey = shopBtn
    local _, setBtn = createKeybind(controls, "Settings", UIController.State.Keybinds.Settings)
    controlsRefs.SettingsKey = setBtn
    tabFrames.Controls = controls

    settingsState.ActiveTab = nil
    switchTab("Audio")

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

switchTab = function(tabName)
    if settingsState.ActiveTab == tabName then return end
    local oldFrame = tabFrames[settingsState.ActiveTab]
    local newFrame = tabFrames[tabName]
    settingsState.ActiveTab = tabName
    for _,btn in ipairs(tabBar:GetChildren()) do
        if btn:IsA("TextButton") then
            local target = (btn.Text == tabName) and COLORS.Bar or Color3.fromRGB(100,100,100)
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3 = target}):Play()
        end
    end
    if oldFrame then
        TweenService:Create(oldFrame,TweenInfo.new(0.15),{GroupTransparency=1}):Play()
    end
    task.delay(0.15,function()
        for _,f in pairs(tabFrames) do f.Visible=false end
        if newFrame then
            newFrame.Visible=true
            newFrame.GroupTransparency=1
            TweenService:Create(newFrame,TweenInfo.new(0.15),{GroupTransparency=0}):Play()
        end
    end)
end

applyState = function()
    if controlsRefs.MusicLabel then
        controlsRefs.MusicLabel.Text = string.format("Music: %0.2f", UIController.State.MusicVolume or 0)
    end
    if controlsRefs.SFXLabel then
        controlsRefs.SFXLabel.Text = string.format("SFX: %0.2f", UIController.State.SFXVolume or 0)
    end
    if controlsRefs.DebugToggle then
        controlsRefs.DebugToggle.Text = UIController.State.DebugEnabled and "ON" or "OFF"
    end
    if controlsRefs.GraphicsToggle then
        controlsRefs.GraphicsToggle.Text = UIController.State.GraphicsHigh and "ON" or "OFF"
    end
    if controlsRefs.InventoryKey then
        controlsRefs.InventoryKey.Text = UIController.State.Keybinds.Inventory.Name
    end
    if controlsRefs.ShopKey then
        controlsRefs.ShopKey.Text = UIController.State.Keybinds.Shop.Name
    end
    if controlsRefs.SettingsKey then
        controlsRefs.SettingsKey.Text = UIController.State.Keybinds.Settings.Name
    end
end

------------------------------
-- 3. Animation helpers ------
------------------------------
openSettings = function()
    settingsState.Visible = true
    UIController.State.SettingsOpen = true
    UIController.State.LastEvent = "SettingsOpen"
    mainGui.Enabled = true
    window.Visible = true
    window.Size = UDim2.new(0,0,0,0)
    window.Position = UDim2.new(0.5,0,0.5,0)
    window.BackgroundTransparency = 1
    TweenService:Create(window,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Size = UDim2.new(0.4,0,0.45,0),
        Position = UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency = 0.25,
    }):Play()
end

closeSettings = function()
    settingsState.Visible = false
    UIController.State.SettingsOpen = false
    UIController.State.LastEvent = "SettingsClose"
    TweenService:Create(window,TweenInfo.new(0.2),{
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency = 1,
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
    if waitingForKey then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            waitingForKey.button.Text = input.KeyCode.Name
            UIController.State.Keybinds[waitingForKey.action] = input.KeyCode
            waitingForKey = nil
            UIController.Fire("SettingsChanged", UIController.State)
        end
        return
    end
    if gpe then return end
    local setKey = UIController.State.Keybinds and UIController.State.Keybinds.Settings or Enum.KeyCode.O
    if input.KeyCode == setKey then
        toggleSettings()
    elseif input.KeyCode == Enum.KeyCode.Escape and settingsState.Visible then
        closeSettings()
    end
end)

UIController.Events.ToggleSettings.Event:Connect(toggleSettings)
UIController.Events.SettingsChanged.Event:Connect(applyState)

applyState()

------------------------------
-- 5. Debug & Watchdog -------
------------------------------
local function updateDebug()
    debugLabel.Text = string.format(
        "Settings: %s | Music: %.2f | SFX: %.2f",
        tostring(settingsState.Visible),
        UIController.State.MusicVolume or 0,
        UIController.State.SFXVolume or 0
    )
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