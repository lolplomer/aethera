local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarUtil = {}

local Util = require(ReplicatedStorage.Utilities.Util)

function AvatarUtil.ApplyHair(rig:Model, Hair:Accessory, Name:string)
    local Clone = Hair:Clone()
    Clone.Name = Name
    local Handle = Clone:FindFirstChild('Handle')
    if Handle then
        Handle.Anchored = false
    end
    Clone.Parent = rig

    
    Util.AttachAccessory(Clone, rig)
    
    return function ()
        Clone:Destroy()
    end
end

function AvatarUtil.ApplyDirectly(rig: Model, model)
    model = model:Clone()

    model.Parent = rig
    
    return function ()
        model:Destroy()
    end
end

function AvatarUtil.ApplyColor(rig, modelName, color)
    local model = rig:FindFirstChild(modelName)
    local color = Color3.fromHex(color)
    if model then
        for _,v in model:GetChildren() do
            if v:IsA('BasePart') then
                v.Color = color
            end
        end
    end
end

return AvatarUtil