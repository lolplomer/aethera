local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)


local new = roact.createElement

local elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements

local TextLabel = require(elements.TextLabel)

local function title(props)
    return new('ImageLabel', {
        Size = UDim2.fromScale(.3,.3),
        AnchorPoint = Vector2.new(0.5,0),
        Position = UDim2.fromScale(0.5,0),
        Image = 'rbxassetid://131498520955699',
        BackgroundTransparency = 1,
    }, {
        new('UIAspectRatioConstraint', {AspectRatio = 6.89873418}),

        new(TextLabel, {
            Text = props.Text,
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromScale(0.8,0.8)
        })
    })
end

return title