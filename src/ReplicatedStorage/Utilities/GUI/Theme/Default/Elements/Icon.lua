local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local create = roact.createElement

return function (props)
    local Padding = (props.Padding or 10)
    return create("Frame", {
        BackgroundColor3 = Color3.fromRGB(88, 114, 145),
        Size = props.Size,
        Position = props.Position
    }, {
        Ratio = create('UIAspectRatioConstraint'),
        Corner = create("UICorner"),
        Image = create("ImageButton", {
            Size = UDim2.new(1,Padding,1,Padding),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5,0.5),
            AnchorPoint = Vector2.new(0.5,0.5),
            Image = props.Image,
            [roact.Event.Activated] = props.Callback
        })
    })
end