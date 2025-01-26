local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.Packages

local knit = require(packages.Knit)
local roactSpring = require(packages.ReactSpring)
local roact = require(ReplicatedStorage.Utilities.Roact)
local trove = require(packages.Trove)

local GUI = knit.GetController('GUI')
local InvController = knit.GetController('InventoryController')

return {
    HUD = true,
    
    Component = function(props)

        print('Updating Weapon Radial')

        local updateCounter, update = roact.useState(0)

        roact.useEffect(function()
            local _trove = trove.new()

            _trove:Connect(InvController.EquipmentChanged, function()
                update(updateCounter + 1)
            end)

            return _trove:WrapClean()
        end)

        local items = {}

        for position = 1, InvController:GetMaxEquipCount('Weapon') + 1 do
            items[position] = GUI.newElement('Slot', {ItemData = InvController:GetEquipmentItem('Weapon', position)})
        end

        return GUI.newElement('BaseRadialSelector', {
            Keybind = 'WeaponChange',
            Items = items,
            Disabled = props.Disabled,
            Selection = InvController:GetEquipPosition('Weapon'),
            SelectionChanged = function(position)
                InvController:SwitchEquipment('Weapon', position)
            end,
        })
    end
}