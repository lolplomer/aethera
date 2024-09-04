local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roact = require(ReplicatedStorage.Utilities.Roact)


local createElement = roact.createElement
local useBinding = roact.useBinding
local useCallback = roact.useCallback
local joinBindings = roact.joinBindings

local elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements
local TextLabel = require(elements.TextLabel)

local LOD = 6

local gradient = {
    H = function(c)
        local sequences = {}
            
        for i = 0,LOD do
            table.insert(sequences, ColorSequenceKeypoint.new(i/LOD, Color3.fromHSV(i/LOD, c.S, c.V)))
        end

        return ColorSequence.new(sequences)
    end,
    S = function(c)
        local sequences = {}

        for i = 0,1 do
            table.insert(sequences, ColorSequenceKeypoint.new(i/1, Color3.fromHSV(c.H,i/1,c.V)))
        end

        return ColorSequence.new(sequences)
    end,
    V = function(c)
        local sequences = {}

        for i = 0,1 do
            table.insert(sequences, ColorSequenceKeypoint.new(i/1, Color3.fromHSV(c.H,c.S,i/1)))
        end

        return ColorSequence.new(sequences)
    end
}

local function ColorPicker(props)


    local InitialColor = props.Color or Color3.fromHSV(1,1,1)
    local colors = {InitialColor:ToHSV()}

    local bindings = {}      
    local picker = {}

    local finalColor, setFinalColor = useBinding(InitialColor)

    for i,v in {'H','S','V'} do
        local binding, set = useBinding(colors[i])
        bindings[v] = {binding = binding, set = set}
    end

    local HSV = joinBindings({
        H = bindings.H.binding,
        S = bindings.S.binding,
        V = bindings.V.binding,
    })

    
    local onUpdate = useCallback(function(color)
        if props.OnChange then
            props.OnChange(color)
        end
    end, {props.OnChange})

    for key, v in bindings do
        local binding, set = v.binding, v.set

        local hold = false

        local onColorChange = useCallback(function(value)
            return UDim2.fromScale(value, 0)
        end)

        local update = useCallback(function(rbx, input)
            local AbsolutePosition = rbx.AbsolutePosition
            local AbsoluteSize = rbx.AbsoluteSize
            local MousePos = input.Position

            set((MousePos.X-AbsolutePosition.X)/(AbsoluteSize.X))

            setFinalColor(Color3.fromHSV(
                bindings.H.binding:getValue(),
                bindings.S.binding:getValue(),
                bindings.V.binding:getValue()
            ))

            onUpdate(finalColor:getValue())

        end, {binding, set})

        table.insert(picker, createElement('Frame', {
            Size = UDim2.fromScale(1,1/3-0.04),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1,1,1),
            Active = true,
            [roact.Event.InputChanged] = function(rbx: GuiObject, input: InputObject)
                if input.UserInputType == Enum.UserInputType.MouseMovement and hold then
                    update(rbx, input)
                end
            end,
            [roact.Event.InputBegan] = function(rbx, input: InputObject)
                if input.UserInputType ==Enum.UserInputType.MouseButton1 then
                    hold = true
                    update(rbx, input)
                end
            end,
            [roact.Event.InputEnded] = function(_, input: InputObject)
                if input.UserInputType  == Enum.UserInputType.MouseButton1 then
                    hold = false
                end
            end
        }, {
            createElement('Frame', {
                Size = UDim2.new(0,3,1,0),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.new(1,1,1),
                Position = binding:map(onColorChange)
            }),
            createElement('UIGradient', {
                Color = HSV:map(useCallback(function(c)
                    if gradient[key] then
                        return gradient[key](c)
                    end
                    return ColorSequence.new(Color3.new(1,1,1))
                end))
            })
        }))
    end 

    return createElement(roact.Fragment, nil, {
        createElement(TextLabel, {
            Text = props.Title or 'Color Picker',
            Size = UDim2.fromScale(1,.15),
            TextStrokeTransparency = 0.9,
        }),

        createElement('Frame', {
            Size = UDim2.fromScale(1,.6),
            Position = UDim2.fromScale(0,.2),
            Transparency = 1,
        }, {
            createElement('UIListLayout', {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0.04,0)
            }),
            createElement(roact.Fragment, nil, picker)
        }),
        createElement('Frame', {
            Size = UDim2.fromScale(0.3, 0.15),
            Position = UDim2.fromScale(0,0.8),
            BorderSizePixel = 0,
            BackgroundColor3 = finalColor
        }),
        createElement(TextLabel, {
            Size = UDim2.fromScale(0.5,0.15),
            Position = UDim2.fromScale(0.35,0.8),
            Text = finalColor:map(function(color)
                return BrickColor.new(color).Name
            end),
            TextStrokeTransparency = 0.9,
            TextXAlignment = Enum.TextXAlignment.Left
        })

    })
end

return ColorPicker