local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)

local RoactSpring = require(ReplicatedStorage.Packages.ReactSpring)

--local TextLabel = roact.PureComponent:extend("TextLabel")

type prop = {
    Text: string | nil,
    Size: UDim2 | nil,
    Position: UDim2 | nil,
    AnchorPoint: Vector2 | nil,
    TextXAlignment: Enum.TextXAlignment | nil,
    TextStrokeColor3: Color3,
    LayoutOrder: number,
    TextStrokeTransparency: number,
    TextColor3: Color3,
    TextScale: number,
}

local TextLabel = roact.forwardRef(function(props, ref)
    local textsize = props.TextSize
    if props.TextScale then
        local camera = workspace.CurrentCamera
        local vp = camera.ViewportSize
        textsize = ((vp.X+vp.Y)/2) * props.TextScale
    end
    local TextScaled = true
    if props.TextScaled ~= nil then
        TextScaled = props.TextScaled
    end

    local styles, api = nil, nil

    if props.Blinking == true then
       styles, api = RoactSpring.useSpring(function()
        return {
            from = {transparency = 1},
            to = {transparency = 0},
            
       }
       end) 

       roact.useEffect(function()
            local blink = false
            local function start()
                blink = not blink
                api.start({
                    from = {transparency = blink and 1 or 0};
                    to = {transparency = blink and 0 or 1};
                    config = {duration = 0.5}
                }):andThenCall(start)
            end

            start()
       end)
    end

    return roact.createElement(props.TextButton and 'TextButton' or "TextLabel", {
        Text = props.Text or "Text Label",
        Size = props.Size or UDim2.fromScale(1,1),
        Position =  props.Position or UDim2.new(),
        AnchorPoint = props.AnchorPoint or Vector2.new(),
        BackgroundTransparency = props.BackgroundTransparency or 1,
        TextScaled = TextScaled,
        LayoutOrder = props.LayoutOrder or 0,
        TextSize = textsize,
        AutomaticSize = props.AutomaticSize,
        RichText = props.RichText,
        ZIndex = props.ZIndex,
        --FontFace = Font.new("rbxassetid://12187607287"),
        TextWrapped = not TextScaled and true or false,
        FontFace = Font.fromEnum(Enum.Font.Fondamento),
        TextXAlignment = props.TextXAlignment,
        TextYAlignment = props.TextYAlignment,
        TextColor3 = props.TextColor3 or Color3.new(1,1,1),
        TextStrokeColor3 = props.TextStrokeColor3 or Color3.new(),
        TextStrokeTransparency = props.TextStrokeTransparency or 1,
        TextTransparency = props.Blinking and styles.transparency or props.TextTransparency,
        ["ref"] = ref,
        [roact.Event.Activated] = props[roact.Event.Activated]
    })
end)

return TextLabel