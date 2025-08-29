
+44
-0

local Style = {}

-- Theme colors
Style.Colors = {
    Background = Color3.fromRGB(25, 25, 35), -- dark navy
    Accent = Color3.fromRGB(45, 120, 220),   -- bright blue
    AccentHover = Color3.fromRGB(65, 150, 255),
    Danger = Color3.fromRGB(180, 40, 40),
    Text = Color3.new(1, 1, 1),
    TextMuted = Color3.fromRGB(170, 170, 170),
}

-- Corner radius for rounded elements
Style.CornerRadius = UDim.new(0, 8)

-- Drop shadow asset (placeholder id)
Style.ShadowImage = "rbxassetid://1316045217"
Style.ShadowTransparency = 0.5

-- Font definitions
Style.Fonts = {
    Title = Enum.Font.GothamBlack,
    Subtitle = Enum.Font.GothamBold,
    Body = Enum.Font.Gotham,
    Code = Enum.Font.Code,
}

-- Text sizes
Style.TextSize = {
    Title = 32,
    Body = 20,
    Small = 14,
}

-- Common stroke thickness
Style.StrokeThickness = 2

-- Default background transparency
Style.BackgroundTransparency = 0.15

-- Padding for containers
Style.Padding = 8

return Style