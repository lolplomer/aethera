local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Items = require(ReplicatedStorage.GameModules.Items)

local InventoryController = Knit.CreateController { Name = "InventoryController" }

local EmptyInventory = {Content = {}, Equipment = {}}

local function YieldPlayerData()
    local PlayerDataController = Knit.GetController('PlayerDataController')
    return PlayerDataController:GetPlayerData().Replica
end

local function PlayerData()
    local PlayerDataController = Knit.GetController('PlayerDataController')
    return PlayerDataController.PlayerData and PlayerDataController.PlayerData.Replica
end

local function Inventory()
    local data = PlayerData()
    return data and data.Data.Inventory
end

function InventoryController:KnitStart()
    task.spawn(function()
        local Data = YieldPlayerData()
        Data:ListenToRaw(function(_, path, value)
            if path[4] == 'Equips' then
                local item = self:GetItem(value)
                local type = Inventory().Equipment[path[3]]
    
                self.EquipmentChanged:Fire(item,path[3],path[5],Items[item])
                if type.Position == path[5] then
                    self.EquipmentSwitched:Fire(item,path[3],path[5],Items[item])
                end
             --   print("Equip change",path,value)
            elseif path[4] == 'Position' then
                local item = self:GetEquipmentItem(path[3], value)
                self.EquipmentSwitched:Fire(item,path[3],value, Items[item])
               -- print("Position change",path,value)
            end
        end)
    end)
end

function InventoryController:ListenOnEquipmentSwitch(type, fn)
    return self.EquipmentSwitched:Connect(function(item, _type, position, itemInfo)
        if type == _type then
            fn(item, position, itemInfo)
        end
    end)
end

function InventoryController:GetItem(id)
    local inv = Inventory()
    return inv and inv.Content[id]
end

function InventoryController:GetItemInfo(itemData)
    return Items[itemData]
end

function InventoryController:GetEquipmentItem(type, position) 
  --  print('item id:',Inventory().Equipment[type].Equips[position],Inventory().Equipment[type])
  local inv = Inventory()
    return inv and self:GetItem(inv.Equipment[type].Equips[position])
end

function InventoryController:GetEquippedItems(type)
    local items = {}
    local inv = Inventory()
    if inv then
        for position_or_subtype, id in inv.Equipment[type].Equips do
            items[position_or_subtype] = self:GetItem(id)
        end    
    end
    
    return items
end

function InventoryController:GetMaxEquipCount(type)
    local TypeInfo = Items:GetTypeInfo(type)
    return TypeInfo.MaxEquips
end

function InventoryController:GetEquipPosition(type)
    local inv = Inventory()
    return inv and inv.Equipment[type].Position or 1
end

function InventoryController:GetEquippedItem(type)
    return self:GetEquipmentItem(type, self:GetEquipPosition(type))
end

function InventoryController:SwitchEquipment(type, newPosition)
    Knit.GetService('InventoryService'):SwitchEquipment(type, newPosition)
end

InventoryController.EquipmentChanged = Signal.new()
InventoryController.EquipmentSwitched = Signal.new()

return InventoryController
