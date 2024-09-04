
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Utilities.Util)
local AvatarUtil = require(script.Parent.Parent.AvatarUtil)

local Clothing = {}

Clothing.Customization = {
    Type = 'Selection', 
    List = Util.GetChildrenInOrder(ReplicatedStorage.Assets.Avatar.Pants),
    Default = 1,
    EnableLabel = true,
    LayoutOrder = 5,
    DisplayName = 'Pants',
}

function Clothing.IsValid(value)
    return Clothing.Customization.List[value] ~= nil
end

function Clothing.Apply(rig: Model, value)
   return AvatarUtil.ApplyDirectly(rig, Clothing.Customization.List[value])
end

return Clothing





