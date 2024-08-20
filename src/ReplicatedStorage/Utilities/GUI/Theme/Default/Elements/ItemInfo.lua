local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local FrameManager = require(ReplicatedStorage.Utilities:WaitForChild("GUI"):WaitForChild"FrameManager")
local ItemInfoFrame = FrameManager.new(UDim2.fromScale(1,1))

local TextLabel = require(script.Parent:WaitForChild("TextLabel"))
local Slot = require(script.Parent:WaitForChild"Slot")

local Items = require(ReplicatedStorage:WaitForChild"GameModules":WaitForChild"Items")
local scale = UDim2.fromScale

local StatFormula = require(ReplicatedStorage.Utilities:WaitForChild("Misc"):WaitForChild"StatFormula")
local Stats = require(ReplicatedStorage.GameModules:WaitForChild"Stats")

local function Title(text, layout, size)
    return roact.createElement(TextLabel, {
        Text = `  {text}`,
        Size = size or UDim2.fromScale(1,0.09),
        TextColor3 = Color3.new(0.784313, 0.784313, 0.784313),
        LayoutOrder = layout,
        TextXAlignment = 'Left'
    })
end

local function Text(text, value, i)
    return roact.createElement(TextLabel, {
        Text = `  {text} <font color="#ffffff">{value}</font>`,
        Size = UDim2.fromScale(1,0.09),
        TextColor3 = Color3.fromRGB(206, 206, 206),
        LayoutOrder = i,
        TextXAlignment = 'Left',
        RichText = true,
    })
end

local function Stat(stat, label, i, size)

    local statInfo = Stats[stat]
    if statInfo then
        stat = statInfo.Label
    end

    return roact.createElement("Frame", {
        Size = size or scale(0.9,0.09),
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 0.9,
        LayoutOrder = i,
    }, {
        Corner = roact.createElement("UICorner"),
        StatName = roact.createElement(TextLabel, {
            Size = scale(0.6,1),
            Text = `  {stat}`,
            TextXAlignment = 'Left'
        }),
        StatValue = roact.createElement(TextLabel, {
            Size = scale(0.4,1),
            Text = `{label}  `,
            TextXAlignment = 'Right',
            Position = scale(0.6,0)
        })
    })
end

ItemInfoFrame
:enableScrolling("Y")
:vertical()
:center("Horizontal")
:setOffset(3)
:shouldRender(function(props)
    return props.ItemData ~= nil or Items[props.ItemData] ~= nil
end)
:div(0.02)
:addElement(function(layoutOrder, props)
    return roact.createElement(Slot, {
        ItemData = props.ItemData,
        LayoutOrder = layoutOrder,
        Size = UDim2.fromScale(0.5,0.5)
    })
end)
:addText(function(props) 
    return Items[props.ItemData].DisplayName
 end, scale(1,0.13))
:addFrame({0.115}, function(ratingFrame)
    ratingFrame
    :horizontal()
    :setOffset(2)
    :center('Vertical')
    :div(0.03)
    --:addText('Rating:', scale(0.34,1))
    :addElement(function(i)
        return roact.createElement(TextLabel, {
            Size = scale(0.34,1),
            Text = "Rating:",
            LayoutOrder = i,
            TextColor3 = Color3.fromRGB(206, 206, 206),
            TextXAlignment = 'Left'
        })
    end)
    :addElement(function(layout, props)
        local item = Items[props.ItemData]
        local rating = item:GetRating()

        return roact.createElement("ImageLabel", {
            BackgroundTransparency = 1,
            Image = rating.Icon,
            LayoutOrder = layout,
            Size = UDim2.fromScale(.7,.7),
        }, {
            Ratio = roact.createElement("UIAspectRatioConstraint", {
                AspectRatio = rating.IconRatio,
            })
        })
    end)
end)
:addElement(function(i,props)
    local item = Items[props.ItemData]
    if item.Equipment then
        local data = props.ItemData[4]
        local equipment = item.Equipment

        local BaseStats = {}
        for stat, value in equipment.Stats do
            local percentage = value[2]
            local mult = value[3] or Stats[stat].LevelMultiplier
            local metadata = Stats[stat]
            local label = math.round(StatFormula.GetBaseStat(data.Lvl, value[1], mult) * 100)/100
            if metadata.IsPercentage or percentage then
                label = StatFormula.Percentage(label)
            end

            BaseStats[`{stat}BaseStats`] = Stat(stat, label, i+3)
        end

        local Substats = {}
        local SubstatsAmount = 0
        for stat, value in data.Substats do
            SubstatsAmount += 1
            local metadata = Stats[stat]
            local percentage = value[2]
            local label = value[1]
            if metadata.IsPercentage or percentage then
                label = StatFormula.Percentage(label)
            end
            Substats[`{stat}Substats`] = Stat(stat, label, i+5)
        end

        local Type = equipment.Type
        if equipment.Subtype then
            Type ..= ` <font size="6" color="#c9c9c9">[{equipment.Subtype}]</font>`
        end
 
        return roact.createElement(roact.Fragment, nil , {
            Level = Text("Level:",data.Lvl,i),
            Type = Text('Type:',Type,i+1),
            BaseStatsTitle = Title("Base Stats:", i+2),
            BaseStats = roact.createElement(roact.Fragment, nil, BaseStats),
            SubstatsTitle = SubstatsAmount > 0 and Title("Sub stats:", i+4),
            Substats = roact.createElement(roact.Fragment, nil, Substats)
        }), i+5
    end
end)
:div(0.02)
:addElement(function(layout, props)
    local item = Items[props.ItemData]
    return roact.createElement(TextLabel, {
        Text = item.Description:gsub("[\r\n]", ""),
        TextScaled = false,
        LayoutOrder = layout,
        TextXAlignment = "Center",
        TextYAlignment = "Top",
        Size = scale(0.9,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextColor3 = Color3.new(0.764705, 0.764705, 0.764705),
        TextScale = 0.0175,
    })
end)
:div(0.03)

return function (props)
    return ItemInfoFrame:render(1, props)
end