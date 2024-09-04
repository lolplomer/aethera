local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local roact = require(ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local TWINFO = TweenInfo.new(0.3)
--local GUI = Knit.GetController("GUI")

local PopupComponent = roact.PureComponent:extend('Popup')

function PopupComponent:didMount()
    local UIS = game:GetService("UserInputService")
    self.InputDetect = UIS.InputEnded:Connect(function(input, gameProcessedEvent)
        --if gameProcessedEvent then return end
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseWheel) and not self.hovered then
            if self.props.DeselectedCallback then
                self.props.DeselectedCallback()
            end
        end
    end)
   TweenService:Create(self.MainFrame:getValue(), TWINFO, {GroupTransparency = 0}):Play()
end

function PopupComponent:init()
    self.MainFrame = roact.createRef()
    self.Size = self.props.Size or UDim2.fromScale(0.2,0.15)
    
    -- GUIUtil.ImplementAnimatedOpenClose(self, {
    --     Size = self.Size,
    --     CloseSizeScale = self.props.CloseSizeScale or 1.2
    -- })

end

function PopupComponent:willUnmount()
    self.InputDetect:Disconnect()
end

function PopupComponent:render()
    local props = self.props
    return roact.createElement("CanvasGroup", {
        BackgroundColor3 = Color3.fromRGB(233, 235, 248),
        
        Position = props.Position or UDim2.fromScale(0.5,0.5),
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5,0.5),
        Size = self.Size,
        GroupTransparency = 1,

        [roact.Event.MouseEnter] = function()
            task.wait()
            self.hovered = true
        --    print(self.hovered)
        end,
        [roact.Event.MouseLeave] = function()
            self.hovered = false
           -- print(self.hovered)
        end,
        ["ref"] = self.MainFrame
    }, {
        Ratio = props.UseRatio ~= false and roact.createElement("UIAspectRatioConstraint", {AspectRatio = props.Ratio or 2.63}),
        Corner = roact.createElement("UICorner", {CornerRadius = UDim.new(0,8)}),
        --Stroke = roact.createElement("UIStroke", {Thickness = 3.5, Color = Color3.fromRGB(233, 235, 248)}),
  
        Inner = roact.createElement('Frame', {
            Size = UDim2.new(1,-10,1,-10),
            BackgroundColor3 = Color3.fromRGB(102, 133, 168),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(.5,.5),
            Position = UDim2.fromScale(.5,.5)
        }, {
            Children =  roact.createElement(roact.Fragment, nil, self.props['children']),
            Corner = roact.createElement("UICorner", {CornerRadius = UDim.new(0,8)}),
            Padding = roact.createElement('UIPadding', {
                PaddingTop = UDim.new(0.05,0),
                PaddingBottom = UDim.new(0.05,0),
                PaddingRight = UDim.new(0.05,0),
                PaddingLeft = UDim.new(0.05,0),
            }),
        })
    })
end

return PopupComponent
