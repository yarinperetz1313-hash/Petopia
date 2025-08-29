diff --git a/src/StarterGui/UI/Inventory/Inventory.client.lua b/src/StarterGui/UI/Inventory/Inventory.client.lua
index 269f361e2178152052b4ab0d1810726610dd8a61..3cb9fad8427d7bc96f13a6b697f8bbf364675e13 100644
--- a/src/StarterGui/UI/Inventory/Inventory.client.lua
+++ b/src/StarterGui/UI/Inventory/Inventory.client.lua
@@ -1,7 +1,334 @@
-print("✅ Inventory is working!")
-local gui = script.Parent
-local label = Instance.new("TextLabel")
-label.Size = UDim2.new(1,0,0.2,0)
-label.Text = "INVENTORY PLACEHOLDER"
-label.TextScaled = true
-label.Parent = gui
+--[[
+    Inventory.client.lua
+    Draggable inventory window with 12 slots and animations.
+
+    Sections
+    --------
+    1. Constants & Requires
+    2. State management
+    3. Utility helpers
+    4. UI construction
+    5. Slot logic
+    6. Open/close animations
+    7. Input & event connections
+    8. Debug overlay & fail-safes
+--]]
+
+------------------------------
+-- 1. Constants & Requires --
+------------------------------
+
+local Players = game:GetService("Players")
+local TweenService = game:GetService("TweenService")
+local UserInputService = game:GetService("UserInputService")
+local ReplicatedStorage = game:GetService("ReplicatedStorage")
+
+local LocalPlayer = Players.LocalPlayer
+
+local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
+local UIController = require(ModulesFolder:WaitForChild("UIController"))
+
+local GUI_NAME = "PetopiaInventory"
+
+local COLORS = {
+    Background = Color3.fromRGB(25, 25, 35),
+    Bar = Color3.fromRGB(45, 120, 220),
+    Slot = Color3.fromRGB(40, 40, 60),
+    SlotHover = Color3.fromRGB(60, 60, 90),
+    White = Color3.new(1, 1, 1),
+    Black = Color3.new(0, 0, 0),
+    Grey = Color3.fromRGB(180, 180, 180),
+    Red = Color3.fromRGB(200, 60, 60),
+}
+
+local SLOT_COUNT = 12
+
+---------------------------------------------------------------
+-- 2. State management ----------------------------------------
+---------------------------------------------------------------
+
+local invState = {
+    Visible = false,
+    Slots = {},
+}
+
+local mainGui
+local window
+local dragBar
+local closeButton
+local grid
+local debugLabel
+
+local buildUI
+local openInventory
+local closeInventory
+local toggleInventory
+local ensureGui
+local createSlots
+
+---------------------------------------------------------------
+-- 3. Utility helpers ----------------------------------------
+---------------------------------------------------------------
+
+local dragConnection
+local function makeDraggable(frame, dragHandle)
+    dragHandle.InputBegan:Connect(function(input)
+        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
+            local startPos = frame.Position
+            local dragStart = input.Position
+            if dragConnection then
+                dragConnection:Disconnect()
+            end
+            dragConnection = UserInputService.InputChanged:Connect(function(moveInput)
+                if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
+                    local delta = moveInput.Position - dragStart
+                    frame.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
+                end
+            end)
+        end
+    end)
+
+    dragHandle.InputEnded:Connect(function(input)
+        if dragConnection and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
+            dragConnection:Disconnect()
+            dragConnection = nil
+        end
+    end)
+end
+
+---------------------------------------------------------------
+-- 4. UI construction ----------------------------------------
+---------------------------------------------------------------
+
+buildUI = function()
+    mainGui = Instance.new("ScreenGui")
+    mainGui.Name = GUI_NAME
+    mainGui.ResetOnSpawn = false
+    mainGui.IgnoreGuiInset = true
+    mainGui.Enabled = false
+    mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
+
+    window = Instance.new("Frame")
+    window.Size = UDim2.new(0.55, 0, 0.6, 0)
+    window.Position = UDim2.new(0.225, 0, 0.2, 0)
+    window.BackgroundColor3 = COLORS.Background
+    window.BorderSizePixel = 0
+    window.Visible = false
+    window.Parent = mainGui
+
+    local corner = Instance.new("UICorner")
+    corner.CornerRadius = UDim.new(0, 12)
+    corner.Parent = window
+
+    local shadow = Instance.new("ImageLabel")
+    shadow.ZIndex = -1
+    shadow.BackgroundTransparency = 1
+    shadow.Image = "rbxassetid://1316045217"
+    shadow.ImageColor3 = Color3.new(0, 0, 0)
+    shadow.ImageTransparency = 0.5
+    shadow.ScaleType = Enum.ScaleType.Slice
+    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
+    shadow.Size = UDim2.new(1, 20, 1, 20)
+    shadow.Position = UDim2.new(0, -10, 0, -10)
+    shadow.Parent = window
+
+    dragBar = Instance.new("Frame")
+    dragBar.Size = UDim2.new(1, 0, 0, 50)
+    dragBar.BackgroundColor3 = COLORS.Bar
+    dragBar.BorderSizePixel = 0
+    dragBar.Parent = window
+
+    local barCorner = Instance.new("UICorner")
+    barCorner.CornerRadius = UDim.new(0, 12)
+    barCorner.Parent = dragBar
+
+    local title = Instance.new("TextLabel")
+    title.Size = UDim2.new(1, -60, 1, 0)
+    title.Position = UDim2.new(0, 10, 0, 0)
+    title.BackgroundTransparency = 1
+    title.Text = "🎒 Inventory"
+    title.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
+    title.TextSize = 32
+    title.TextColor3 = COLORS.White
+    title.TextStrokeTransparency = 0
+    title.TextStrokeColor3 = COLORS.Black
+    title.TextXAlignment = Enum.TextXAlignment.Left
+    title.Parent = dragBar
+
+    closeButton = Instance.new("TextButton")
+    closeButton.Size = UDim2.new(0, 40, 0, 40)
+    closeButton.Position = UDim2.new(1, -45, 0.1, 0)
+    closeButton.BackgroundColor3 = COLORS.Red
+    closeButton.Text = "✖"
+    closeButton.FontFace = Font.fromEnum(Enum.Font.GothamBold)
+    closeButton.TextColor3 = COLORS.White
+    closeButton.TextSize = 24
+    closeButton.TextStrokeColor3 = COLORS.Black
+    closeButton.TextStrokeTransparency = 0
+    closeButton.Parent = dragBar
+
+    local closeCorner = Instance.new("UICorner")
+    closeCorner.CornerRadius = UDim.new(0, 8)
+    closeCorner.Parent = closeButton
+
+    closeButton.MouseEnter:Connect(function()
+        TweenService:Create(closeButton, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.Red:lerp(COLORS.White, 0.2) }):Play()
+    end)
+    closeButton.MouseLeave:Connect(function()
+        TweenService:Create(closeButton, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.Red }):Play()
+    end)
+
+    closeButton.Activated:Connect(function()
+        toggleInventory()
+    end)
+
+    grid = Instance.new("Frame")
+    grid.Size = UDim2.new(1, -20, 1, -70)
+    grid.Position = UDim2.new(0, 10, 0, 60)
+    grid.BackgroundTransparency = 1
+    grid.Parent = window
+
+    local layout = Instance.new("UIGridLayout")
+    layout.CellPadding = UDim2.new(0, 10, 0, 10)
+    layout.CellSize = UDim2.new(0.25, -10, 0.25, -10)
+    layout.FillDirectionMaxCells = 4
+    layout.Parent = grid
+
+    debugLabel = Instance.new("TextLabel")
+    debugLabel.Size = UDim2.new(0, 400, 0, 20)
+    debugLabel.Position = UDim2.new(0, 10, 1, -30)
+    debugLabel.BackgroundTransparency = 1
+    debugLabel.Font = Enum.Font.Code
+    debugLabel.TextSize = 14
+    debugLabel.TextXAlignment = Enum.TextXAlignment.Left
+    debugLabel.TextColor3 = COLORS.White
+    debugLabel.TextStrokeTransparency = 0
+    debugLabel.TextStrokeColor3 = COLORS.Black
+    debugLabel.Parent = mainGui
+
+    makeDraggable(window, dragBar)
+    createSlots()
+end
+
+---------------------------------------------------------------
+-- 5. Slot logic ----------------------------------------------
+---------------------------------------------------------------
+
+createSlots = function()
+    invState.Slots = {}
+    for i = 1, SLOT_COUNT do
+        local slot = Instance.new("TextButton")
+        slot.Name = "Slot" .. i
+        slot.BackgroundColor3 = COLORS.Slot
+        slot.Text = "[Empty]"
+        slot.TextColor3 = COLORS.Grey
+        slot.TextStrokeColor3 = COLORS.Black
+        slot.TextStrokeTransparency = 0
+        slot.FontFace = Font.fromEnum(Enum.Font.GothamBold)
+        slot.TextSize = 18
+        slot.AutoButtonColor = false
+
+        local corner = Instance.new("UICorner")
+        corner.CornerRadius = UDim.new(0, 6)
+        corner.Parent = slot
+
+        slot.MouseEnter:Connect(function()
+            TweenService:Create(slot, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.SlotHover }):Play()
+        end)
+        slot.MouseLeave:Connect(function()
+            TweenService:Create(slot, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.Slot }):Play()
+        end)
+
+        slot.Activated:Connect(function()
+            print("Clicked slot", i)
+        end)
+
+        slot.Parent = grid
+        table.insert(invState.Slots, slot)
+    end
+end
+
+---------------------------------------------------------------
+-- 6. Open/close animations ----------------------------------
+---------------------------------------------------------------
+
+openInventory = function()
+    invState.Visible = true
+    mainGui.Enabled = true
+    window.Visible = true
+    window.Size = UDim2.new(0, 0, 0, 0)
+    window.Position = UDim2.new(0.5, 0, 0.5, 0)
+    TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
+        Size = UDim2.new(0.55, 0, 0.6, 0),
+        Position = UDim2.new(0.225, 0, 0.2, 0),
+    }):Play()
+end
+
+closeInventory = function()
+    invState.Visible = false
+    TweenService:Create(window, TweenInfo.new(0.2), {
+        Size = UDim2.new(0, 0, 0, 0),
+        Position = UDim2.new(0.5, 0, 0.5, 0),
+    }):Play()
+    task.delay(0.2, function()
+        window.Visible = false
+        mainGui.Enabled = false
+    end)
+end
+
+toggleInventory = function()
+    if invState.Visible then
+        closeInventory()
+    else
+        openInventory()
+    end
+end
+
+---------------------------------------------------------------
+-- 7. Input & events -----------------------------------------
+---------------------------------------------------------------
+
+UserInputService.InputBegan:Connect(function(input, gpe)
+    if gpe then
+        return
+    end
+    if input.KeyCode == Enum.KeyCode.I then
+        toggleInventory()
+    end
+end)
+
+UIController.Events.ToggleInventory.Event:Connect(toggleInventory)
+
+---------------------------------------------------------------
+-- 8. Debug overlay & fail-safes ------------------------------
+---------------------------------------------------------------
+
+local function updateDebug()
+    debugLabel.Text = string.format("Inventory: %s | Slots: %d", tostring(invState.Visible), #invState.Slots)
+end
+
+task.spawn(function()
+    while true do
+        task.wait(0.5)
+        if debugLabel then
+            updateDebug()
+        end
+    end
+end)
+
+ensureGui = function()
+    if not mainGui or not mainGui.Parent then
+        buildUI()
+    end
+end
+
+task.spawn(function()
+    while true do
+        task.wait(5)
+        ensureGui()
+    end
+end)
+
+-- initialize
+buildUI()
+
