
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Utilities.Util)
local AvatarUtil = require(script.Parent.Parent.AvatarUtil)

local Hair = {}

Hair.Customization = {
    Type = 'Selection', 
    List = Util.GetChildrenInOrder(ReplicatedStorage.Assets.Avatar.Hair),
    Default = 9,
    EnableLabel = true,
    LayoutOrder = 3,
    DisplayName = 'Secondary Hair',
    ReapplyWhenChanged = {'Hair2Color'}
}

function Hair.CustomLabel(value)
    local Model = Hair.Customization.List[value]
    if Model and not Model:FindFirstChild('Handle') then
        return 'None'
    end
    return value
end

function Hair.IsValid(value)
    return Hair.Customization.List[value] ~= nil
end

function Hair.Apply(rig: Model, value)
    return AvatarUtil.ApplyHair(rig, Hair.Customization.List[value], 'Hair2')
end

return Hair





