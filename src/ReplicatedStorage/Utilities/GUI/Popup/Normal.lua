local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local GUIUtil = require(script.Parent.Parent:WaitForChild"GUIUtil")

--local GUI = Knit.GetController("GUI")

local PopupComponent = roact.PureComponent:extend('Popup')

function PopupComponent:didMount()
    local UIS = game:GetService("UserInputService")
    self.InputDetect = UIS.InputEnded:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseWheel) and not self.hovered then
            if self.props.DeselectedCallback then
                self.props.DeselectedCallback()
            end
        end
    end)
    self:open()
end

function PopupComponent:init()
    self.FrameRef = roact.createRef()
    self.Size = self.props.Size or UDim2.fromScale(0.2,0.15)
    GUIUtil.ImplementAnimatedOpenClose(self, {
        Size = self.Size,
        CloseSizeScale = self.props.CloseSizeScale or 1.2
    })
end

function PopupComponent:willUnmount()
    self.InputDetect:Disconnect()
end

function PopupComponent:render()
    local props = self.props
    return roact.createElement("CanvasGroup", {
        BackgroundColor3 = Color3.fromRGB(102, 133, 168),
        
        Position = props.Position or UDim2.fromScale(0.5,0.5),
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5,0.5),
        Size = self.Size,

        [roact.Event.MouseEnter] = function()
            task.wait()
            self.hovered = true
        --    print(self.hovered)
        end,
        [roact.Event.MouseLeave] = function()
            self.hovered = false
           -- print(self.hovered)
        end,
        [roact.Ref] = self.FrameRef
    }, {
        Children = roact.createFragment(self.props[roact.Children]),
        Ratio = props.UseRatio ~= false and roact.createElement("UIAspectRatioConstraint", {AspectRatio = 2.63}),
        Corner = roact.createElement("UICorner"),
        Stroke = roact.createElement("UIStroke", {Thickness = 3.5, Color = Color3.fromRGB(233, 235, 248)})
    })
end

return PopupComponent