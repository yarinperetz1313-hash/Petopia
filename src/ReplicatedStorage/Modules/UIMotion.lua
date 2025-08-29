local TweenService = game:GetService("TweenService")

local UIMotion = {}

local APPEAR_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local DISAPPEAR_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FADE_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function UIMotion.AppearCentered(gui)
    gui.AnchorPoint = Vector2.new(0.5, 0.5)
    gui.Position = UDim2.fromScale(0.5, 0.5)
    gui.Visible = true
    local targetSize = gui.Size
    gui.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, 0, 0)
    gui.BackgroundTransparency = 1
    TweenService:Create(gui, APPEAR_INFO, {
        Size = targetSize,
        BackgroundTransparency = 0
    }):Play()
end

function UIMotion.Disappear(gui)
    local targetSize = gui.Size
    TweenService:Create(gui, DISAPPEAR_INFO, {
        Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(DISAPPEAR_INFO.Time, function()
        gui.Visible = false
    end)
end

function UIMotion.Hover(button)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, FADE_INFO, {
            BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.1)
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, FADE_INFO, {
            BackgroundColor3 = button.BackgroundColor3
        }):Play()
    end)
end

function UIMotion.Press(button)
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, FADE_INFO, {Size = button.Size + UDim2.new(0, -2, 0, -2)}):Play()
    end)
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, FADE_INFO, {Size = button.Size}):Play()
    end)
end

function UIMotion.FadeSwap(oldContainer, buildNew)
    if oldContainer then
        TweenService:Create(oldContainer, FADE_INFO, {BackgroundTransparency = 1}):Play()
        task.wait(FADE_INFO.Time)
        oldContainer:Destroy()
    end
    local newContainer = buildNew()
    newContainer.BackgroundTransparency = 1
    TweenService:Create(newContainer, FADE_INFO, {BackgroundTransparency = 0}):Play()
    return newContainer
end

return UIMotion