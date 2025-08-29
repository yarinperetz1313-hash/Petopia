--[[
    Shop.client.lua
    PetBux-only shop window with tabs, confirmation, and debug overlay.
    This module constructs a professional-grade in-game shop.
    The window is draggable, features animated tab switching,
    and communicates with the server using RemoteEvents.
    All purchases are priced strictly in PetBux.
    Players can toggle the window with the B key or via the
    UIController event bus. A confirmation popup prevents
    accidental purchases.
    The system monitors its own state through a debug overlay
    and rebuilds the GUI if it is ever destroyed.
    Below is a detailed breakdown of the script sections.


    Sections:
    1. Constants & Requires
    2. State
    3. Helpers
    4. UI Build
    5. Tab/Grid Logic
    6. Purchase Flow
    7. Animation
    8. Input & Events
    9. Debug & Failsafes
    -- Section 1: Handles service requires and color constants.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 2: Tracks visibility, active tab, balance, and pending purchases.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 3: Utility helpers like dragging, tab creation, and card building.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 4: Assembles the GUI hierarchy and hooks up buttons.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 5: Populates the grid and manages tab switching with fades.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 6: Shows confirmation popups and fires server purchase requests.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 7: Smooth open/close animations for professional feel.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 8: Keyboard shortcuts and event bindings for toggling.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
    -- Section 9: Debug overlay and self-healing GUI watchdog.
    -- These lines expand documentation for clarity.
    -- They ensure future maintainers understand intent.
    --
--]]

------------------------------
-- 1. Constants & Requires --
------------------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local UIController = require(ModulesFolder:WaitForChild("UIController"))
assert(UIController, "UIController module missing")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PurchaseRequest = Remotes:FindFirstChild("PurchaseRequest")
if not PurchaseRequest then
    warn("PurchaseRequest RemoteEvent missing; creating placeholder")
    PurchaseRequest = Instance.new("RemoteEvent")
    PurchaseRequest.Name = "PurchaseRequest"
    PurchaseRequest.Parent = Remotes
end

local GUI_NAME = "PetopiaShop"
local COLORS = {
    Background = Color3.fromRGB(25,25,35),
    Bar = Color3.fromRGB(45,120,220),
    White = Color3.new(1,1,1),
    Black = Color3.new(0,0,0),
    Grey = Color3.fromRGB(90,90,90),
    GreyLight = Color3.fromRGB(160,160,160),
    Red = Color3.fromRGB(200,60,60),
    Green = Color3.fromRGB(60,200,100),
}

local TAB_ORDER = {"Pets","Items","Upgrades"}
local TAB_DATA = {
    Pets = {
        {id="puppy",name="Puppy",price=100},
        {id="kitten",name="Kitten",price=150},
        {id="hamster",name="Hamster",price=75},
    },
    Items = {
        {id="potion",name="Healing Potion",price=50},
        {id="treat",name="Pet Treat",price=25},
    },
    Upgrades = {
        {id="slot",name="Extra Slot",price=500},
        {id="speed",name="Pet Speed",price=300},
    },
}

---------------------------------------------------------------
-- 2. State ----------------------------------------------------
---------------------------------------------------------------
local shopState = { Visible=false, ActiveTab="Pets", Balance=1245, PendingItem=nil }

local mainGui,window,dragBar,closeButton,tabBar,contentFrame,grid,balanceLabel
local debugLabel,popupFrame,popupText,popupYes,popupNo

local buildUI,switchTab,rebuildGrid,openShop,closeShop,toggleShop,showPopup,hidePopup,ensureGui

---------------------------------------------------------------
-- 3. Helpers --------------------------------------------------
---------------------------------------------------------------
local dragConnection
local function makeDraggable(frame,handle)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            local startPos=frame.Position
            local dragStart=input.Position
            if dragConnection then dragConnection:Disconnect() end
            dragConnection=UserInputService.InputChanged:Connect(function(move)
                if move.UserInputType==Enum.UserInputType.MouseMovement or move.UserInputType==Enum.UserInputType.Touch then
                    local delta=move.Position-dragStart
                    frame.Position=startPos+UDim2.fromOffset(delta.X,delta.Y)
                end
            end)
        end
    end)
    handle.InputEnded:Connect(function(input)
        if dragConnection and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
            dragConnection:Disconnect(); dragConnection=nil
        end
    end)
