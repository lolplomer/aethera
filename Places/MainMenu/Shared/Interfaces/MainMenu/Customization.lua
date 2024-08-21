local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)
local util = require(ReplicatedStorage.Utilities.GUI.GUIUtil)

local story = require(ReplicatedStorage.PlaceShared.RoactStory)
local e = roact.createElement

local elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements

local TextLabel = require(elements.TextLabel)
local TextButton = require(elements.TextButtonNew)

local Title = require(script.Parent.Title)

local RoactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local Avatar = require(ReplicatedStorage.GameModules.Avatar)

local Direction = {
    Left = {
        Image = "rbxassetid://112657131728381",
        AnchorPoint = Vector2.new(0,0.5),
        Position = UDim2.fromScale(0,0.5),
        Ratio = 0.525969757
    },
    Right = {
        Image = "rbxassetid://105582742701594",
        AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.fromScale(1,0.5),
        Ratio = 0.525969757
    }
}

local function Arrow(props)
    local prop = Direction[props.Direction] or Direction.Left

    local style, api = RoactSpring.useSpring(function()
        return {
            Size = UDim2.fromScale(0.9,0.9),
            config = {tension = 350}
        }
    end)

    return e('Frame', {
        Size = UDim2.fromScale(.7,.7),
        Position = prop.Position,
        AnchorPoint = prop.AnchorPoint,
        BackgroundTransparency = 1,
    }, {
        e('ImageButton', {
            BackgroundTransparency = 1,
            Size = style.Size,
            Image = prop.Image,
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            [roact.Event.MouseButton1Up] = function()
                api.start {Size = UDim2.fromScale(.9,.9)}
            end,
            [roact.Event.MouseButton1Down] = function()
                api.start {Size = UDim2.fromScale(1.1,1.1)}
            end,
            [roact.Event.Activated] = props.Callback
        }),
        e('UIAspectRatioConstraint',{AspectRatio = prop.Ratio})
    })
end

local function reducer(state, action)
    if action.type == 'switch' then
        state = table.clone(state)
        local new = state[action.category] + action.index
        if new > 15 then
            new = 0
        elseif new < 0 then
            new = 15
        end
        state[action.category] = new
        return state
    end
end

local function customization(props) 

    local transparency, visible = util.useFadeEffect(props.Visible)

    local avatar, dispatch = roact.useReducer(reducer, {
        Skin = 0,
        Hair1 = 0,
        Hair2 = 0,
        Uniform = 0,
    })

    local categories = {}

    for Key, Value in avatar do
        table.insert(categories, e('ImageLabel', {
            Size = UDim2.fromScale(.9,.25),
            BackgroundColor3 = Color3.fromHex('587291'),
            BorderSizePixel = 0
        }, {
            e('UICorner'),

            e('UIPadding', {
                PaddingTop = UDim.new(0.05,0),
                PaddingLeft = UDim.new(0.05,0), 
                PaddingRight = UDim.new(0.05,0),
                PaddingBottom = UDim.new(0.05,0),
            }),

            e(TextLabel, {
                Size = UDim2.fromScale(1,0.3),
                Text = Key,
            }),

            e(Arrow, {
                Direction = 'Left',
                Callback = roact.useCallback(function()
                    print('left')
                    dispatch{type = 'switch', category = Key, index = -1}
                end)
            }),

            
     

            e('Frame', {
                Size = UDim2.fromScale(0.5,0.55),
                AnchorPoint = Vector2.new(0.5,1),
                Position = UDim2.fromScale(0.5,.85),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromHex("43566D")
            }, {
                e(TextLabel, {
                    Text = Value
                }),
                e('UICorner')
            }),

            e(Arrow, {
                Direction = 'Right',
                Callback = roact.useCallback(function()
                    print('right')
                    dispatch{type = 'switch', category = Key, index = 1}
                end)
            })
        }))
    end

    

    return e('CanvasGroup', {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        GroupTransparency = transparency,
        Visible = visible
    }, {
        e('ImageLabel', {
            Size = UDim2.fromScale(.65,.65),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.fromScale(1, 0.1),
            Image = "rbxassetid://103526089652155",
            BackgroundTransparency = 1,
            
        }, {
            e('UIAspectRatioConstraint', {AspectRatio = 0.593294461}),

            e('ScrollingFrame', {
                Size = UDim2.fromScale(0.9,0.77),
                AnchorPoint = Vector2.new(.5,.5),
                Position = UDim2.fromScale(.5,.5),
                BackgroundTransparency = 1,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
            }, {
                e('UIListLayout', {
                    Padding = UDim.new(0,5) ,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    
                }),

                e('UIPadding', {
                    PaddingRight = UDim.new(0,5),

                }),

                e(roact.Fragment, nil, categories)
            })
        }),
        e(TextButton, {
            Size = UDim2.fromScale(.2,.08),
            Text = 'Next',
            Position = UDim2.fromScale(1,.9),
            AnchorPoint = Vector2.new(1,1),
            AspectRatio = 4.57471264
            --Position = UDim2.fromScale(1,1)
        }),

        e('UIPadding', {
            PaddingRight = UDim.new(0.02,0),
            PaddingBottom = UDim.new(0.02,0)
        }),

        e(Title, {
            Text = 'Customization'
        })
    })
end

return customization