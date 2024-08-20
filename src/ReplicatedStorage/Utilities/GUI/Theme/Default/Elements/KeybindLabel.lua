local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

return function (props)
    local InputController = Knit.GetController('InputController')
    local input = InputController:GetInputOfKeybind(props.Keybind)
    local viewportSize = workspace.CurrentCamera.ViewportSize

    return roact.createElement('Frame', {
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1,1,1),
        Size = UDim2.new(),
        AutomaticSize = 'XY',
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        ZIndex = 100,
    }, {
        UICorner = roact.createElement('UICorner', {
            CornerRadius = UDim.new(1,0)
        }),
        UIStroke = roact.createElement('UIStroke', {
            Thickness = 3.2,
            Transparency = 0.82,
        }),
        Padding = roact.createElement('UIPadding', {
            PaddingBottom = UDim.new(0,5),
            PaddingLeft = UDim.new(0,10),
            PaddingRight = UDim.new(0,10),
            PaddingTop = UDim.new(0,5)
        }),
        Label = roact.createElement('TextLabel', {
            BackgroundTransparency = 1,
            Size = UDim2.new(),
            AutomaticSize = 'XY',
            Text = props.DisableLabel and input.Name or  `{input.Name} - {props.CustomLabel or props.Keybind}`,
            TextColor3 = Color3.new(),
            TextSize = (viewportSize.X+viewportSize.Y) * 0.00810445745,
            FontFace = Font.new('SourceSans',Enum.FontWeight.SemiBold),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
        })
    })
end