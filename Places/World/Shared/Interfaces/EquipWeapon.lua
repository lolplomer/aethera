local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)
local knit = require(ReplicatedStorage.Packages.Knit)
local GUI = knit.GetController('GUI')
local roactSpring = require(ReplicatedStorage.Packages.ReactSpring)
local InventoryController = knit.GetController('InventoryController')
local trove = require(ReplicatedStorage.Packages.Trove)

local function component(props)
    
    local itemData, setItemData = roact.useState(InventoryController:GetEquippedItem('Weapon'))
    local transparency = roactSpring.useSpring ({
        value = if props.Disabled then 1 else 0,
        config = {
            duration = 0.1  
        }
    })
    local text = roactSpring.useSpring({
        from = {value = 0},
        to = {value = 1},
        reset = true,
        config = {duration = props.Disabled and 0.1 or 5}
    })

    roact.useEffect(function()
        local _trove = trove.new()
        
        _trove:Add(InventoryController:ListenOnEquipmentSwitch('Weapon', function(newItemData)
            setItemData(newItemData)
        end))

        return _trove:WrapClean()
    end)

    local itemInfo = InventoryController:GetItemInfo(itemData)


    return roact.createElement('CanvasGroup', {
        Size = UDim2.fromScale(.18,.18),
        Position = UDim2.new(.98,0,.98,0),
        AnchorPoint = Vector2.new(1,1),
        BackgroundTransparency = 1,
        GroupTransparency = transparency.value
    }, {
        Equipped = GUI.newElement('Slot', {
            ItemData = itemData,
            Position = UDim2.fromScale(.5,.5),
            Size = UDim2.fromScale(0.6,0.6),
            AnchorPoint = Vector2.new(.5,.5),
        }),
        ItemName = GUI.newElement('TextLabel', {
            Size = UDim2.fromScale(1,.2),
            Text = itemInfo and itemInfo.DisplayName or 'None',
            TextTransparency = text.value
        }),
        Right = GUI.newElement('KeybindLabel', {
            Keybind = 'WeaponChange',
            Position = UDim2.fromScale(.9,.7),
            AnchorPoint = Vector2.new(1,.5),
            DisableLabel = true,
        }),
        ratio = roact.createElement('UIAspectRatioConstraint')
    })
end

return {
    Component = component
}   