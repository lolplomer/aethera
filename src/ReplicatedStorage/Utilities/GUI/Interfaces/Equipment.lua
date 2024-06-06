local WindowManager = require(script.Parent.Parent:WaitForChild"WindowManager")
local knit = require(game.ReplicatedStorage:WaitForChild"Packages":WaitForChild"Knit")

local GUI = knit.GetController "GUI"
local PlayerDataController = knit.GetController "PlayerDataController"

local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

local Util = script.Parent.Parent
local InventoryUtil = require(Util.Parent:WaitForChild"InventoryUtil")
local IconManager = require(Util:WaitForChild"IconManager")


local GameModules = game.ReplicatedStorage:WaitForChild"GameModules"
local Items = require(GameModules:WaitForChild"Items")

local Types = {}
for type,v in Items.Type do
    table.insert(Types, v.LayoutOrder, type)
end
local TypeSplits = table.create(#Types, 1/3)

local Window = WindowManager.new('Equipment', {DisableIcon = true})
local trove = require(game.ReplicatedStorage:WaitForChild'Packages':WaitForChild"Trove")

function Window:init()
    self:setState {update = 0}
end

function Window:didMount()
    local playerData = PlayerDataController:GetPlayerData()
    self.itemChangeConnection = playerData.Replica:ListenToRaw(function(_, path)
        if path[1] == 'Inventory' and path[2] == 'Equipment' then
            self:setState{update = self.state.update + 1}
        end
    end)
end

function Window:willUnmount()
    if self.itemChangeConnection then
        self.itemChangeConnection:Disconnect()
        self.itemChangeConnection = nil
    end
end

local StatList = roact.PureComponent:extend('StatList')


function StatList:init()
    self.cleaner = trove.new()
    self:setState {update = 0}
end

function StatList:didMount()
    local PlayerStats = knit.GetController('PlayerReplicaController'):GetReplica('PlayerStats')


    self.cleaner:Add(PlayerStats.Replica:ListenToRaw(function(_,path)
        if path[1]=='FullStats' then
            self:setState {update = self.state.update + 1}
        end
    end))
end

function StatList:render()
    local PlayerStats = knit.GetController('PlayerReplicaController'):GetReplica('PlayerStats')
 
    local stats = {}
    for stat,value in PlayerStats.FullStats do
        stats[stat] = GUI.newElement('Stat', {
            Stat = stat,
            Value = value,
            Size = UDim2.fromScale(0.95,0.09)
        })
    end
    --return roact.createElement(roact.Fragment, nil, stats)
    return roact.createElement(roact.Fragment, nil, stats)
end

Window.Frame
:horizontal()

:split({1/3,1/3,1/3}, function(LeftSide, CharPreview, Stats)
    LeftSide
    :vertical()
    :split({0.8,0.2}, function(Equips, Inventory)

        Equips
        :enableScrolling("Y")
        for i, typeUI in {Equips:split(TypeSplits,nil,true)} do
            local type = Types[i]

            typeUI
            :addBackground {Padding = 5}
            :split({0.4,0.6}, function(Title, TypeEquips)
                Title
                :addText(type, UDim2.fromScale(1,1))

                TypeEquips
                :horizontal()
                :center()
                :setOffset(4)
                --:enableScrolling("X")
                :addElement(function()
                    local elements = {}

                    local TypeInfo = Items:GetTypeInfo(type)
                    local InvData = PlayerDataController:GetPlayerData().Inventory
                    --local Count = TypeInfo.Method == "Single" and TypeInfo.MaxEquips or TypeInfo.SubtypeCount

                    local function Callback(Type, Subtype_or_Pos)
                        return function(_, inputObject)
                            GUI:CreatePopup(GUI.newElement('ButtonList', {
                                Buttons = {
                                    {Text = 'Unequip', Callback = function()
                                        local InvService = knit.GetService"InventoryService"
                                        InvService.Unequip:Fire(Type, Subtype_or_Pos)
                                        GUI:ClosePopup('EquipPopup')
                                    end},
                                },
                                Padding = 10
                            }), 'EquipPopup', {
                                Position = UDim2.fromOffset(inputObject.Position.X, inputObject.Position.Y),
                                AnchorPoint = Vector2.new(0,0),
                                Size = UDim2.fromScale(0.1,0.05),
                                CloseSizeScale = 1.05,
                                UseRatio = false,
                            })
                        end
                    end

                    if TypeInfo.Method == "Single" then
                        for i_element = 1,TypeInfo.MaxEquips do
                            local ItemData, _ = InventoryUtil.GetEquippedType(InvData, type, i_element)
                            elements[i_element] = GUI.newElement("Slot", {
                                ItemData = ItemData,
                                Size = UDim2.fromScale(1,1),
                                EquipPosition = i_element,
                                LayoutOrder = i_element,
                                Callback = ItemData and Callback(type, i_element),
                                PositionEquipped = i_element == InvData.Equipment[type].Position
                            })
                        end
                    elseif TypeInfo.Method == 'Multiple' then
                        for Subtype, _ in TypeInfo.Subtype do
                            local ItemData, _ = InventoryUtil.GetEquippedType(InvData, type, Subtype)
                            elements[Subtype] = GUI.newElement("Slot", {
                                ItemData = ItemData,
                                Size = UDim2.fromScale(1,1),
                                EquipType = {Type = type, Subtype = Subtype},
                                Callback = ItemData and Callback(type, Subtype)
                            })
                        end
                    end

                    -- elements.UIPadding = GUI.newElement('UIPadding', {
                    --     Padding = UDim.new(0,3)
                    -- })
                   
                    --return roact.createElement(roact.Fragment, nil, elements)
                    return roact.createElement(roact.Fragment, nil, elements)
                end)

            end)
        end

        Inventory
        :horizontal()
        :addElement(function()
            return GUI.newElement("Icon", {
                Size = UDim2.fromScale(1,1),
                Padding = -20,
                Image = "rbxassetid://15110529922",
                Callback = function()
                    IconManager('Inventory'):select()
                end
            })
        end)
    end)

    CharPreview
    :addBackground()

    Stats
    
    :addBackground{Padding = 15}
    :center()
    :split({0.15,0.85}, function(Level, List)

        List
        :addBackground {Color = Color3.fromHex("475D76"),Padding=15}
        :enableScrolling()
        :addElement(function()
            return roact.createElement(StatList)
        end)
        
        Level
        :setOffset(10)
        :addElement(function()
            return GUI.newElement('Level')
        end)
    end)
end)

return Window.Component 