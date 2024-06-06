local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local Follow = roact.PureComponent:extend('FollowPopupComponent')
local Trove = require(ReplicatedStorage.Packages:WaitForChild"Trove")

function Follow:init()
    self.MainFrame = roact.createRef()
    self.Cleaner = Trove.new()
end

function Follow:didMount()
    local Frame = self.MainFrame:getValue()
    self.Cleaner:Connect(UserInputService.InputChanged, function(input:InputObject)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Frame.Position = UDim2.fromOffset(input.Position.X,input.Position.Y)
        end
    end)
end

function Follow:willUnmount()
    self.Cleaner:Destroy()
end

function Follow:render()
    return roact.createElement('Frame', {
        Size = self.props.Size or UDim2.fromScale(.2,.15),
        BackgroundTransparency = 0.4,
        BackgroundColor3 = Color3.new(),
        ["ref"] = self.MainFrame,
        AutomaticSize = Enum.AutomaticSize.Y
    }, {
        --Children = roact.createElement(roact.Fragment, nil, self.props['children']),
        Children =  roact.createElement(roact.Fragment, nil, self.props['children']),
        List = roact.createElement('UIListLayout', {})
    })
end

return Follow