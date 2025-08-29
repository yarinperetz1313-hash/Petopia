local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local GuiUtil = {}

--- Wait for the specified child up to `timeout` seconds.
-- Raises an assertion if the child does not appear in time.
-- @param parent Instance Parent to search under
-- @param name string Name of the expected child
-- @param timeout number? Maximum wait time in seconds (default 5)
-- @return Instance The found child
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
@@ -58,26 +64,26 @@ function GuiUtil.SnapToPixels(gui)
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