local CategoryItems = {}
local UnmappedItems = {}

local Rating = require(script.Parent:WaitForChild"Rating")
local EquipType = require(script:WaitForChild"EquipmentType")

local Items = {
    Category = CategoryItems,
    Items = UnmappedItems,
    Type = EquipType,
    CategoryCount = 0,
    Settings = require(script:WaitForChild"CategorySettings")
}

local function WarnInvalidItem(name, category, reason)
    warn(`Invalid Item {name} from {category}: {reason}`)
end

local ItemClass = {}
ItemClass.__index = ItemClass

function ItemClass:GetRating()
    return Rating[self.Rating] or Rating.Default
end

function ItemClass:GetType()
    if self.Equipment then
        return self.Equipment.Type, self.Equipment.Subtype
    end
end

function ItemClass:GetTypeInfo()
    return self.Equipment and self.Equipment.TypeInfo
end

function ItemClass:GetModel()
    return self.Model and game.ReplicatedStorage.Models[self.Model]
end

local ModuleClass = {}

function ModuleClass:__index(index)
    if typeof(index) == "table" then
        return self[index[1]]
    end
    return ModuleClass[index] or Items[index] or Items.Items[index]
end

function ModuleClass:GetItems(category)
    if not category then
        return Items.Items
    else
        return Items.Category[category]
    end
end

function ModuleClass:GetTypeMethod(Type)
    return Items.Type[Type].Method
end

function ModuleClass:GetTypeInfo(Type)
    return Items.Type[Type]
end

local function Initialize()

    for _, Info in Items.Type do
        Info.SubtypeCount = 0
        for _,_ in Info.Subtype do
            Info.SubtypeCount += 1
        end
    end

    for _, categoryFolder in script:GetChildren() do
        if not categoryFolder:IsA('Folder') then
            continue
        end
        local categoryName = categoryFolder.Name
        CategoryItems[categoryName] = {}
        Items.CategoryCount += 1
        for _, itemModule in categoryFolder:GetChildren() do
            local itemName = itemModule.Name
            if itemModule:IsA"ModuleScript" then

                local item = require(itemModule)
                if Items[itemName] then
                    WarnInvalidItem(itemName, categoryName, `Cannot use name {itemName}`)
                    continue
                elseif UnmappedItems[itemName] then
                    local sameNameItem = UnmappedItems[itemName]
                    WarnInvalidItem(itemName, categoryName, `Item with the name {itemName} already exist from category {sameNameItem.Category}`)
                    continue
                elseif item.Equipment then
                    if not EquipType[item.Equipment.Type] then
                        WarnInvalidItem(itemName, categoryName, `Invalid equipment type {item.Equipment.Type}`)
                        continue
                    elseif not EquipType[item.Equipment.Type].Subtype[item.Equipment.Subtype] then
                        WarnInvalidItem(itemName, categoryName, `Invalid equipment type {item.Equipment.Subtype}`)
                        continue
                    end
                    item.Equipment.TypeInfo = EquipType[item.Equipment.Type]
                    if not item.Equipment.Stats then
                        item.Equipment.Stats = {}
                    end
                end

                

                if item.Stackable == true and item.Data then
                    warn(`{itemName} ({categoryName}) won't be stackable because it's Data exists`)
                    item.Stackable = false
                end

                setmetatable(item, ItemClass)

                item.Description = item.Description:gsub("[\n\r\t]+","")
                item.Category = categoryName
                item.Rating = item:GetRating().Key
                
                CategoryItems[categoryName][itemName] = item
                UnmappedItems[itemName] = item
            else
                WarnInvalidItem(itemModule.Name, categoryName, "Instance is not a ModuleScript")
            end
        end
    end
end

Initialize()

return setmetatable({}, ModuleClass)