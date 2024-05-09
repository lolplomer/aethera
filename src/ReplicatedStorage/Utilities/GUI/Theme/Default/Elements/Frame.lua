local roact = require(game.ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Roact"))

type prop = {
    AspectRatio: number?,
    Visible: boolean?,
    Size: UDim2,
}

local Frame = roact.PureComponent:extend("Frame")

function Frame:render()
    local visible = not not self.props.Visible
    return roact.createElement("CanvasGroup", {
        Size = self.props.Size or UDim2.new(0.5, 0,0.7, 0),
        BackgroundColor3 = Color3.fromRGB(27, 27, 27),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5,0.5),
        Visible = visible,
        [roact.Ref] = self.props[roact.Ref]
    }, {
        DecorativeFrame = roact.createElement("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            Image = "rbxassetid://13798496003"
        }, {
            SafeFrame = roact.createElement("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(.9,.8),
                Position = UDim2.fromScale(.5,.49),
                AnchorPoint = Vector2.new(.5,.5)
            }, self.props[roact.Children])
        }),
        -- UICorner = roact.createElement("UICorner", {
        --     CornerRadius = UDim.new(0,6)
        -- }),
        UIAspectRatio = roact.createElement("UIAspectRatioConstraint", {
            AspectRatio = self.props.AspectRatio or 1.478,
        }),
       -- Children = roact.createFragment(self.props[roact.Children])
    })
end

return function(prop: prop)
    return roact.createElement(Frame, prop)
end

