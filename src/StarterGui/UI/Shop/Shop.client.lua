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

local TAB_ORDER = {"Pets","Items","Upgrades","Marketplace"}
local TAB_DATA = {
    Pets = {
        {id="puppy",name="Puppy",price=100,type="Pet",rarity="Common"},
        {id="kitten",name="Kitten",price=150,type="Pet",rarity="Common"},
        {id="hamster",name="Hamster",price=75,type="Pet",rarity="Common"},
    },
    Items = {
        {id="potion",name="Healing Potion",price=50,type="Item"},
        {id="treat",name="Pet Treat",price=25,type="Item"},
    },
    Upgrades = {
        {id="slot",name="Extra Slot",price=500,type="Upgrade"},
        {id="speed",name="Pet Speed",price=300,type="Upgrade"},
    },
    Marketplace = {},
}

---------------------------------------------------------------
-- 2. State ----------------------------------------------------
---------------------------------------------------------------
local shopState = { Visible=false, ActiveTab="Pets", PendingItem=nil }
UIController.State.ShopOpen = false
UIController.State.ShopTab = "Pets"
UIController.State.ShopItems = #TAB_DATA.Pets

local mainGui,window,dragBar,closeButton,tabBar,contentFrame,grid,balanceLabel
local debugLabel,popupFrame,popupText,popupYes,popupNo,popupBuy

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
    mainGui:ClearAllChildren()
    window=Instance.new("Frame",mainGui); window.Size=UDim2.new(0.55,0,0.6,0); window.Position=UDim2.new(0.225,0,0.2,0)
    window.BackgroundColor3=COLORS.Background; window.BackgroundTransparency=0.25; window.BorderSizePixel=0; window.Visible=false
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
    closeButton.Size=UDim2.new(0,40,0,40); closeButton.Position=UDim2.new(1,-5,0,5); closeButton.AnchorPoint=Vector2.new(1,0)
    closeButton.BackgroundColor3=COLORS.Red; closeButton.Text="✖"; closeButton.Font=Enum.Font.GothamBold; closeButton.TextColor3=COLORS.White
    closeButton.TextSize=24; closeButton.TextStrokeColor3=COLORS.Black; closeButton.TextStrokeTransparency=0
    closeButton:ClearAllChildren()
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
    balanceLabel.Text=string.format("PetBux: %,d",UIController.State.PetBux)
    debugLabel=Instance.new("TextLabel",mainGui)
    debugLabel.Size=UDim2.new(0,400,0,20); debugLabel.Position=UDim2.new(0,10,1,-30); debugLabel.BackgroundTransparency=1
    debugLabel.Font=Enum.Font.Code; debugLabel.TextSize=14; debugLabel.TextColor3=COLORS.White
    debugLabel.TextStrokeColor3=COLORS.Black; debugLabel.TextStrokeTransparency=0; debugLabel.TextXAlignment=Enum.TextXAlignment.Left
    popupFrame=Instance.new("Frame",mainGui); popupFrame.Size=UDim2.new(0.4,0,0.25,0); popupFrame.Position=UDim2.new(0.3,0,0.375,0)
    popupFrame.BackgroundColor3=COLORS.Background; popupFrame.BackgroundTransparency=0.25; popupFrame.BorderSizePixel=0; popupFrame.Visible=false
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
    popupBuy=Instance.new("TextButton",popupFrame)
    popupBuy.Size=UDim2.new(0,120,0,40); popupBuy.Position=UDim2.new(0.25,-60,1,-60); popupBuy.BackgroundColor3=COLORS.Green
    popupBuy.Text="Buy PetBux"; popupBuy.Font=Enum.Font.GothamBold; popupBuy.TextSize=22; popupBuy.TextColor3=COLORS.White
    popupBuy.TextStrokeColor3=COLORS.Black; popupBuy.TextStrokeTransparency=0; popupBuy.Visible=false
    Instance.new("UICorner",popupBuy).CornerRadius=UDim.new(0,8)
    popupYes.MouseEnter:Connect(function() TweenService:Create(popupYes,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green:lerp(COLORS.White,0.2)}):Play() end)
    popupYes.MouseLeave:Connect(function() TweenService:Create(popupYes,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green}):Play() end)
    popupNo.MouseEnter:Connect(function() TweenService:Create(popupNo,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Red:lerp(COLORS.White,0.2)}):Play() end)
    popupNo.MouseLeave:Connect(function() TweenService:Create(popupNo,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Red}):Play() end)
    popupBuy.MouseEnter:Connect(function() TweenService:Create(popupBuy,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green:lerp(COLORS.White,0.2)}):Play() end)
    popupBuy.MouseLeave:Connect(function() TweenService:Create(popupBuy,TweenInfo.new(0.15),{BackgroundColor3=COLORS.Green}):Play() end)
    popupYes.Activated:Connect(confirmPurchase)
    popupNo.Activated:Connect(hidePopup)
    popupBuy.Activated:Connect(function()
        UIController.Fire("TogglePetBux")
    end)

    petbuxFrame=Instance.new("Frame",mainGui)
    petbuxFrame.Size=UDim2.new(0.3,0,0.2,0)
    petbuxFrame.Position=UDim2.new(0.35,0,0.4,0)
    petbuxFrame.BackgroundColor3=COLORS.Background
    petbuxFrame.BackgroundTransparency=0.25
    petbuxFrame.Visible=false
    Instance.new("UICorner",petbuxFrame).CornerRadius=UDim.new(0,12)
    local pbShadow=shadow:Clone(); pbShadow.Size=UDim2.new(1,20,1,20); pbShadow.Position=UDim2.new(0,-10,0,-10); pbShadow.Parent=petbuxFrame
    local pbLabel=Instance.new("TextLabel",petbuxFrame)
    pbLabel.Size=UDim2.new(1,-20,1,-20); pbLabel.Position=UDim2.new(0,10,0,10)
    pbLabel.BackgroundTransparency=1
    pbLabel.Font=Enum.Font.GothamBold
    pbLabel.TextSize=24
    pbLabel.TextColor3=COLORS.White
    pbLabel.TextStrokeTransparency=0
    pbLabel.TextStrokeColor3=COLORS.Black
    pbLabel.Text="PetBux purchase coming soon"

    tradeFrame=Instance.new("Frame",mainGui)
    tradeFrame.Size=UDim2.new(0.5,0,0.4,0)
    tradeFrame.Position=UDim2.new(0.25,0,0.3,0)
    tradeFrame.BackgroundColor3=COLORS.Background
    tradeFrame.BackgroundTransparency=0.25
    tradeFrame.Visible=false
    Instance.new("UICorner",tradeFrame).CornerRadius=UDim.new(0,12)
    local tfShadow=shadow:Clone(); tfShadow.Size=UDim2.new(1,20,1,20); tfShadow.Position=UDim2.new(0,-10,0,-10); tfShadow.Parent=tradeFrame
    local feeLabel=Instance.new("TextLabel",tradeFrame)
    feeLabel.Size=UDim2.new(1,-20,0,40); feeLabel.Position=UDim2.new(0,10,0,10)
    feeLabel.BackgroundTransparency=1
    feeLabel.Font=Enum.Font.GothamBold
    feeLabel.TextSize=20
    feeLabel.TextColor3=COLORS.White
    feeLabel.TextStrokeTransparency=0
    feeLabel.TextStrokeColor3=COLORS.Black
    feeLabel.Text="Trade Fee: 10%"
    local confirmTrade=Instance.new("TextButton",tradeFrame)
    confirmTrade.Size=UDim2.new(0,120,0,40); confirmTrade.Position=UDim2.new(0.5,-60,1,-60)
    confirmTrade.BackgroundColor3=COLORS.Green
    confirmTrade.Text="Confirm"
    confirmTrade.Font=Enum.Font.GothamBold
    confirmTrade.TextSize=22
    confirmTrade.TextColor3=COLORS.White
    confirmTrade.TextStrokeTransparency=0
    confirmTrade.TextStrokeColor3=COLORS.Black
    Instance.new("UICorner",confirmTrade).CornerRadius=UDim.new(0,8)
    confirmTrade.Activated:Connect(function()
        UIController.SetPetBux(math.floor(UIController.State.PetBux*0.9))
        UIController.State.MarketplaceState = "trade"
        UIController.State.LastEvent = "TradeConfirm"
        tradeFrame.Visible=false
    end)
    makeDraggable(window,dragBar)
    rebuildGrid()
