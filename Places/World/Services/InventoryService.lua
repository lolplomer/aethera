
--[[
    InventoryService

    Game service used to handle player's data of Inventory
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage.Packages
local knit = require(packages.Knit)

local gameModules = game.ReplicatedStorage.GameModules
local items = require(gameModules.Items)

local service = knit.CreateService{
    Name = script.Name,
    Client = {
        Equip = knit.CreateSignal();
        Unequip = knit.CreateSignal();
    }
}

local PlayerDataService

local misc = game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Misc')
local util = require(ReplicatedStorage.Utilities.Util)
local Status = require(misc.Status)

local Inventories = {}
local Equipments = {}

local DEFAULT_LOOT_MODEL = ReplicatedStorage.Models.DefaultLootDrop

local RateLimiter = require(ReplicatedStorage.Madwork.RateLimiter).NewRateLimiter(3)

local Drops = util.new('Folder', {
    Name = 'Drops',
    Parent = workspace
})

-- Private Find function to Find value in a dictionary table
local function Find(T, value)
    for index, v in T do
        if value == v then
            return index
        end
    end
end



--[[
    Equipment Class
    This handles and apply the equipment (such as weapon, armor, etc) to player
]]
local Equipment = {} do 
    Equipment.__index = Equipment

    -- Private Equipment function to create an empty container of equipments
    local function BuildEmptyEquipment()
        local equipment = {}
        for Type, _ in items.Type do
            local Method = items:GetTypeMethod(Type)
            if Method == 'Single' then
                equipment[Type] = {
                    Data = {
                        Character = nil,
                        Position = 1,
                        Model = nil,
                        ItemId = nil
                    }
                }
            else
                equipment[Type] = {
                    Data = {
                        Character = nil,
                        Models = {},
                    }
                }
            end
        end
        return equipment
    end

    -- Equipment Constructor
    function Equipment.new(Inventory)
        local equipment = setmetatable({
            Inventory = Inventory,
            Replica = Inventory.Replica,
            Player = Inventory.Player,
            Equipment = BuildEmptyEquipment(),
        }, Equipment)

        return equipment
    end

    -- Reupdates all equipment
    function Equipment:UpdateAll()
        for Type, _ in self.Inventory.Equipment do
            self:Update(Type)
        end
    end

    -- Creates a Model of an item and attach it to the player's character
    function Equipment:_createModel(Metadata, Data, Character)
        local TypeInfo = Metadata:GetTypeInfo()

        local Model: Model = Metadata:GetModel():Clone()
        TypeInfo.ApplyInstance(Metadata, Model, Character, self.Player) -- attaches the model
        Data.Model = Model
    end  

    -- Applies/replaces a model of equipment, if a model is already exist it will get replaced with a new one
    function Equipment:_applyModel(ItemId, Type, subtype_or_pos)
        local TypeInfo = items.Type[Type]
        local Method = TypeInfo.Method
        local Data = self.Equipment[Type].Data
        local inventory = self.Inventory

        local Metadata = items[inventory:GetItem(ItemId)]
        
        -- Single Method = Kind of equipment that does not have subtypes (we call each equipment a type)
        -- In this method we use a 'Position' instead which is a pointer of what is currently equipped and we can switch to
        -- other Position to change equipment of the type (if that other Position has another item equipped)
        if Method == "Single" then
            if Data.Model then
                Data.Model:Destroy()
                Data.Model = nil
            end
            if ItemId and Metadata then
                self:_createModel(Metadata, Data, self.Player.Character)
            end

            Data.ItemId = ItemId
            Data.Position = subtype_or_pos

        -- Multiple Method = Kind of equipment that does have subtypes
        -- Which means we can equip as many items as we want under the same type but different subtypes
        elseif Method == "Multiple" then

            local Models = Data.Models
            local _subtype = subtype_or_pos

            if not Models[_subtype] then
                Models[_subtype] = {}
            end

            if Models[_subtype].ItemId ~= ItemId or Data.Character ~= self.Player.Character then

                local ModelData = Models[_subtype]

                if ModelData.Model then
                    ModelData.Model:Destroy()
                    ModelData.Model = nil
                end
                
                if ItemId and Metadata then
                    self:_createModel(Metadata, ModelData, self.Player.Character)
                end

                ModelData.ItemId = ItemId
            end

        end
    end

    -- Reupdates stats of an item (stats like ATK, DEF, SPD, etc)
    function Equipment:_updateStats(ItemId, Type, Subtype)
        
        local inventory = self.Inventory
        
        local StatService = knit.GetService("StatService")
        local PlayerStats = StatService:GetStats(self.Player) 

        local ModifierName = `{Type}{Subtype and ' '..Subtype or ''}`
        local Item = inventory:GetItem(ItemId)

        if ItemId and Item then
            
            local _Data = Item[4]
            local Metadata = items[Item]

            local Mainstats = util.ReadItemStats(Metadata.Equipment.Stats, _Data.Lvl)
            local Substats = util.ReadItemStats(_Data.Substats)

            PlayerStats:SetModifiers {
                [`{ModifierName} Stats`] = Mainstats,
                [`{ModifierName} Substats`] = Substats
            }
        else
            PlayerStats:RemoveModifier(`{ModifierName} Stats`)
            PlayerStats:RemoveModifier(`{ModifierName} Substats`)
        end
    end

    -- Updates an equipment
    function Equipment:Update(Type, Subtype)
        if not self.Player.Character then
            return
        end
        --print('Updating',Type,'Equipments')
        local Current = self.Equipment[Type]
        
        local TypeInfo = items.Type[Type]
        local Method = TypeInfo.Method
   
        local inventory = self.Inventory
        local EquipData = inventory.Equipment[Type]

        local Data = Current.Data
        local PreviousChar = Data.Character
        local DIFFERENT_CHARACTER = PreviousChar ~= self.Player.Character


        if Method == "Single" then
            --[[
                Current.Data: {
                    Model: Instance,
                    ItemId: number,
                    Character: Model,
                    Position: number,
                }
            ]]
            
            local Position = EquipData.Position
            local ItemId = EquipData.Equips[Position]

            local DIFFERENT_ITEM_ID_BUT_SAME_POS = (Position == Data.Position and Data.ItemId ~= ItemId)
            local DIFFERENT_POS = (Position ~= Data.Position)
            local SHOULD_APPLY_MODEL = DIFFERENT_ITEM_ID_BUT_SAME_POS or DIFFERENT_POS or DIFFERENT_CHARACTER

            if SHOULD_APPLY_MODEL then
                self:_applyModel(ItemId, Type, Position)
            end

            self:_updateStats(ItemId, Type)

        elseif Method == "Multiple" then
            --[[
                Current.Data: {
                    Models: {
                        [Subtype]: {
                            ItemId: number,
                            Model: number
                        }
                    },
                    Character: Model,
                }
            ]]

            if Subtype == nil or DIFFERENT_CHARACTER then
                for _subtype, ItemId in EquipData.Equips do
                    self:_applyModel(ItemId, Type, _subtype)
                    self:_updateStats(ItemId, Type, _subtype)
                end
            elseif Subtype then
                local ItemId = EquipData.Equips[Subtype]
                self:_applyModel(ItemId, Type, Subtype)
                self:_updateStats(ItemId, Type, Subtype)
            end
        end

        Data.Character = self.Player.Character
    end


end

-- Inventory Class
local Inventory = {} do
    Inventory.__index = Inventory

    -- Inventory Constructor
    function Inventory.new(DataReplica)
        local inventory = setmetatable({
            Content = DataReplica.Inventory.Content,
            Equipment = DataReplica.Inventory.Equipment,
            Player = DataReplica.Replica.Tags.Player,
            Replica = DataReplica.Replica,
        }, Inventory)

        local equipment = Equipment.new(inventory)
        inventory.ActiveEquipment = equipment

        return inventory, equipment
    end

    -- Find's first item that is named itemName
    -- index 1 of item is name
    function Inventory:GetFirstItem(itemName)
        for id, item in self.Content do
            if item[1] == itemName then
                return id, item
            end
        end
    end

    -- Gets an item by id
    function Inventory:GetItem(id)
        return self.Content[id]
    end

    -- Removes an item by the name, this will remove the first item it found
    -- specify amount to remove 'amount' of items
    function Inventory:RemoveItemByName(itemName, amount)
        amount = amount or 1
    
        local id = self:GetFirstItem(itemName)
    
        if not id then
            return warn(`{itemName} didn't exist on {self.Player}'s inventory`)
        end
       
        self:RemoveItemById(id, amount)
    end

    function Inventory:UnequipByItemId(id)
        local type, position_or_subtype = self:GetEquipped(id)
        --print(type, position_or_subtype, id, 'removing')
        if type and position_or_subtype then
            self:UnequipItem(type, position_or_subtype)
        end
    end

    -- Removes 'amount' of item by the id
    function Inventory:RemoveItemById(id, amount)
        local Item = self:GetItem(id)

        if not Item then
            return
        end

        self:UnequipByItemId(id)

        if amount == true then
            self.Replica:SetValue({'Inventory','Content',id}, nil)
        else
            local newAmount = Item[3]-amount
            if newAmount <= 0 then
                --playerData.Replica:ArrayRemove({"Inventory", "Content"},id)
                self.Replica:SetValue({"Inventory",'Content',id}, nil)
            else
                self.Replica:SetValue({"Inventory", "Content",id,3},newAmount)
            end
        end
    end

    -- Creates 'Amount' of new items in the inventory,
    -- if Data is specified, the item won't be stacked which means Amount will not be necessary
    function Inventory:AddItem(ItemName, Amount, Data)
        Amount = Amount or 1

        local item = items[ItemName]
        if not item then
            warn(`Failed to add {ItemName} to {self.Player}'s inventory: item does not exist`)
            return Status.Failed("ITEM_NOT_EXIST")
        end
    
        if item.Stackable == true then
            local id, foundItem = self:GetFirstItem(ItemName)
            if id == nil then
                local ItemData = {ItemName,item.Category,Amount}
                id = self.Replica:ArrayInsert({"Inventory", "Content"}, ItemData)
    
                return Status.Success({
                    Id = id,
                    ItemData = ItemData
                })
            else
                warn(id, typeof(id), "Inventory", "Content")
                local newAmount = foundItem[3] + Amount
                self.Replica:SetValue({"Inventory", "Content",id,3},newAmount)
    
                return Status.Success({
                    Id = id,
                    ItemData = foundItem,
                    Stacked = true
                })
            end
        else
            Data = Data or (item.Data and table.clone(item.Data)) or {}
    
            if item.Equipment then
                Data.Lvl = Data.Lvl or 1
                Data.Substats = Data.Substats or {}
            end
    
            local itemData = {ItemName,item.Category,1,Data}
            local id = self.Replica:ArrayInsert({"Inventory", "Content"}, itemData)
    
            return Status.Success({
                Id = id,
                ItemData = itemData,
            })
        end
    end

    function Inventory:GetData(itemId)
        local item = self:GetItem(itemId)
        if item then
            return item[4]
        end
    end

    function Inventory:DropItem(itemId, amount, CF)
        
        local item = self:GetItem(itemId)

        if item then
            local name = item[1]
            local data = item[4] and table.clone(item[4])
            amount = math.min(amount, data[3])

            self:RemoveItemById(itemId, amount)

            service:DropItem(name, self.Player.Character:GetPivot() * CFrame.new(0, 0, -3), amount, data)
        end
        


    end

    -- Verify and validate the items to prevent the player having illegal items such as
    -- items that have wrong category, nonexistent in the items module, etc
    function Inventory:VerifyItems()
        for id, item in self.Content do
            local metadata = items[item[1]]
            if metadata then
                if item[2] ~= metadata.Category then
                    self.Replica:SetValue({"Inventory", "Content",id,2},metadata.Category)
                end
            end
        end
    end

    -- Unequips the equipment Type (uses the Equipment class)
    function Inventory:UnequipItem(Type, position_or_subtype)
        if not Type or not position_or_subtype then return end

        if self.Equipment[Type].Equips[position_or_subtype] then
            self.Replica:SetValue({'Inventory','Equipment',Type,'Equips',position_or_subtype}, nil)
            
            self.ActiveEquipment:Update(Type, position_or_subtype)
        end
    end

    -- Switches 'Single' Method Equipment to other Position
    function Inventory:SwitchEquipment(Type, position)
        if typeof(position) == "number" and self.Equipment[Type] then
            self.Replica:SetValue({"Inventory","Equipment",Type,"Position"},position)
            self.ActiveEquipment:Update(Type)
        end
    end

    function Inventory:IncrementEquipment(Type, value)
        local TypeInfo = items:GetTypeInfo(Type)
        local max = TypeInfo.MaxEquips

        local current = self.Equipment[Type].Position
        local new = current + value

        if new > max then
            new = 1
        elseif new < 1 then
            new = max
        end

        self:SwitchEquipment(Type, new)
    end

    function Inventory:PreviousEquipment(Type)
        self:IncrementEquipment(Type, -1)
    end

    function Inventory:NextEquipment(Type)
        self:IncrementEquipment(Type, 1)
    end

    -- Equips an item, position is only necessary if the item type method is Single
    function Inventory:EquipItem(id, position)
        local Item = self:GetItem(id)

        if not Item then
            return Status.Failed("NOT_EXIST")
        end

        local Metadata = items[Item]
        if Metadata then
            local Type, Subtype = Metadata:GetType()
            if Type then
                local TypeInfo = Metadata:GetTypeInfo()
                if TypeInfo.Method == "Single" then

                    local _position = Find(self.Equipment[Type].Equips, id)

                    if _position then
                        self.Replica:SetValue({'Inventory','Equipment',Type,'Equips',_position},nil)
                    end
                    self.Replica:SetValue({'Inventory','Equipment',Type,'Equips',position},id)
                elseif TypeInfo.Method == "Multiple" then
                    local _id = self.Equipment[Type].Equips[Subtype] 
                    if _id ~= id then
                        self.Replica:SetValue({'Inventory','Equipment',Type,'Equips',Subtype}, id)    
                    end
                end
                self.ActiveEquipment:Update(Type, Subtype)
            else
                return Status.Failed("NOT_EQUIPMENT") 
            end
        else
            return Status.Failed("ITEM_NOT_EXIST") 
        end
        return Status.Success({Metadata = Metadata})
    end


    function Inventory:GetEquipped(id)
        local Item = self:GetItem(id)
        local Metadata = items[Item]
        if Metadata then
            local Type, Subtype = Metadata:GetType()
            if Type then
                local TypeInfo = Metadata:GetTypeInfo()
                
                for position_or_subtype, _id in self.Equipment[Type].Equips do
                    if _id == id then
                        return Type, position_or_subtype
                    end
                end
            end
        end
    end
end

-- Private function to handle player joins
local function OnPlayerAdded(player:Player, data)
    local PlayerInv, equipment = Inventory.new(data)
    Inventories[player] = PlayerInv
    Equipments[player] = equipment

    -- Cleans up inventory and equipment object once their Data Replica is destroyed
    -- Data Replica destroyed can only because the player is leaving the game
    data.Replica:AddCleanupTask(function()
        Inventories[player] = nil
        Equipments[player] = nil
    end)

    -- Reupdates all the equipment everytime player resets their character
    util.CharacterAdded(player, function()
        equipment:UpdateAll()
    end,false)

    -- Simple admin commands for testing/debugging
    player.Chatted:Connect(function(message)
	    local args = message:split(" ")
	    if args[1] == 'additem' then
	        local itemName = args[2]
	        local amount = tonumber(args[3])
	        PlayerInv:AddItem(itemName, amount)
	    elseif args[1] == 'removeitem' then
	        local itemName = args[2]
	        local amount = tonumber(args[3])
	        PlayerInv:RemoveItemByName(itemName, amount)
        elseif args[1] == "equip" then
            local id = tonumber(args[2])
            local pos = tonumber(args[3]) or 1
            PlayerInv:EquipItem(id, pos)
        elseif args[1] == 'equipment' then
            print(equipment.Equipment)
        elseif args[1] == 'equippos' then
            local position = tonumber(args[2])
            PlayerInv:SwitchEquipment("Weapon",position)
        elseif args[1] == 'drop' then
            print('dropping')
            service:DropItem(args[2], player.Character:GetPivot() * CFrame.new(0,0,-3), tonumber(args[3]))
		end
	end)

    -- Adds some items to player inventory for testing
    PlayerInv:AddItem("CycloneSword")
    
    PlayerInv:AddItem('Auri')
    PlayerInv:AddItem('ScarletDuskChestplate')
    PlayerInv:AddItem('ScarletDuskLeggings')

    local itemStatus = PlayerInv:AddItem('BasicArmor')
    PlayerInv:EquipItem(itemStatus.Id)

    local itemStatus = PlayerInv:AddItem("BasicSword")
    PlayerInv:EquipItem(itemStatus.Id, 1)
end

-- Builds an Empty Equipment Data
local function BuildEmptyEquipment()
    local equipment = {}
    for Type, _ in items.Type do
        equipment[Type] = {
            Equips = {},
            Position = 1,
        }
    end
    return equipment
end

-- Gets player inventory, if nonexistent it waits (result will never be nil)
function service:GetInventory(player)
    return util.GetAsync(Inventories, player, 'Inventory')
end

function service:DropItem(itemName, CF, amount, data)

    data = data and table.clone(data)
    amount = amount or 1
    --self:RemoveItemById(itemId, amount)

    local metadata = items[itemName]
    if not metadata then return end
    
    
    local model, primarypart = metadata:BuildViewportItem(true)
    if not model then
        model = ReplicatedStorage.Models.DefaultLootDrop:Clone()
        primarypart = model.PrimaryPart
    end


    model.Parent = Drops
    model:PivotTo(CF)
    
    ReplicatedStorage.Models.DropHighlight:Clone().Parent = model

    local ProximityPrompt: ProximityPrompt, finish = knit.GetService('KeybindService'):SetObjectInteract(primarypart, `Pick up {itemName} ({amount}x)`)
    ProximityPrompt.HoldDuration = 0.5
    
    local Triggered = false
    ProximityPrompt.Triggered:Connect(function(playerWhoTriggered)
        if Triggered then return end

        local inventory = service:GetInventory(playerWhoTriggered)
        inventory:AddItem(itemName, amount, data)

        finish()
        model:Destroy()
    end)
end

-- Initiates the Service
function service:KnitInit()
    PlayerDataService = knit.GetService("PlayerDataService")
    local KeybindService = knit.GetService('KeybindService')

    PlayerDataService:RegisterDataIndex("Inventory", {
        Content = {}, 
        Equipment = BuildEmptyEquipment()
    })

    KeybindService:SetDefaultKeybind('Inventory', Enum.KeyCode.B)


    self.Client.Equip:Connect(function(player, id, position)
        local PlayerInv = self:GetInventory(player)
        local status = PlayerInv:EquipItem(id, position)
        if status.Success then
            local TypeInfo = status.Metadata:GetTypeInfo()
            if TypeInfo and TypeInfo.Method == 'Single' then
                local Type = status.Metadata:GetType()
                PlayerInv:SwitchEquipment(Type, position)    
            end
        end
    end)

    self.Client.Unequip:Connect(function(player, type, subtype_or_pos)
        local PlayerInv = self:GetInventory(player)
        PlayerInv:UnequipItem(type, subtype_or_pos)
    end)

    PlayerDataService.PlayerAdded:Connect(OnPlayerAdded)
end

function service.Client:SwitchEquipment(player, type, position)
    if RateLimiter:CheckRate(player) then
        local PlayerInv = service:GetInventory(player)
        PlayerInv:SwitchEquipment(type, position)
    end
end

return service