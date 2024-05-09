local roact = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Roact")

local knit = require(game.ReplicatedStorage:WaitForChild"Packages":WaitForChild"Knit")

local Util = game.ReplicatedStorage:WaitForChild"Utilities"
local InvUtil = require(Util:WaitForChild"InventoryUtil")

--local GUI = knit.GetController("GUI")

local Slot = require(script.Parent.Slot)
local ScrollingFrame = require(script.Parent.ScrollingFrame)

local playerData
local inventory = roact.PureComponent:extend("Inventory")

function inventory:init()
    playerData = knit.GetController("PlayerDataController"):GetPlayerData() 
    self:setState{update = 0}
end 

function inventory:render()
    local _items = {}
    for index, itemData in playerData.Inventory.Content do
        if not self.props.Category or itemData[2] == self.props.Category then
            local Equipped = InvUtil.GetEquipStatus(playerData.Inventory, index)
           -- print('Equip status for',index,':',Equipped)
            _items[`Item{index}`] = roact.createElement(Slot,{
                ItemData = itemData,
                Callback = self.props.Callback ~= nil and function ()
                    self.props.Callback(itemData, index)
                end,
                Equipped = Equipped
            })
        end
    end
    return roact.createElement(ScrollingFrame, {
        ScrollBarThickness = 6,
        Size = self.props.Size,
    }, {
        UIGridLayout = roact.createElement("UIGridLayout", {
            --CellSize = UDim2.fromScale(0.12,0.24),
            SortOrder = Enum.SortOrder.LayoutOrder,
            CellSize = self.props.CellSize or UDim2.fromScale(0.225,0.325),
            CellPadding = UDim2.fromScale(0.02,0.02)
        }),
        Items = roact.createFragment(_items)
    })
end

function inventory:shouldUpdate()
    if not playerData then return false end

    if self.props.ShouldUpdate then
        return self.props.ShouldUpdate()
    end
    return true
end

function inventory:didMount()
    self.itemChangeConnection = playerData.Replica:ListenToRaw(function(_, path)
        if path[1] == 'Inventory' then
            self:setState{update = self.state.update + 1}
        end
    end)
end

function inventory:willUnmount()
    if self.itemChangeConnection then
        print("Disconnected itemChangeConnection")
        self.itemChangeConnection:Disconnect()
        self.itemChangeConnection = nil
    end
end

return inventory