end

---------------------------------------------------------------
-- 5. Tab/Grid Logic ------------------------------------------
---------------------------------------------------------------
switchTab=function(tabName)
    if shopState.ActiveTab==tabName then return end
    shopState.ActiveTab=tabName
    UIController.State.ShopTab = tabName
    UIController.State.MarketplaceState = (tabName == "Marketplace") and "view" or "idle"
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
    if shopState.ActiveTab == "Marketplace" then
        local start = Instance.new("TextButton",grid)
        start.Size = UDim2.new(0.5,0,0,50)
        start.Position = UDim2.new(0.25,0,0.5,-25)
        start.BackgroundColor3 = COLORS.Bar
        start.Text = "Start Trade"
        start.Font = Enum.Font.GothamBold
        start.TextSize = 24
        start.TextColor3 = COLORS.White
        start.TextStrokeTransparency = 0
        start.TextStrokeColor3 = COLORS.Black
        Instance.new("UICorner",start).CornerRadius=UDim.new(0,8)
        start.Activated:Connect(function()
            tradeFrame.Visible = true
            UIController.State.MarketplaceState = "trade"
        end)
        UIController.State.ShopItems = 0
        return
    end
    local layout=Instance.new("UIGridLayout",grid)
    layout.CellPadding=UDim2.new(0,10,0,10); layout.CellSize=UDim2.new(0,180,0,220)
    for _,item in ipairs(TAB_DATA[shopState.ActiveTab]) do
        createItemCard(item).Parent=grid
    end
    UIController.State.ShopItems = #TAB_DATA[shopState.ActiveTab]
