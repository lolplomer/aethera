local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local knit = require(ReplicatedStorage.Packages.Knit)
local GUI = knit.GetController('GUI')
local InputController = knit.GetController('InputController')

local Trove = require(ReplicatedStorage.Packages.Trove)

return function (props)
    local proximity: ProximityPrompt = props.ProximityPrompt

    local styles, api = ReactSpring.useSpring(function()
        return {
            transparency =  props.Disabled and 0 or 1,
            hold = 0,
            config = {mass = 0.5, tension = 250}
        }
    end)

    local hold, hold_api = ReactSpring.useSpring(function()
        return {value = 0,  config = {
            duration = proximity.HoldDuration,
            easing = ReactSpring.easings.linear
        }}
    end)

    roact.useEffect(function()
        local _trove = Trove.new()
        local cleanup = _trove:WrapClean()

        api.start {
            transparency = props.Disabled and 1 or 0
        }

        
        _trove:Connect(proximity.PromptButtonHoldBegan, function()
            api.start {hold = 1}

            hold_api.start {
                from = {value = 0},
                to = {value = 1},
                reset = true,
                config = {
                    duration = proximity.HoldDuration,
                }
            }
        end)
        _trove:Connect(proximity.PromptButtonHoldEnded, function()
            api.start {hold = 0}

            hold_api.stop()
            --hold_api.start {value = 0}
        end)

        return cleanup
    end)

    local hasObjectText = proximity.ObjectText ~= ""

    return roact.createElement('CanvasGroup', {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        GroupTransparency = styles.transparency,
       -- ClipsDescendants = false
        --AnchorPoint = Vector2.new(0,.5),
        --Position = UDim2.fromScale(0,.5)
    }, {
        KeyFrame = roact.createElement('ImageButton', {
            BackgroundTransparency = 1,
            Size = styles.hold:map(function(value)  
                return UDim2.fromScale(0.2+0.08*value,.7+0.08*value)
            end),
            Position = UDim2.fromScale(0.19,0.5),
            ScaleType = Enum.ScaleType.Fit,
            Image = 'rbxassetid://18118106613',
            AnchorPoint = Vector2.new(0.5,0.5),
            ZIndex = 2,
            [roact.Event.MouseButton1Down] = function()
                proximity:InputHoldBegin()
            end,
            [roact.Event.MouseButton1Up] = function()
                task.wait()
                proximity:InputHoldEnd()
            end,
        }, {
            Ratio = roact.createElement('UIAspectRatioConstraint', {AspectRatio = 1}),
            Key = GUI.newElement('TextLabel', {
                Size = UDim2.fromScale(.65,.65),
                Position = UDim2.fromScale(.5,.5),
                AnchorPoint = Vector2.new(.5,.5),
                Text = `<b>{InputController:GetInputOfKeybind('Interact').Name}</b>`,
                RichText = true,
                ZIndex = 2,

            })
        }),
        Frame = roact.createElement('ImageLabel', {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0.77,.35),
            Position = UDim2.fromScale(0.57,0.5),
            AnchorPoint = Vector2.new(0.5,.5),
            Image = "rbxassetid://18128698149",
        }, {
            Ratio = roact.createElement('UIAspectRatioConstraint', {AspectRatio = 425.59/97}),
            ActionText = GUI.newElement('TextLabel', {
                Size = UDim2.fromScale(.7, hasObjectText and .6 or .7 ),
                Position = UDim2.fromScale(0.2,hasObjectText and 0.9 or 0.5),
                TextXAlignment = 'Left',
                AnchorPoint = Vector2.new(0, hasObjectText and 1 or 0.5),
                Text = proximity.ActionText
            }),
            ObjectText = hasObjectText and GUI.newElement('TextLabel', {
                Size = UDim2.fromScale(.7, .3),
                Position = UDim2.fromScale(0.2,0.15),
                TextXAlignment = 'Left',
                AnchorPoint = Vector2.new(0, 0),
                TextColor3 = Color3.fromRGB(200, 200, 200),
                Text = proximity.ObjectText
            }),

            HoldBar = roact.createElement('ImageLabel', {
                AnchorPoint = Vector2.new(0,1),
                Size = UDim2.fromScale(0.85,1),
                Image = 'rbxassetid://18128371339',
                ImageColor3 = Color3.fromHex('43556A'),
                BackgroundTransparency = 1,
                ImageTransparency = styles.hold:map(function(value)
                    return 1-value
                end)
            }, {
                Ratio = roact.createElement('UIAspectRatioConstraint', {AspectRatio = 331/11}),
                Bar = GUI.newElement('ImageBar', {
                    Image = "rbxassetid://18128371339",
                    Size = UDim2.fromScale(1,1),
                    Value = hold.value,
                    ImageTransparency = styles.hold:map(function(value)
                        return 1-value
                    end),
                    ImageColor3 = Color3.fromHex('909FB0')
                })
            })
        })
    })
end