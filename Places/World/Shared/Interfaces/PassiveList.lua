local ReplicatedStorage = game:GetService("ReplicatedStorage")
local trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local GUI = Knit.GetController('GUI')
local roact = require(ReplicatedStorage.Utilities.Roact)

local PassiveClient = Knit.GetController('PassiveClient')

return {
    HUD = true,
    
    Component = function(props)

        local update, setUpdate = roact.useState(0)

        roact.useEffect(function()

            local _trove = trove.new()
            
            _trove:Connect(PassiveClient.PassiveActivated, function(passive)
                print(passive, 'activated')
                setUpdate(update + 1)
            end)

            _trove:Connect(PassiveClient.PassiveDeactivated, function(passive)
                print(passive, 'deactivated')
                setUpdate(update + 1)
            end)

            return _trove:WrapClean()
        end)

        local list = {}


        for name, data in PassiveClient:GetActivePassives() do
            if next(data) then
                table.insert(list, GUI.newElement('Passive', {
                    Position = UDim2.new(0.2,0,0.95,0),
                    AnchorPoint = Vector2.new(0,1),
                    Size = UDim2.fromScale(0.1,0.1),
                    Passive = name
                }))
            end
        end

        return roact.createElement('Frame', {
            Size = UDim2.fromScale(0.28,0.9),
            AnchorPoint = Vector2.new(0,1),
            Position = UDim2.fromScale(0.02,0.98),
            BackgroundTransparency = 1,
            Visible = not props.Disabled
        }, {
            Ratio = roact.createElement('UIAspectRatioConstraint'),
            Grid = roact.createElement('UIGridLayout', {
                CellPadding = UDim2.fromScale(0.02,0.02),
                CellSize = UDim2.fromScale(0.15,0.15),
                StartCorner = Enum.StartCorner.BottomRight,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = 'Right',
                VerticalAlignment = 'Bottom'
            }),
            List = roact.createElement(roact.Fragment, nil, list)
        })

        -- return GUI.newElement('Passive', {
        --     Position = UDim2.new(0.2,0,0.95,0),
        --     AnchorPoint = Vector2.new(0,1),
        --     Size = UDim2.fromScale(0.1,0.1),
        --     Passive = 'MPRegeneration'
        -- })
    end
}