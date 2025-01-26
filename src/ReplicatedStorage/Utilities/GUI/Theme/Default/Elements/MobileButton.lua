local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local roact = require(ReplicatedStorage.Utilities.Roact)

local e = roact.createElement
local useEffect = roact.useEffect
local useCallback = roact.useCallback

local function isTouch(input: InputObject)
    return input.UserInputType == Enum.UserInputType.Touch
end

local function component(props)

    local button = props.Button

    local onInputBegan = useCallback(function(input: InputObject)
        if isTouch(input) then
            button.PressBegan:Fire(input)
        end
    end, {button})

    local onInputEnded = useCallback(function(input: InputObject)
        if isTouch(input) then
            button.PressEnded:Fire(input)
        end
    end, {button})

    useEffect(function()
        local inputEndedConnection = UserInputService.InputEnded:Connect(onInputEnded)
        return function ()
            inputEndedConnection:Disconnect()
        end
    end, {button})

    return e('ImageButton', {
        Size = UDim2.fromScale(props.Scale, props.Scale),
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        [roact.Event.InputBegan] = onInputBegan,
        Image = "rbxassetid://136470109213437",
        
    }, {e("UIAspectRatioConstraint")})
end

return component