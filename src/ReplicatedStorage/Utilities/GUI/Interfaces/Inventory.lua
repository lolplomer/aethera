local GUIUtil = game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"GUI"
local roact = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Roact")
local knit = require(game.ReplicatedStorage:WaitForChild"Packages":WaitForChild"Knit")

local WindowManager = require(GUIUtil:WaitForChild"WindowManager")
local FrameManager = require(GUIUtil:WaitForChild"FrameManager")
local IconManager = require(GUIUtil:WaitForChild"IconManager")

local items = require(game.ReplicatedStorage:WaitForChild"GameModules":WaitForChild"Items")
local categorySettings = items.Settings

local Window = WindowManager.new(script.Name, {
    Keybind = 'Inventory'
})
local MasterFrame = Window.Frame

local InvUtil = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"InventoryUtil")

local GUI = knit.GetController "GUI"
local PlayerDataController = knit.GetController "PlayerDataController"


local EquipPopup = FrameManager.new(UDim2.fromScale(1,1))

EquipPopup
--:addBackground()
:vertical()
:split({0.4,0.6}, function(title, buttonContainer)
    title:addText('Select equip position', UDim2.fromScale(1,1))

    buttonContainer
    :horizontal()
    :setOffset(10)
    :center()
    :addElement(function(_, props)
        local Metadata = items[props.ItemData]
        local TypeInfo = Metadata:GetTypeInfo()

        local InventoryService = knit.GetService("InventoryService")
        local btns = {}
        for i = 1,TypeInfo.MaxEquips do
            btns[i] = GUI.newElement("TextButton", {
                Text = i,
                Size = UDim2.new(1/TypeInfo.MaxEquips,-10,1,0),
                Callback = function()
                    InventoryService.Equip:Fire(props.Id, i)
                    GUI:ClosePopup('EquipPopup')
                end
            })
        end
        return roact.createFragment(btns)
    end)
end)

function Window:didUpdate()
   -- print('Inventory updated')
    GUI:ClosePopup('EquipPopup')
end

function Window:init()
    Window:setState{
        Category = categorySettings.StartingCategory
    }
end

local function GetSelectedItemData()
    local itemIndex = Window.state.Selected
    local itemData
    if itemIndex then
        local PlayerData = PlayerDataController:GetPlayerData()
        itemData = PlayerData.Inventory.Content[itemIndex]
    end 
    return itemData, itemIndex
end

local EquipButtonComponent = roact.PureComponent:extend('EquipButtonComponent')

function EquipButtonComponent:init()
    self:setState{update = 0}
end

function EquipButtonComponent:render()
    local itemData, id = self.props.ItemData, self.props.Id
    --local itemData, id = GetSelectedItemData()
    local Metadata = items[itemData]

    if Metadata then
        local Type, _ = Metadata:GetType()

        if not Type then return end
        local TypeInfo = Metadata:GetTypeInfo()

        local Equipped, _Type, Subtype_or_Pos = InvUtil.GetEquipStatus(PlayerDataController:GetPlayerData().Inventory, id)

        return GUI.newElement("TextButton", {
            Text = Equipped and "Unequip" or "Equip",
            Size = UDim2.fromScale(1,1),
            Callback = function()
                if not Equipped then
                    if TypeInfo.Method == 'Single' then
                        GUI:CreatePopup(EquipPopup:render(1, {ItemData = itemData, Id = id}), 'EquipPopup')
                    elseif TypeInfo.Method == 'Multiple' then
                        local InventoryService = knit.GetService("InventoryService")
                        InventoryService.Equip:Fire(id)
                    end
                else
                    local InventoryService = knit.GetService("InventoryService")
                    InventoryService.Unequip:Fire(_Type, Subtype_or_Pos)
                end
            end,
            Selected = Equipped
        })
    end
end

function EquipButtonComponent:didMount()
    local playerData = PlayerDataController:GetPlayerData()
    self.itemChangeConnection = playerData.Replica:ListenToRaw(function(_, path)
        if path[1] == 'Inventory' and path[2] == 'Equipment' then
            self:setState{update = self.state.update + 1}
        end
    end)
end

function EquipButtonComponent:willUnmount()
    if self.itemChangeConnection then
        self.itemChangeConnection:Disconnect()
        self.itemChangeConnection = nil
    end
end

MasterFrame
:horizontal()
:split({0.2,0.5,0.3}, function(leftSide, itemList, mainItemInfo)

    leftSide
    :split({0.8,0.2}, function(categoryList, equipmentBtnContainer)
        categoryList
        :rename("Category")
        :center("Horizontal")
        :vertical()
        :div(0.03)
        :addElement(function()
            local CategoryButtons = {}
            for category, _ in items.Category do
                CategoryButtons[category] = GUI.newElement("TextButton", {
                    Text = category,
                    Selected = Window.state.Category == category,
                    Size = UDim2.fromScale(1,0.1),
                    Callback = function()
                        Window:setState{Category = category, Selected = roact.None}
                    end
                }) 
            end
            return roact.createFragment(CategoryButtons)
        end)

        equipmentBtnContainer
        --:center()
        :addElement(function()
            return GUI.newElement("Icon", {
                Size = UDim2.fromScale(1,1),
                Padding = -20,
                Image = "rbxassetid://15103095167",
                Callback = function()
                    IconManager('Equipment'):select()
                end
            })
        end)
    end)
   

    itemList
    :rename("Items")
    :addElement(function()
        return GUI.newElement("Inventory", {
            Category = Window.state.Category,
            CellSize = UDim2.fromScale(0.3,0.3),
            Callback = function(itemData, index)
                if Window.state.Selected == index then
                    Window:setState{Selected = roact.None}
                else
                    Window:setState{Selected = index}
                end
                warn('selected', itemData, index)
            end,
        })
    end)

    mainItemInfo
    :vertical()
    :split({0.85,0.15}, function(itemInfo, equipButtonContainer)
        itemInfo
        :setOffset(10)
        :addBackground()
        :addElement(function()
            
            local itemData = GetSelectedItemData()
            return GUI.newElement("ItemInfo", {
                ItemData = itemData
            })
        end)

        equipButtonContainer
        :addElement(function()
            local itemData, id = GetSelectedItemData()
           return roact.createElement(EquipButtonComponent, {ItemData = itemData, Id = id})
        end)
    end)

end)

return Window.Component