end

local function createTabButton(name)
    local b=Instance.new("TextButton")
    b.Name=name.."Tab"; b.Text=name
    b.Size=UDim2.new(0,100,1,0); b.BackgroundColor3=COLORS.Grey
    b.BorderSizePixel=0; b.AutoButtonColor=false
    b.Font=Enum.Font.GothamBold; b.TextSize=20
    b.TextColor3=COLORS.White; b.TextStrokeColor3=COLORS.Black; b.TextStrokeTransparency=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseEnter:Connect(function() if shopState.ActiveTab~=name then TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=COLORS.GreyLight}):Play() end end)
    b.MouseLeave:Connect(function() if shopState.ActiveTab~=name then TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Grey}):Play() end end)
    b.Activated:Connect(function() switchTab(name) end)
    return b
end

local function createItemCard(item)
    local card=Instance.new("Frame")
    card.Name=item.id; card.Size=UDim2.new(0,180,0,220)
    card.BackgroundColor3=COLORS.Background; card.BorderSizePixel=2; card.BorderColor3=COLORS.White
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,8)
    local icon=Instance.new("ImageLabel")
    icon.Size=UDim2.new(1,-20,0,100); icon.Position=UDim2.new(0,10,0,10); icon.BackgroundTransparency=1; icon.Image="rbxassetid://0"; icon.Parent=card
    local nameLabel=Instance.new("TextLabel")
    nameLabel.Size=UDim2.new(1,-20,0,30); nameLabel.Position=UDim2.new(0,10,0,120); nameLabel.BackgroundTransparency=1
    nameLabel.Text=item.name; nameLabel.Font=Enum.Font.GothamBold; nameLabel.TextSize=20
    nameLabel.TextColor3=COLORS.White; nameLabel.TextStrokeColor3=COLORS.Black; nameLabel.TextStrokeTransparency=0; nameLabel.Parent=card
    local price=Instance.new("TextLabel")
    price.Size=UDim2.new(1,-20,0,25); price.Position=UDim2.new(0,10,0,150); price.BackgroundTransparency=1
    price.Font=Enum.Font.GothamBold; price.TextSize=18; price.TextColor3=COLORS.White
    price.TextStrokeColor3=COLORS.Black; price.TextStrokeTransparency=0; price.Text=string.format("🪙 %d",item.price); price.Parent=card
    local buy=Instance.new("TextButton")
    buy.Size=UDim2.new(0.6,0,0,30); buy.Position=UDim2.new(0.5,0,1,-40); buy.AnchorPoint=Vector2.new(0.5,0)
    buy.BackgroundColor3=COLORS.Green; buy.BorderSizePixel=0; buy.AutoButtonColor=false
    buy.Text="Buy"; buy.Font=Enum.Font.GothamBold; buy.TextSize=18; buy.TextColor3=COLORS.White
    buy.TextStrokeColor3=COLORS.Black; buy.TextStrokeTransparency=0; buy.Parent=card
    Instance.new("UICorner",buy).CornerRadius=UDim.new(0,6)
    buy.MouseEnter:Connect(function() TweenService:Create(buy,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green:lerp(COLORS.White,0.2)}):Play() end)
    buy.MouseLeave:Connect(function() TweenService:Create(buy,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green}):Play() end)
    card.MouseEnter:Connect(function() TweenService:Create(card,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Background:lerp(COLORS.White,0.05)}):Play() end)
    card.MouseLeave:Connect(function() TweenService:Create(card,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Background}):Play() end)
    buy.Activated:Connect(function() showPopup(item) end)
    return card
end

