

local AvatarUtil = require(script.Parent.Parent.AvatarUtil)

local Hair = {}

Hair.Customization = {
    Type = 'Color', 
    List = {},
    Default = Color3.fromRGB():ToHex(),
    LayoutOrder = 7,
    DisplayName = 'Secondary Hair Color',
    
}

function Hair.IsValid(value)
    return pcall(Color3.fromHex, value)
end

function Hair.Apply(rig: Model, value)
    return AvatarUtil.ApplyColor(rig, 'Hair2', value)
end

return Hair





