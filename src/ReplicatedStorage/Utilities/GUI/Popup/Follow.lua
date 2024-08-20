local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local Follow = roact.PureComponent:extend('FollowPopupComponent')
local Trove = require(ReplicatedStorage.Packages:WaitForChild"Trove")

function Follow:init()
    self.MainFrame = roact.createRef()
    self.Cleaner = Trove.new()
end

function Follow:UpdatePosition()
    local Frame: Frame = self.MainFrame.current
    local mousePos = UserInputService:GetMouseLocation()
    local resolution = workspace.CurrentCamera.ViewportSize
    local frameSize = Frame.AbsoluteSize
    local boundary = Vector2.new(
        math.max(resolution.X - frameSize.X * 1.2,0),
        math.max(resolution.Y - frameSize.Y * 1.2,0)
    )

    local position = Vector2.new(
        math.clamp(mousePos.X, 0, boundary.X),
        math.clamp(mousePos.Y, 0, boundary.Y)
    )

    Frame.Position = UDim2.fromOffset(position.X,position.Y)
end

function Follow:didMount()
    self:UpdatePosition()

    self.Cleaner:Connect(RunService.RenderStepped, function()
        self:UpdatePosition()
    end)

    -- self.Cleaner:Connect(UserInputService.InputChanged, function(input:InputObject)
    --     if input.UserInputType == Enum.UserInputType.MouseMovement then
    --         self:UpdatePosition()
    --     end
    -- end)
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
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
    }, {
        --Children = roact.createElement(roact.Fragment, nil, self.props['children']),
        Children =  roact.createElement(roact.Fragment, nil, self.props['children']),
        List = roact.createElement('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = 'Center'
        }),
        Stroke = roact.createElement('UIStroke', {
            Color = Color3.new(),
            Thickness = 5,
            Transparency = 0.4
        })
    })
end

return Follow