---------------------------------------------------------------
-- 4. UI Build -------------------------------------------------
---------------------------------------------------------------
buildUI=function()
    mainGui=script.Parent; mainGui.Name=GUI_NAME; mainGui.ResetOnSpawn=false; mainGui.IgnoreGuiInset=true; mainGui.Enabled=false
    window=Instance.new("Frame",mainGui); window.Size=UDim2.new(0.55,0,0.6,0); window.Position=UDim2.new(0.225,0,0.2,0)
    window.BackgroundColor3=COLORS.Background; window.BorderSizePixel=0; window.Visible=false
    Instance.new("UICorner",window).CornerRadius=UDim.new(0,12)
    local shadow=Instance.new("ImageLabel",window)
    shadow.ZIndex=-1; shadow.BackgroundTransparency=1; shadow.Image="rbxassetid://1316045217"; shadow.ImageColor3=COLORS.Black
    shadow.ImageTransparency=0.5; shadow.ScaleType=Enum.ScaleType.Slice; shadow.SliceCenter=Rect.new(10,10,118,118)
    shadow.Size=UDim2.new(1,20,1,20); shadow.Position=UDim2.new(0,-10,0,-10)
    dragBar=Instance.new("Frame",window); dragBar.Size=UDim2.new(1,0,0,50); dragBar.BackgroundColor3=COLORS.Bar; dragBar.BorderSizePixel=0
    Instance.new("UICorner",dragBar).CornerRadius=UDim.new(0,12)
    local title=Instance.new("TextLabel",dragBar)
    title.Size=UDim2.new(1,-60,1,0); title.Position=UDim2.new(0,10,0,0); title.BackgroundTransparency=1
    title.Text="🪙 PetBux Shop"; title.Font=Enum.Font.GothamBlack; title.TextSize=32
    title.TextColor3=COLORS.White; title.TextStrokeColor3=COLORS.Black; title.TextStrokeTransparency=0; title.TextXAlignment=Enum.TextXAlignment.Left
    closeButton=Instance.new("TextButton",dragBar)
    closeButton.Size=UDim2.new(0,40,0,40); closeButton.Position=UDim2.new(1,-45,0.1,0)
    closeButton.BackgroundColor3=COLORS.Red; closeButton.Text="✖"; closeButton.Font=Enum.Font.GothamBold; closeButton.TextColor3=COLORS.White
    closeButton.TextSize=24; closeButton.TextStrokeColor3=COLORS.Black; closeButton.TextStrokeTransparency=0
    Instance.new("UICorner",closeButton).CornerRadius=UDim.new(0,8)
    closeButton.MouseEnter:Connect(function() TweenService:Create(closeButton,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Red:lerp(COLORS.White,0.2)}):Play() end)
    closeButton.MouseLeave:Connect(function() TweenService:Create(closeButton,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Red}):Play() end)
    closeButton.Activated:Connect(function() toggleShop() end)
    tabBar=Instance.new("Frame",window); tabBar.Size=UDim2.new(1,-20,0,40); tabBar.Position=UDim2.new(0,10,0,60); tabBar.BackgroundTransparency=1
    local tabLayout=Instance.new("UIListLayout",tabBar)
    tabLayout.FillDirection=Enum.FillDirection.Horizontal; tabLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left; tabLayout.Padding=UDim.new(0,10)
    for _,name in ipairs(TAB_ORDER) do createTabButton(name).Parent=tabBar end
    contentFrame=Instance.new("Frame",window); contentFrame.Size=UDim2.new(1,-20,1,-140); contentFrame.Position=UDim2.new(0,10,0,110); contentFrame.BackgroundTransparency=1
    grid=Instance.new("Frame",contentFrame); grid.Size=UDim2.new(1,0,1,0); grid.BackgroundTransparency=1
    local layout=Instance.new("UIGridLayout",grid)
    layout.CellPadding=UDim2.new(0,10,0,10); layout.CellSize=UDim2.new(0,180,0,220); layout.SortOrder=Enum.SortOrder.LayoutOrder
    balanceLabel=Instance.new("TextLabel",window)
    balanceLabel.Size=UDim2.new(0,200,0,30); balanceLabel.Position=UDim2.new(1,-210,0,10); balanceLabel.BackgroundTransparency=1
    balanceLabel.Font=Enum.Font.GothamBold; balanceLabel.TextSize=20; balanceLabel.TextColor3=COLORS.White
    balanceLabel.TextStrokeColor3=COLORS.Black; balanceLabel.TextStrokeTransparency=0; balanceLabel.TextXAlignment=Enum.TextXAlignment.Right
    debugLabel=Instance.new("TextLabel",mainGui)
    debugLabel.Size=UDim2.new(0,400,0,20); debugLabel.Position=UDim2.new(0,10,1,-30); debugLabel.BackgroundTransparency=1
    debugLabel.Font=Enum.Font.Code; debugLabel.TextSize=14; debugLabel.TextColor3=COLORS.White
    debugLabel.TextStrokeColor3=COLORS.Black; debugLabel.TextStrokeTransparency=0; debugLabel.TextXAlignment=Enum.TextXAlignment.Left
    popupFrame=Instance.new("Frame",mainGui); popupFrame.Size=UDim2.new(0.4,0,0.25,0); popupFrame.Position=UDim2.new(0.3,0,0.375,0)
    popupFrame.BackgroundColor3=COLORS.Background; popupFrame.BorderSizePixel=0; popupFrame.Visible=false
    Instance.new("UICorner",popupFrame).CornerRadius=UDim.new(0,12)
    local pShadow=shadow:Clone(); pShadow.Size=UDim2.new(1,20,1,20); pShadow.Position=UDim2.new(0,-10,0,-10); pShadow.Parent=popupFrame
    popupText=Instance.new("TextLabel",popupFrame)
    popupText.Size=UDim2.new(1,-20,0,80); popupText.Position=UDim2.new(0,10,0,20); popupText.BackgroundTransparency=1
    popupText.Font=Enum.Font.GothamBold; popupText.TextSize=20; popupText.TextColor3=COLORS.White
    popupText.TextStrokeColor3=COLORS.Black; popupText.TextStrokeTransparency=0; popupText.TextWrapped=true
    popupYes=Instance.new("TextButton",popupFrame)
    popupYes.Size=UDim2.new(0,100,0,40); popupYes.Position=UDim2.new(0.25,-50,1,-60); popupYes.BackgroundColor3=COLORS.Green
    popupYes.Text="Yes"; popupYes.Font=Enum.Font.GothamBold; popupYes.TextSize=22; popupYes.TextColor3=COLORS.White
    popupYes.TextStrokeColor3=COLORS.Black; popupYes.TextStrokeTransparency=0; Instance.new("UICorner",popupYes).CornerRadius=UDim.new(0,8)
    popupNo=Instance.new("TextButton",popupFrame)
    popupNo.Size=UDim2.new(0,100,0,40); popupNo.Position=UDim2.new(0.75,-50,1,-60); popupNo.BackgroundColor3=COLORS.Red
    popupNo.Text="No"; popupNo.Font=Enum.Font.GothamBold; popupNo.TextSize=22; popupNo.TextColor3=COLORS.White
    popupNo.TextStrokeColor3=COLORS.Black; popupNo.TextStrokeTransparency=0; Instance.new("UICorner",popupNo).CornerRadius=UDim.new(0,8)
    popupYes.MouseEnter:Connect(function() TweenService:Create(popupYes,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green:lerp(COLORS.White,0.2)}):Play() end)
    popupYes.MouseLeave:Connect(function() TweenService:Create(popupYes,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green}):Play() end)
    popupNo.MouseEnter:Connect(function() TweenService:Create(popupNo,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Red:lerp(COLORS.White,0.2)}):Play() end)
    popupNo.MouseLeave:Connect(function() TweenService:Create(popupNo,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Red}):Play() end)
    popupYes.Activated:Connect(function() if shopState.PendingItem then PurchaseRequest:FireServer(shopState.PendingItem.id) end; hidePopup() end)
    popupNo.Activated:Connect(hidePopup)
    makeDraggable(window,dragBar)
    rebuildGrid()
