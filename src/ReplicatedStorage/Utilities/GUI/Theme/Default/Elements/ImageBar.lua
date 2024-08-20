local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Utilities.Roact)

return function (props)
    
    return Roact.createElement('ImageLabel', {
        Size = props.Size,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        BorderSizePixel = 0,
        Image = props.Image,
        BackgroundTransparency = 1,
        ImageColor3 = props.ImageColor3,
        ZIndex = props.ZIndex,
        ImageTransparency = props.ImageTransparency
    }, {
        Gradient = Roact.createElement('UIGradient', {
            Rotation = props.Rotation,
            Transparency = props.Value:map(function(value)
                return NumberSequence.new {
                    NumberSequenceKeypoint.new(0,0),
                    NumberSequenceKeypoint.new(math.clamp(value-0.001,0.001,0.998),0),
                    NumberSequenceKeypoint.new(math.clamp(value,0.002,0.999),1),
                    NumberSequenceKeypoint.new(1,1)
                }
            end)
            --Transparency = 0.5
        }),
        Children = Roact.createElement(Roact.Fragment, nil, props['children'])
    })
end