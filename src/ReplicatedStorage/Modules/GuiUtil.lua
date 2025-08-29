local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local GuiUtil = {}

function GuiUtil.BoundWait(parent, name, timeout)
    timeout = timeout or 5
    local obj = parent:WaitForChild(name, timeout)
    assert(obj, string.format("Missing child '%s' in %s", name, parent:GetFullName()))
    return obj
end

function GuiUtil.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function(state)
                if state == Enum.UserInputState.End then
                    dragStart = nil
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
            local delta = input.Position - dragStart
            frame.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
            GuiUtil.ConstrainToViewport(frame)
        end
    end)
end

function GuiUtil.ConstrainToViewport(frame)
    local vp = workspace.CurrentCamera.ViewportSize
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    local newX = math.clamp(pos.X, 0, vp.X - size.X)
    local newY = math.clamp(pos.Y, 0, vp.Y - size.Y)
    frame.Position = UDim2.fromOffset(newX, newY)
end

function GuiUtil.SnapToPixels(gui)
    gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        gui.Position = UDim2.fromOffset(
            math.floor(gui.AbsolutePosition.X + 0.5),
            math.floor(gui.AbsolutePosition.Y + 0.5)
        )
    end)
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        gui.Size = UDim2.fromOffset(
            math.floor(gui.AbsoluteSize.X + 0.5),
            math.floor(gui.AbsoluteSize.Y + 0.5)
        )
    end)
end

function GuiUtil.BuildIconButton(props)
    props = props or {}
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(45,120,220)
    button.Size = props.Size or UDim2.fromOffset(32,32)
    button.Font = props.Font or Enum.Font.GothamBold
    button.TextSize = props.TextSize or 20
    button.Text = props.Text or ""
    button.TextColor3 = props.TextColor3 or Color3.new(1,1,1)
    button.AnchorPoint = props.AnchorPoint or Vector2.new(0,0)
    button.Position = props.Position or UDim2.new()
    if props.Parent then button.Parent = props.Parent end
    return button
end

function GuiUtil.BuildCloseIcon(props)
    props = props or {}
    props.Text = props.Text or "✖"
    props.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(180,40,40)
    return GuiUtil.BuildIconButton(props)
end

return GuiUtil