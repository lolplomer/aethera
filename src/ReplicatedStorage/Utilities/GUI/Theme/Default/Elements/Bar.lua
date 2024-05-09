local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local ColorUtil = require(game.ReplicatedStorage.Utilities:WaitForChild"Misc":WaitForChild"ColorUtil")
local TextLabel = require(script.Parent:WaitForChild"TextLabel")

local function Corner(radius)
    return roact.createElement('UICorner', {CornerRadius = radius})
end

return function (props)
    return roact.createElement("Frame", {
        LayoutOrder = props.LayoutOrder,
        BorderSizePixel = 0,
        Size = props.Size or UDim2.fromScale(1,1),
        Position = props.Position,
        BackgroundColor3 = props.StrokeColor
    }, {
        Children = roact.createFragment(props[roact.Children]),
        Corner = Corner(props.CornerRadius),
        InnerBar = roact.createElement("Frame", {
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.5,0.5),
            AnchorPoint = Vector2.new(0.5,0.5),
            Size = UDim2.new(1,-(props.StrokeSizeX or props.StrokeSize),1,-(props.StrokeSizeY or props.StrokeSize)),
            BackgroundColor3 = props.InnerBarColor or ColorUtil.MultiplyValue(props.BarColor, 0.5),
            [roact.Ref] = props.Ref
        }, {
            Bar = roact.createElement("Frame", {
                BorderSizePixel = 0,
                Size = UDim2.fromScale(props.Progress/props.MaxProgress,1),
                BackgroundColor3 = props.BarColor,
                [roact.Ref] = props.BarRef
            }, {
                Corner = Corner(props.BarCornerRadius or props.CornerRadius),
            }),
            Corner = Corner(props.BarCornerRadius or props.CornerRadius),
            Label = roact.createElement(TextLabel, {
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.fromScale(0.5,0.5),
                Size = UDim2.fromScale(1,1),
                Text = `{props.Label}: {props.Progress}/{props.MaxProgress}`,
                ZIndex = 2,
                [roact.Ref] = props.LabelRef
            })
        })
    })
end