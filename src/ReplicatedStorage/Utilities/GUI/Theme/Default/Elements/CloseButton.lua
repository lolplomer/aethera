local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

return function(props)
    return roact.createElement("ImageButton", {
        Size = props.Size,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1,
        Image = "rbxassetid://13806830407",
        [roact.Event.Activated] = props.Callback
    },  {
        AspectRatio = roact.createElement("UIAspectRatioConstraint", {
            AspectRatio = 0.92727272727
        })
    })
end