local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

return roact.forwardRef(function(props, ref)
    if props.ClipsDescendants == nil then
        props.ClipsDescendants = true
    end
    return roact.createElement('Frame', {
        BackgroundTransparency = 1,
        Size = props.Size or UDim2.fromScale(1,1),
        Position = props.Position,
        ClipsDescendants = props.ClipsDescendants,
        ZIndex = props.ZIndex   ,
        ["ref"] = ref
    }, {
        Children =  roact.createElement(roact.Fragment, nil, props['children'])
    })
end)
