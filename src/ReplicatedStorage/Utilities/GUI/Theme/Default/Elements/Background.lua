local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

return function (props)
    local padding = props.Padding or 0

    return roact.createElement("Frame", {
        Size = UDim2.new(1,-padding,1,-padding),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Color3.fromHex("587291")
    }, {
        UICorner = roact.createElement("UICorner", {
            CornerRadius = UDim.new(0,6)
        }),
        Children = roact.createFragment(props[roact.Children])
    })
end