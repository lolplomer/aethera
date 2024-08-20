local ReplicatedStorage = game.ReplicatedStorage
local roact = require(ReplicatedStorage.Utilities.Roact)
local TextLabel = require(script.Parent.TextLabel)

local Knit = require(ReplicatedStorage.Packages.Knit)
local GUI = Knit.GetController("GUI")

type prop = {
    Color: Color3,
    Text: string,
    Size: UDim2 | nil,
    Position: UDim2 | nil,
    AspectRatio: number | nil,
    Callback: any,
    AnchorPoint: Vector2,
    LayoutOrder: number,
    TextXAlignment: Enum.TextXAlignment,
    TextYAlignment: Enum.TextYAlignment,
    TextSize: UDim2?,
    UseGradient: boolean?,
    CornerSize: UDim,
    Selected: boolean,
}

local TextButton = roact.PureComponent:extend("TextButton")

local color = Color3.fromHex("587291")

function TextButton:init()
    self.innerButtonRef = roact.createRef()
end

function TextButton:render()
    local props = self.props

    self.props.Selected = not not self.props.Selected

    self.buttonColor = self.props.Selected and GUI.Color.MultiplyValue(color, 1.2) or color

    return roact.createElement("ImageButton", {
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Size = props.Size,
        Position = props.Position,
        Image = "rbxassetid://13797922094",
        AnchorPoint = props.AnchorPoint,
        LayoutOrder = props.LayoutOrder or 0,
        [roact.Event.Activated] = props.Callback,
        [roact.Event.MouseButton1Down] = function()
            GUI.Tween(self.innerButtonRef:getValue(), {ImageColor3 = GUI.Color.MultiplyValue(self.buttonColor, 1.2)}, TweenInfo.new(0.05))
        end,
        [roact.Event.MouseButton1Up] = function()
            GUI.Tween(self.innerButtonRef:getValue(), {ImageColor3 = self.buttonColor})
        end
    }, {

        InnerDecoration = roact.createElement('ImageLabel', {
            BackgroundTransparency = 1,
           -- Image = "rbxassetid://13797899918",
            Image = "rbxassetid://13797922094",
           -- ImageColor3 = self.props.Selected == false  and self.buttonColor or nil,
            Size = UDim2.fromScale(0.9,1),
            Position = UDim2.fromScale(.5,0),
            AnchorPoint = Vector2.new(0.5,0),
            
            ["ref"] = self.innerButtonRef,
            [roact.Event.MouseEnter] = function()
                GUI.Tween(self.innerButtonRef:getValue(), {ImageColor3 = GUI.Color.MultiplyValue(self.buttonColor, 0.8)})
            end,
            [roact.Event.MouseLeave] = function()
                task.wait()
                GUI.Tween(self.innerButtonRef:getValue(), {ImageColor3 = self.buttonColor})
            end,
        }, {
            TextLabel = roact.createElement(TextLabel, {
                Size = props.TextSize or UDim2.fromScale(0.9,0.8),
                AnchorPoint = Vector2.new(.5,.5),
                Position = UDim2.fromScale(.5,.5),
                Text = props.Text,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                --TextStrokeTransparency = 0.87,
                TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
                TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
            }),
            Children = roact.createElement(roact.Fragment, nil, props['children'])
        }),


    })
end

function TextButton:didUpdate()
    GUI.Tween(self.innerButtonRef:getValue(), {ImageColor3 = self.buttonColor})
end

function TextButton:didMount()
    local btn = self.innerButtonRef:getValue()
    btn.ImageColor3 = self.buttonColor
    --GUI.Tween(self.innerButtonRef:getValue(), {ImageColor3 = self.buttonColor})
end

return TextButton