local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)
local roactSpring = require(ReplicatedStorage.Packages.ReactSpring)
local useCallback = roact.useCallback
local useSpring = roactSpring.useSpring

local GuiUtil = require(ReplicatedStorage.Utilities.GUI.GUIUtil)

local TextLabel = require(script.Parent.TextLabel)

local color = Color3.fromHex("587291")

return function(props)
    local selected = props.Selected or false

    local buttonColor = selected and GuiUtil.Color.MultiplyValue(color, 1.2) or color

    local styles, api = useSpring(function()
        return {
            ImageColor3 = buttonColor,
            config = { tension = 170, friction = 26 }
        }
    end)

    local onActivated = useCallback(function()
        if props.Callback then
            props.Callback()
        end
    end, { props.Callback })

    local onMouseDown = useCallback(function()
        api.start({ ImageColor3 = GuiUtil.Color.MultiplyValue(buttonColor, 1.2) })
    end, { buttonColor, api })

    local onMouseUp = useCallback(function()
        api.start({ ImageColor3 = buttonColor })
    end, { buttonColor, api })

    local onMouseEnter = useCallback(function()
        api.start({ ImageColor3 = GuiUtil.Color.MultiplyValue(buttonColor, 0.8) })
    end, { buttonColor, api })

    local onMouseLeave = useCallback(function()
        api.start({ ImageColor3 = buttonColor })
    end, { buttonColor, api })

    return roact.createElement("ImageButton", {
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Size = props.Size,
        Position = props.Position,
        Image = "rbxassetid://13797922094",
        AnchorPoint = props.AnchorPoint,
        LayoutOrder = props.LayoutOrder or 0,
        [roact.Event.Activated] = onActivated,
        [roact.Event.MouseButton1Down] = onMouseDown,
        [roact.Event.MouseButton1Up] = onMouseUp,
    }, {
        InnerDecoration = roact.createElement('ImageLabel', {
            BackgroundTransparency = 1,
            Image = "rbxassetid://13797922094",
            Size = UDim2.fromScale(0.9, 1),
            Position = UDim2.fromScale(0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            ImageColor3 = styles.ImageColor3,
            [roact.Event.MouseEnter] = onMouseEnter,
            [roact.Event.MouseLeave] = onMouseLeave,
        }, {
            TextLabel = roact.createElement(TextLabel, {
                Size = props.TextSize or UDim2.fromScale(0.9, 0.8),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Text = props.Text,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
                TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
            }),
            Children = roact.createElement(roact.Fragment, nil, props.children)
        }),
    }, {
        props.AspectRatio and roact.createElement('UIAspectRatioConstraint', {AspectRatio = props.AspectRatio})
    })
end
