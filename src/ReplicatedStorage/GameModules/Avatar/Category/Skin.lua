
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Skin = {}

local BodyParts = {
    'Head', 'UpperTorso', 'LowerTorso',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot'
}

Skin.Customization = {
    Type = 'Selection', 
    List = {
        Color3.fromRGB(255, 211, 160),
        Color3.fromRGB(154, 127, 97),
        Color3.fromRGB(83, 69, 53),
        Color3.fromRGB(194, 194, 194)
    },
    Default = 1,
    EnableLabel = false,
    LayoutOrder = 1,
    DisplayName = 'Skin Color'
}

function Skin.IsValid(value)
    return Skin.Customization.List[value] ~= nil
end

function Skin.Apply(rig: Model, value)

    value = Skin.Customization.List[value]

    for _, Name in BodyParts do
        rig[Name].Color = value
    end
end

if RunService:IsClient() then
    
    local Roact = require(ReplicatedStorage.Utilities.Roact)
    
    Skin.CustomView = function(props: {value: any, key: number})
        
        return Roact.createElement('Frame', {
            Size = UDim2.fromScale(1,1),
            BorderSizePixel = 0,
            BackgroundColor3 = props.value:map(function(value)
                return Skin.Customization.List[value]
            end),
        }, {
            Roact.createElement('UICorner')
        })

    end

end

return Skin