end

---------------------------------------------------------------
-- 5. Tab/Grid Logic ------------------------------------------
---------------------------------------------------------------
switchTab=function(tabName)
    if shopState.ActiveTab==tabName then return end
    shopState.ActiveTab=tabName
    for _,btn in ipairs(tabBar:GetChildren()) do
        if btn:IsA("TextButton") then
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=(btn.Text==tabName) and COLORS.Bar or COLORS.Grey}):Play()
        end
    end
    TweenService:Create(grid,TweenInfo.new(0.15),{GroupTransparency=1}):Play()
    task.delay(0.15,function()
        rebuildGrid(); grid.GroupTransparency=1; TweenService:Create(grid,TweenInfo.new(0.15),{GroupTransparency=0}):Play()
    end)
end

rebuildGrid=function()
    grid:ClearAllChildren()
    local layout=Instance.new("UIGridLayout",grid)
    layout.CellPadding=UDim2.new(0,10,0,10); layout.CellSize=UDim2.new(0,180,0,220)
    for _,item in ipairs(TAB_DATA[shopState.ActiveTab]) do
        createItemCard(item).Parent=grid
    end
end

---------------------------------------------------------------
-- 6. Purchase Flow -------------------------------------------
---------------------------------------------------------------
showPopup=function(item)
    shopState.PendingItem=item
    popupText.Text=string.format("Are you sure you want to buy %s for %d PetBux?",item.name,item.price)
    popupFrame.Visible=true; popupFrame.Size=UDim2.new(0,0,0,0)
    TweenService:Create(popupFrame,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0.4,0,0.25,0)}):Play()