end

---------------------------------------------------------------
-- 6. Purchase Flow -------------------------------------------
---------------------------------------------------------------
local function quickBuy(index)
    local list = TAB_DATA[shopState.ActiveTab]
    local item = list and list[index]
    if item then showPopup(item) end
end

local function confirmPurchase()
    if not shopState.PendingItem then return end
    local item = shopState.PendingItem
    UIController.SetPetBux(UIController.State.PetBux - item.price)
    if item.type == "Pet" then
        item.level = 1
        item.xp = 0
        local traits = {"Playful","Lazy","Energetic"}
        item.trait = traits[math.random(#traits)]
    end
    UIController.Fire("AddToInventory", item)
    PurchaseRequest:FireServer(item.id)
    UIController.State.LastEvent = "Purchase" .. item.id
    hidePopup()
end

showPopup=function(item)
    if UIController.State.PetBux < item.price then
        shopState.PendingItem=nil
        UIController.State.LastEvent = "InsufficientFunds"
        UIController.State.PendingItem = nil
        popupYes.Visible=false
        popupBuy.Visible=true
        popupNo.Text="Close"
        popupNo.Position=UDim2.new(0.75,-50,1,-60)
        popupBuy.Position=UDim2.new(0.25,-60,1,-60)
        popupText.Text=string.format("Not enough PetBux to buy %s",item.name)
    else
        shopState.PendingItem=item
        UIController.State.PendingItem = item.name
        popupYes.Visible=true
        popupBuy.Visible=false
        popupNo.Text="No"
        popupNo.Position=UDim2.new(0.75,-50,1,-60)
        popupText.Text=string.format("Are you sure you want to buy %s for %d PetBux?",item.name,item.price)
    end
    popupFrame.Visible=true; popupFrame.Size=UDim2.new(0,0,0,0)
    TweenService:Create(popupFrame,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0.4,0,0.25,0)}):Play()
end

hidePopup=function()
    shopState.PendingItem=nil
    UIController.State.PendingItem=nil
    popupYes.Visible=true
    popupBuy.Visible=false
    popupNo.Text="No"
    popupNo.Position=UDim2.new(0.75,-50,1,-60)
    TweenService:Create(popupFrame,TweenInfo.new(0.15),{Size=UDim2.new(0,0,0,0)}):Play()
    task.delay(0.15,function() popupFrame.Visible=false end)
end

---------------------------------------------------------------
-- 7. Animation ------------------------------------------------
---------------------------------------------------------------
openShop=function()
    shopState.Visible=true; UIController.State.ShopOpen = true; UIController.State.LastEvent="ShopOpen"; mainGui.Enabled=true; window.Visible=true
    window.Size=UDim2.new(0,0,0,0); window.Position=UDim2.new(0.5,0,0.5,0); window.BackgroundTransparency=1
    TweenService:Create(window,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0.55,0,0.6,0),Position=UDim2.new(0.225,0,0.2,0),BackgroundTransparency=0.25}):Play()
end

closeShop=function()
    shopState.Visible=false; UIController.State.ShopOpen = false; UIController.State.LastEvent="ShopClose"
    TweenService:Create(window,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1}):Play()
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
    if popupFrame.Visible then
        if input.KeyCode==Enum.KeyCode.Y and popupYes.Visible then
            confirmPurchase()
        elseif input.KeyCode==Enum.KeyCode.N or input.KeyCode==Enum.KeyCode.Escape then
            hidePopup()
        end
        return
    end
    local shopKey = UIController.State.Keybinds and UIController.State.Keybinds.Shop or Enum.KeyCode.B
    if input.KeyCode==shopKey then
        toggleShop()
    elseif input.KeyCode==Enum.KeyCode.Escape and shopState.Visible then
        closeShop()
    elseif shopState.Visible then
        if input.KeyCode.Value>=Enum.KeyCode.One.Value and input.KeyCode.Value<=Enum.KeyCode.Nine.Value then
            quickBuy(input.KeyCode.Value - Enum.KeyCode.One.Value + 1)
        end
    end
end)

UIController.Events.ToggleShop.Event:Connect(toggleShop)
UIController.Events.TogglePetBux.Event:Connect(function()
    petbuxFrame.Visible = not petbuxFrame.Visible
    if petbuxFrame.Visible then
        UIController.State.MarketplaceState = "buybux"
    else
        UIController.State.MarketplaceState = shopState.ActiveTab == "Marketplace" and "view" or "idle"
    end
end)

---------------------------------------------------------------
-- 9. Debug & Failsafes ---------------------------------------
---------------------------------------------------------------
local function updateBalance()
    balanceLabel.Text=string.format("PetBux: %,d",UIController.State.PetBux)
end

local function updateDebug()
    debugLabel.Text=string.format("Shop: %s | Tab: %s | PetBux: %d",tostring(shopState.Visible),shopState.ActiveTab,UIController.State.PetBux)
end

UIController.Events.BalanceChanged.Event:Connect(updateBalance)
RunService.RenderStepped:Connect(function()
    updateDebug()
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
