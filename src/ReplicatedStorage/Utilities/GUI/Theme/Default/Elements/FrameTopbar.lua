local roact = require(game.ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Roact"))
--local signal = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild"Signal")

local TextLabel = require(script.Parent:WaitForChild"TextLabel")

type prop = {
    Title: string,
    CloseButtonCallback: any,
}

local FrameTopbar = roact.PureComponent:extend('FrameTopbar')

function FrameTopbar:render()
    return roact.createElement("ImageLabel", {
        BackgroundTransparency = 1,
        Size = self.props.Size or UDim2.fromScale(.76,0.11),
        Image = "rbxassetid://13806797167",
        Position = self.props.Position or UDim2.fromScale(-0.04,0.03)
    }, {
        TextLabel = roact.createElement(TextLabel, {
            Text = self.props.Title,
            Position = UDim2.fromScale(0.065, 0.5),
            Size = UDim2.fromScale(.5,.9),
            AnchorPoint = Vector2.new(0,.5),
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })
end


return function(prop: prop)
   return roact.createElement(FrameTopbar, prop)
end