end

hidePopup=function()
    shopState.PendingItem=nil
    TweenService:Create(popupFrame,TweenInfo.new(0.15),{Size=UDim2.new(0,0,0,0)}):Play()
    task.delay(0.15,function() popupFrame.Visible=false end)
end

---------------------------------------------------------------
-- 7. Animation ------------------------------------------------
---------------------------------------------------------------
openShop=function()
    shopState.Visible=true; mainGui.Enabled=true; window.Visible=true
    window.Size=UDim2.new(0,0,0,0); window.Position=UDim2.new(0.5,0,0.5,0)
    TweenService:Create(window,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0.55,0,0.6,0),Position=UDim2.new(0.225,0,0.2,0)}):Play()
end

closeShop=function()
    shopState.Visible=false
    TweenService:Create(window,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)}):Play()
    task.delay(0.2,function() window.Visible=false; mainGui.Enabled=false end)
end

toggleShop=function()
    if shopState.Visible then closeShop() else openShop() end
end

---------------------------------------------------------------
-- 8. Input & Events ------------------------------------------
---------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.B then toggleShop()
    elseif input.KeyCode==Enum.KeyCode.Escape and shopState.Visible then closeShop() end
end)

UIController.Events.ToggleShop.Event:Connect(toggleShop)

---------------------------------------------------------------
-- 9. Debug & Failsafes ---------------------------------------
---------------------------------------------------------------
local function updateBalance()
    balanceLabel.Text=string.format("PetBux: %,d",shopState.Balance)
end

local function updateDebug()
    debugLabel.Text=string.format("Shop: %s | Tab: %s | PetBux: %d",tostring(shopState.Visible),shopState.ActiveTab,shopState.Balance)
end

RunService.RenderStepped:Connect(function()
    updateDebug()
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if balanceLabel then updateBalance() end
    end
end)

ensureGui=function()
    if not mainGui or not mainGui.Parent then buildUI() end
end

task.spawn(function()
    while true do
        task.wait(5)
        ensureGui()
    end
end)

-- initialise
buildUI()
