local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Skin = {}

Skin.Customization = {
    Type = 'Selection', 
    List = {
    Color3.fromRGB(255, 211, 160):ToHex(),
    Color3.fromRGB(154, 127, 97):ToHex(),
    Color3.fromRGB(83, 69, 53):ToHex(),
    },
    Default = 1
}

if RunService:IsClient() then
    
    local Roact = require(ReplicatedStorage.Utilities.Roact)
    

    Skin.CustomView = function(props: {value: any, key: number})
        
        return Roact.createElement('Frame', {
            Size = UDim2.fromScale(1,1),
            BackgroundColor3 = props.value
        })

    end

end

return Skin





