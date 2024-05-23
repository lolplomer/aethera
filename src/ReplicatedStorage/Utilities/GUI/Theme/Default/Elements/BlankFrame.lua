local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

return function (props)
    if props.ClipsDescendants == nil then
        props.ClipsDescendants = true
    end
    return roact.createElement('Frame', {
        BackgroundTransparency = 1,
        Size = props.Size or UDim2.fromScale(1,1),
        Position = props.Position,
        ClipsDescendants = props.ClipsDescendants,
        ZIndex = props.ZIndex,
        [roact.Ref] = props[roact.Ref]
    }, {
        Children = roact.createFragment(props[roact.Children])
    })
end