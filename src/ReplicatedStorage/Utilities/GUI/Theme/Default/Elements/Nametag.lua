local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local GUI = Knit.GetController('GUI')

local Roact = require(ReplicatedStorage.Utilities.Roact)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local BarImage = 'rbxassetid://17791872538'



return function (props)


    local char = props.Character
    local humanoid: Humanoid = char:WaitForChild"Humanoid"

    local styles, api = ReactSpring.useTrail(2, function(index)
        return {
            health = humanoid.Health/humanoid.MaxHealth - ((index-1)*0.02),
            
            delay = 3,
            config = {
                tension = 250/index,
                friction = 30,
                damping = 0.7,
            }
        }
    end) 

    Roact.useEffect(function()
        local conn = Trove.new()

        conn:Connect(humanoid.HealthChanged, function(health)
            api.start (function()
                return {
                    from =  {transparency = 0},
                    to = {transparency = 1, health = health/humanoid.MaxHealth}
                }
            end)
        end)

        return function ()
            conn:Destroy()
        end
    end)

    return Roact.createElement('Frame', {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1
    }, {

        Label = GUI.newElement('TextLabel', {
            Size = UDim2.fromScale(1,.5),
            Text = props.Character.Name,
            TextScaled = true,
            TextXAlignment = 'Left',
        }),

        Bar = Roact.createElement('ImageLabel', {
            Size = UDim2.fromScale(1,0.5),
            Position = UDim2.fromScale(0,0.5),
            BackgroundTransparency = 1,
            Image = BarImage,
        }, {
            Bar = GUI.newElement('ImageBar', {
                Value = styles[1].health,
                Size = UDim2.fromScale(1,1),
                Image = BarImage,
                ImageColor3 = Color3.fromHex('8AFF88'),
                ZIndex = 2,
            }),
            DiffBar = GUI.newElement('ImageBar', {
                Value = styles[2].health,
                Size = UDim2.fromScale(1,1),
                ImageTransparency = styles[2].transparency,
                Image = BarImage,
                ImageColor3 = Color3.new(1, 0.278431, 0.278431)   ,
                ZIndex = 1,
            }),
            Ratio = Roact.createElement('UIAspectRatioConstraint', {AspectRatio = 230/11})
        }),
       
    })
end