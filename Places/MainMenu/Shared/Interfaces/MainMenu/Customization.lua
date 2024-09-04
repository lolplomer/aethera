local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)
local util = require(ReplicatedStorage.Utilities.GUI.GUIUtil)

local e = roact.createElement

local elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements

local TextLabel = require(elements.TextLabel)
local TextButton = require(elements.TextButtonNew)

local Title = require(script.Parent.Title)

local RoactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local Avatar = require(ReplicatedStorage.GameModules.Avatar)
local Knit = require(ReplicatedStorage.Packages.Knit)

local AvatarController = Knit.GetController('AvatarController')
local GUI = Knit.GetController('GUI')

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
    state = table.clone(state)
    state[action.category] = action.value
    return state
end

local function customization(props) 
    print(props.Done)
    local transparency, visible = util.useFadeEffect(props.Visible)

    local avatar = AvatarController:GetEditingData()

    local bindings = {}
    local categories = {}

    for category,_ in Avatar.Category do
        local bind, set = roact.useBinding(avatar[category])
        bindings[category] = {binding = bind, set = set}
    end
    
    roact.useEffect(function()
        if not props.Visible then
            return
        end
        local connection = AvatarController.EditorChanged:Connect(function(category, value)
            if bindings[category] then
                bindings[category].set(value)
            end
        end)
        for category, value in avatar do
            bindings[category].set(value)
        end
        return function ()
            connection:Disconnect()
        end
    end)

    for Category, Module in Avatar.Category do

        local Type = Module.Customization.Type

        local IS_SELECTION = Type == 'Selection'


        table.insert(categories, e('ImageLabel', {
            Size = UDim2.fromScale(.9,.25),
            BackgroundColor3 = Color3.fromHex('587291'),
            BorderSizePixel = 0,
            LayoutOrder = Module.Customization.LayoutOrder or 99
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
                Text = Module.Customization.DisplayName or Category,
            }),

            IS_SELECTION and e(Arrow, {
                Direction = 'Left',
                Callback = roact.useCallback(function()
                    AvatarController.Editor:PreviousSelection(Category)
                end)
            }),

            e('Frame', {
                Size = UDim2.fromScale(0.5,0.55),
                AnchorPoint = Vector2.new(0.5,1),
                Position = UDim2.fromScale(0.5,.85),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromHex("43566D")
            }, {
                IS_SELECTION and e(TextLabel, {
                    Text = bindings[Category].binding:map(roact.useCallback(function(value)
                        return (Module.CustomLabel and Module.CustomLabel(value) or value) or 'N/A'
                    end)),
                    Visible = Module.Customization.Visible ~= false
                }),

                Type == 'Color' and e('ImageButton', {
                    Size = UDim2.new(1,-9,1,-9),
                    AnchorPoint = Vector2.new(0.5,0.5),
                    Position = UDim2.fromScale(0.5,0.5),
                    Image = '',
                    BackgroundColor3 = bindings[Category].binding:map(roact.useCallback(function(value)
                        return value and Color3.fromHex(value)
                    end)),
                    [roact.Event.Activated] = function()
                        GUI:CreatePopup('ColorPicker' , GUI.newElement('ColorPicker', {
                            OnChange = function(color: Color3)
                                AvatarController:EditAvatar{
                                    [Category] = color:ToHex()
                                }
                            end,
                            Title = Module.Customization.DisplayName or Category,
                            Color = avatar[Category] and Color3.fromHex(avatar[Category])
                        }), {
                            Ratio = 1.3,
                            Position = UDim2.fromScale(0.04,0.5),
                            Size = UDim2.fromScale(0.3,0.5),
                            AnchorPoint = Vector2.new(0,.5)
                        })
                    end
                }, {
                    e('UICorner')
                }),

                Module.CustomView and roact.createElement(Module.CustomView, {
                    value = bindings[Category].binding
                }),

                e('UICorner')
            }),

            IS_SELECTION and e(Arrow, {
                Direction = 'Right',
                Callback = roact.useCallback(function()
                    AvatarController.Editor:NextSelection(Category)
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
                    SortOrder = Enum.SortOrder.LayoutOrder
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
            AspectRatio = 4.57471264,
            Callback = props.Done
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