local roact = require(game.ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Roact"))

type prop = {
    AspectRatio: number?,
    Visible: boolean?,
    Size: UDim2,
}

local Frame = roact.PureComponent:extend("Frame")

function Frame:render()
  

    
end

return roact.forwardRef(function(props, ref)
    local visible = not not props.Visible


    return roact.createElement("CanvasGroup", {
        Size = props.Size or UDim2.new(0.5, 0,0.7, 0),
        BackgroundColor3 = Color3.fromRGB(27, 27, 27),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5,0.5),
        Visible = visible,
        ["ref"] = ref
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
            }, props['children'])
        }),
        -- UICorner = roact.createElement("UICorner", {
        --     CornerRadius = UDim.new(0,6)
        -- }),
        UIAspectRatio = roact.createElement("UIAspectRatioConstraint", {
            AspectRatio = props.AspectRatio or 1.478,
        }),
       -- Children = roact.createElement(roact.Fragment, nil, self.props['children'])
    })
end) 
