local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local Label = roact.PureComponent:extend('KeybindLabel')

function Label:render()
    local InputController = Knit.GetController('InputController')
    local input = InputController:GetInputOfKeybind(self.props.Keybind)

    return roact.createElement('Frame', {
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1,1,1),
        Size = UDim2.new(),
        AutomaticSize = 'XY',
        Position = self.props.Position,
        AnchorPoint = self.props.AnchorPoint,
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
            Text = `{input.Name} - {self.props.Keybind}`,
            TextColor3 = Color3.new(),
            TextSize = 18,
            FontFace = Font.new('SourceSans',Enum.FontWeight.SemiBold),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
        })
    })
end

return Label