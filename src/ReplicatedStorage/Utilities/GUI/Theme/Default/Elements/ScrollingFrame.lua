local roact = require(game.ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Roact"))

return function(props)
    return roact.createElement('ScrollingFrame', {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        AutomaticCanvasSize = 'Y',
        CanvasSize = UDim2.fromScale(0,0),
        ScrollBarThickness = props.ScrollBarThickness or 8,
        BorderSizePixel = 0,
    }, props[roact.Children])
end