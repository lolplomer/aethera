local ReplicatedStorage = game:GetService("ReplicatedStorage")
local knit = require(ReplicatedStorage.Packages.Knit)
local GUI = knit.GetController('GUI')
local roact = require(ReplicatedStorage.Utilities.Roact)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)

return function (props)

    local styles, api = ReactSpring.useSpring(function()
        return {
            value = 0,
            config = {
                tension = 120,
                friction = 10,
            }
        }
    end)

    local transparency, transparency_api = ReactSpring.useSpring(function()
        return {value = 1}
    end)

    roact.useEffect(function()
        transparency_api.start {value = 0, config = {duration = 0.15}}
        task.delay(.6, transparency_api.start, {value = 1, config = {duration = 0.7}})

        api.start{value = 1}
        
        --api.start {immediate = false, value = 1}
    end)
    
    return GUI.newElement('TextLabel', {
        Text = `<b>{props.Damage}</b>`,
        --Size = UDim2.fromScale(1,1),
        TextStrokeTransparency = 0.65,
        RichText = true,
        TextColor3 = props.Crit and Color3.new(1, 0.388235, 0.388235) or Color3.new(1,1,1),
        TextTransparency = transparency.value,
        Position = styles.value:map(function(value)
            return UDim2.fromScale(0.5, 0.5-math.sin(value * math.pi/4)/2)
        end),
        AnchorPoint = Vector2.new(.5,.5),
        Size = styles.value:map(function(value)
            return UDim2.fromScale(1+value/4,1+value/4)
        end),
    })

end