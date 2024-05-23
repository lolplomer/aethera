local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Items = require(ReplicatedStorage.GameModules.Items)

local InventoryController = Knit.CreateController { Name = "InventoryController" }

local function PlayerData()
    local PlayerDataController = Knit.GetController('PlayerDataController')
    return PlayerDataController:GetPlayerData().Replica
end

local function Inventory()
    return PlayerData().Data.Inventory
end

function InventoryController:KnitStart()
    local Data = PlayerData()
    print(Data)
    Data:ListenToRaw(function(_, path, value)
        if path[4] == 'Equips' then
            local item = self:GetItem(value)
            local type = Inventory().Equipment[path[3]]

            self.EquipmentChanged:Fire(item,path[3],path[5],Items[item])
            if type.Position == path[5] then
                self.EquipmentSwitched:Fire(item,path[3],path[5],Items[item])
            end
            print("Equip change",path,value)
        elseif path[4] == 'Position' then
            local item = self:GetEquipmentItem(path[3], value)
            self.EquipmentSwitched:Fire(item,path[3],value, Items[item])
            print("Position change",path,value)
        end
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
    return Inventory().Content[id]
end

function InventoryController:GetEquipmentItem(type, position) 
  --  print('item id:',Inventory().Equipment[type].Equips[position],Inventory().Equipment[type])
    return self:GetItem(Inventory().Equipment[type].Equips[position])
end

function InventoryController:GetEquippedItem(type)
    return self:GetEquipmentItem(type, Inventory().Equipment[type].Position)
end

function InventoryController:KnitInit()
    
end

InventoryController.EquipmentChanged = Signal.new()
InventoryController.EquipmentSwitched = Signal.new()

return InventoryController
