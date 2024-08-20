local UserInputService = game:GetService("UserInputService")
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
        local type = Metadata:GetType()

        local InventoryService = knit.GetService("InventoryService")
        local InventoryController = knit.GetController('InventoryController')
        local btns = {}


        local function equip(i)
            InventoryService.Equip:Fire(props.Id, i)
            GUI:ClosePopup('EquipPopup')
        end

        for i = 1,TypeInfo.MaxEquips do

            local itemData = InventoryController:GetEquipmentItem(type, i)

            btns[i] = GUI.newElement("Slot", {
                ItemData = itemData,
                EquipPosition = i,
                Callback = function()
                   equip(i)
                end
            })
        end
        --return roact.createElement(roact.Fragment, nil, btns)

        return function ()

            roact.useEffect(function()
                local conn = UserInputService.InputBegan:Connect(function(input: InputObject)
                    if input.KeyCode then
                        local position = input.KeyCode.Value - 48
                        if position > 0 and position <= TypeInfo.MaxEquips then
                            equip(position)
                        end
                    end
                end)

                return function ()
                    conn:Disconnect()
                end
            end)

            return roact.createElement(roact.Fragment, nil, btns)    
        end

        
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
        local PlayerData = PlayerDataController.PlayerData
        itemData = PlayerData and PlayerData.Inventory.Content[itemIndex]
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
        local playerData = PlayerDataController.PlayerData

        if not playerData then
            return
        end

        local Equipped, _Type, Subtype_or_Pos = InvUtil.GetEquipStatus(playerData.Inventory, id)

        return GUI.newElement("TextButton", {
            Text = Equipped and "Unequip" or "Equip",
            Size = UDim2.fromScale(1,1),
            Callback = function()
                if not Equipped then
                    if TypeInfo.Method == 'Single' then
                        GUI:CreatePopup('EquipPopup', EquipPopup:render(1, {ItemData = itemData, Id = id}))
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
    task.defer(function()
        local playerData = PlayerDataController:GetPlayerData()
        self.itemChangeConnection = playerData.Replica:ListenToRaw(function(_, path)
            if path[1] == 'Inventory' and path[2] == 'Equipment' then
                self:setState{update = self.state.update + 1}
            end
        end)
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
            --return roact.createElement(roact.Fragment, nil, CategoryButtons)
            return roact.createElement(roact.Fragment, nil, CategoryButtons)
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
