local roact = require(game.ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Roact"))
local TextButton = require(script.Parent:WaitForChild"TextButton")
local roactAnimate = require(game.ReplicatedStorage.Utilities:WaitForChild"RoactAnimate")


local Dropdown = roact.PureComponent:extend("Dropdown")
local padding = 5

function Dropdown:init()
    self.opened = false

    local choiceCount = #self.props.Choices

    self._sizeValue = roactAnimate.Value.new(UDim2.fromScale(1,0))
    local tweenInfo = TweenInfo.new(0.25)
    self._close = roactAnimate(self._sizeValue, tweenInfo, UDim2.fromScale(1,0))
    self._open = roactAnimate(self._sizeValue, tweenInfo, UDim2.fromScale(1,choiceCount*0.9))
end

function Dropdown:open()
    self._open:Start()
    self.opened = true
end

function Dropdown:close()
    self._close:Start()
    self.opened = false
end

function Dropdown:toggle()
    if self.opened then
        self:close()
    else
        self:open()
    end
end

function Dropdown:render()

    local choiceCount = #self.props.Choices

    local choices = {}
    for _, choice in self.props.Choices do
        choices[choice.Text] = roact.createElement(TextButton, {
            Text = choice.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            UseGradient = false,
            Color = Color3.fromRGB(56, 56, 56),
            CornerSize = UDim.new(),
            Size = UDim2.new(1,0,1/choiceCount,-padding),
            Callback = function()
                self:setState{SelectedChoice = choice}
                if choice.Callback then
                    choice.Callback()
                end
                self:close()
            end
        })
    end

    local ButtonText = self.props.Text
    if self.state.SelectedChoice then
        ButtonText = self.state.SelectedChoice.Text
    end

    return roact.createElement(TextButton, {
        TextSize = UDim2.fromScale(0.9,0.6),
        Size = self.props.Size,
        Text = ButtonText,

        TextXAlignment = Enum.TextXAlignment.Left,
        Callback = function()
           self:toggle()
        end
    }, {
        Choice = roact.createElement(roactAnimate.Frame, {
            Position = UDim2.fromScale(0,1),
            Size = self._sizeValue,
            BackgroundColor3 = Color3.fromRGB(56, 56, 56),
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            UIListLayout = roact.createElement('UIListLayout', {
                Padding = UDim.new(0,padding),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            }),
            Choices = roact.createFragment(choices)
        }),
        Arrow = roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(1,0.5),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Size = UDim2.fromScale(0.85,0.85),
            Position = UDim2.fromScale(0.999,0.5),
            Image = "rbxassetid://5143165549",
            BackgroundTransparency = 1,
        })
    })
end


return Dropdown